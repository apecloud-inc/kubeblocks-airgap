#!/bin/bash

set -e

# 镜像包可选。不传则跳过 load，直接推送本地已有镜像。
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <registry-address> [docker-image-file...]"
    exit 1
fi
REGISTRY=$1
shift # 移除第一个参数，剩下的都是镜像文件

# 对每个镜像文件执行 load 操作
for DOCKER_IMAGE_FILE in "$@"; do
    echo "Loading image from file: $DOCKER_IMAGE_FILE"
    sealos load -i "$DOCKER_IMAGE_FILE"
done

FAILED_FILE="kubeblocks-image-list-failed.txt"
if [ -f "$FAILED_FILE" ]; then
    IMAGES_LIST_FILE="$FAILED_FILE"
else
    IMAGES_LIST_FILE="kubeblocks-image-list.txt"
fi
if [ ! -f "$IMAGES_LIST_FILE" ]; then
    echo "Image list file does not exist."
    exit 1
fi
echo "使用镜像列表: $IMAGES_LIST_FILE"
# 占位行避免成功列表为空时，awk 把原列表误当成成功记录。
PUSHED_OK_FILE=$(mktemp)
FAILED_BODY_FILE=$(mktemp)
echo "# pushed-ok" > "$PUSHED_OK_FILE"
trap 'rm -f "$PUSHED_OK_FILE" "$FAILED_BODY_FILE"' EXIT
LIST_PUSH_FAILED=0

# 读取镜像列表文件，对每个镜像修改 tag 并 push
while IFS= read -r image; do
    if [[ $image = \#* || -z "$image" ]]; then
        continue
    fi

    # 提取镜像名和标签
    image_name=$(echo "$image" | cut -d":" -f1)
    image_tag=$(echo "$image" | cut -d":" -f2)
    name_prefix="${image_name%%/*}"

    if [[ "$name_prefix" != "$image_name" ]]; then
        # 替换仓库名为用户提供的REGISTRY地址
        new_image_name="${image_name/$name_prefix/$REGISTRY}"
    else
        new_image_name="${REGISTRY}/${image_name}"
    fi

    # 如果提取的镜像标签为空，则默认使用latest标签
    if [[ -z "$image_tag" ]]; then
        image_tag="latest"
    fi

    new_image="${new_image_name}:${image_tag}"
    # 对镜像执行 sealos tag
    image_tmp="$image"
    if [[ "$image" == "docker.io/library/"* ]]; then
        image=${image/docker.io\/library\//localhost\/}
    elif [[ "$image" == "docker.io/"* ]]; then
        image=${image/docker.io\//localhost\/}
    fi
    set +e
    sealos tag "$image" "$new_image"
    tag_ret=$?
    if [[ "$tag_ret" != "0" ]]; then
        sealos tag "$image_tmp" "$new_image"
        tag_ret=$?
        if [[ "$tag_ret" != "0" ]]; then
            image_tmp_2=${image_tmp/docker.io\//}
            sealos tag "$image_tmp_2" "$new_image"
            tag_ret=$?
        fi
    fi
    if [[ "$tag_ret" == "0" ]]; then
        sealos push "$new_image"
        tag_ret=$?
    fi
    set -e
    if [[ "$tag_ret" != "0" ]]; then
        echo "❌ $(tput -T xterm setaf 1) $image 推送失败 $(tput -T xterm sgr0)"
        continue
    fi
    printf '%s\n' "$image" >> "$PUSHED_OK_FILE"
    echo "✅ $(tput -T xterm setaf 2) $new_image pushed successfully $(tput -T xterm sgr0)"

done < "$IMAGES_LIST_FILE"

# 只有全量推送才推本地 Kubernetes 相关镜像。失败清单补推时不推。
if [[ "$IMAGES_LIST_FILE" != "$FAILED_FILE" ]]; then
    while IFS= read -r image; do
        [[ -z "$image" || "$image" == *":<none>" || "$image" == "$REGISTRY/"* ]] && continue
        image_name="${image%:*}"
        image_tag="${image##*:}"
        name_prefix="${image_name%%/*}"
        if [[ "$name_prefix" != "$image_name" ]]; then
            new_image_name="${image_name/$name_prefix/$REGISTRY}"
        else
            new_image_name="${REGISTRY}/${image_name}"
        fi
        new_image="${new_image_name}:${image_tag}"
        set +e
        sealos tag "$image" "$new_image"
        k8s_ret=$?
        if [[ "$k8s_ret" == "0" ]]; then
            sealos push "$new_image"
            k8s_ret=$?
        fi
        set -e
        if [[ "$k8s_ret" != "0" ]]; then
            continue
        fi
    done < <(sealos images | awk 'NR>1 {print $1":"$2}' | grep -E 'apecloud/kubernetes-airgap:|apecloud/calico-airgap:|labring/helm:|labring/metrics-server:|labring/openebs:|labring/coredns:' || true)
fi
# 全量列表只写出未成功镜像。失败文件里只把这次成功的行改成注释，不重写文件。
FAILED_FILE="kubeblocks-image-list-failed.txt"
if [[ "$IMAGES_LIST_FILE" == "$FAILED_FILE" ]]; then
    awk '
    NR==FNR { if ($0 != "") ok[$0]++; next }
    {
        line = $0
        if (line !~ /^#/ && line != "" && ok[line] > 0) { ok[line]--; print "# " line; next }
        print
    }
    ' "$PUSHED_OK_FILE" "$FAILED_FILE" > "$FAILED_BODY_FILE"
    mv "$FAILED_BODY_FILE" "$FAILED_FILE"
    failed_count=$(awk '!/^#/ && $0 != "" { c++ } END { print c+0 }' "$FAILED_FILE")
else
    awk '
    NR==FNR { if ($0 != "") ok[$0]++; next }
    line !~ /^#/ && line != "" && ok[line] > 0 { ok[line]--; next }
    line !~ /^#/ && line != "" { print }
    ' "$PUSHED_OK_FILE" "$IMAGES_LIST_FILE" > "$FAILED_BODY_FILE"
    failed_count=$(awk 'END { print NR+0 }' "$FAILED_BODY_FILE")
    if [[ "$failed_count" -gt 0 ]]; then
        mv "$FAILED_BODY_FILE" "$FAILED_FILE"
    fi
fi
if [[ "$failed_count" -gt 0 ]]; then
    echo "❌ $(tput -T xterm setaf 1) 未推送成功 ${failed_count} 个，见 $FAILED_FILE $(tput -T xterm sgr0)"
    awk '!/^#/ && $0 != "" { print }' "$FAILED_FILE" | while IFS= read -r failed_image; do
        echo "❌ $(tput -T xterm setaf 1) $failed_image $(tput -T xterm sgr0)"
    done
    LIST_PUSH_FAILED=1
else
    rm -f "$FAILED_FILE"
    LIST_PUSH_FAILED=0
fi
if [[ "$LIST_PUSH_FAILED" == "1" ]]; then
    exit 1
fi
echo "$(tput -T xterm setaf 2) All images pushed successfully $(tput -T xterm sgr0)"
