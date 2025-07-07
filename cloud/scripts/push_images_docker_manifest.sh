#!/bin/bash

set -e

# 检查是否提供了registry地址
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <registry-address>"
    exit 1
fi
REGISTRY=$1

IMAGES_LIST_FILE="kubeblocks-image-list.txt"
# 检查镜像列表文件是否存在
if [ ! -f "$IMAGES_LIST_FILE" ]; then
    echo "Image list file does not exist."
    exit 1
fi

# 读取镜像列表文件，对每个镜像整合成 manifest 并 push
while IFS= read -r image; do
    if [[ $image = \#* ||  -z "$image" ]]; then
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
    # 对镜像执行 docker manifest
    set +e
    docker manifest create "$new_image" "$new_image_amd64" "$new_image_arm64"
    docker manifest annotate "$new_image" "$new_image_amd64" --os linux --arch amd64
    docker manifest annotate "$new_image" "$new_image_arm64" --os linux --arch arm64
    tag_ret=$?
    set -e
    if [[ "$tag_ret" != "0" ]]; then
        echo "❌ $(tput -T xterm setaf 1) $new_image create manifest failed $(tput -T xterm sgr0)"
    else
        # 推送镜像 manifest 到指定的 registry
        docker manifest push "$new_image"
        echo "✅ $(tput -T xterm setaf 2) $new_image manifest pushed successfully $(tput -T xterm sgr0)"
    fi

done < "$IMAGES_LIST_FILE"

echo "$(tput -T xterm setaf 2) All images manifest pushed successfully $(tput -T xterm sgr0)"