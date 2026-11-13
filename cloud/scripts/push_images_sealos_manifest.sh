#!/bin/bash

set -e

# 检查是否提供了registry地址
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <registry-address>"
    exit 1
fi
REGISTRY=$1

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

# 读取镜像列表文件，对每个镜像整合成 manifest 并 push
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
    new_image_amd64="${new_image_name}:${image_tag}-amd64"
    new_image_arm64="${new_image_name}:${image_tag}-arm64"
    # 对镜像执行 sealos manifest
    set +e
    sealos manifest create "$new_image" "$new_image_amd64" && \
    sealos manifest add "$new_image" "$new_image_amd64" && \
    sealos manifest add "$new_image" "$new_image_arm64" && \
    sealos manifest annotate "$new_image" "$new_image_amd64" --os linux --arch amd64 && \
    sealos manifest annotate "$new_image" "$new_image_arm64" --os linux --arch arm64 && \
    sealos manifest push "$new_image" docker://${new_image_name}
    tag_ret=$?
    set -e
    if [[ "$tag_ret" != "0" ]]; then
        echo "❌ $(tput -T xterm setaf 1) $image 推送失败 $(tput -T xterm sgr0)"
        continue
    fi
    printf '%s\n' "$image" >> "$PUSHED_OK_FILE"
    echo "✅ $(tput -T xterm setaf 2) $new_image manifest pushed successfully $(tput -T xterm sgr0)"

done < "$IMAGES_LIST_FILE"

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
echo "$(tput -T xterm setaf 2) All images manifest pushed successfully $(tput -T xterm sgr0)"
