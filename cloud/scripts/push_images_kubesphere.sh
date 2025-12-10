#!/bin/bash
set -e
# 检查是否至少提供了一个registry地址和一个镜像文件
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <registry-address> <docker-image-file>..."
    exit 1
fi
REGISTRY=$1
shift # 移除第一个参数，剩下的都是镜像文件
# 对每个镜像文件执行 load 操作
for DOCKER_IMAGE_FILE in "$@"; do
    echo "Loading image from file: $DOCKER_IMAGE_FILE"
    docker load -i "$DOCKER_IMAGE_FILE"
done
IMAGES_LIST_FILE="kubeblocks-image-list.txt"
# 检查镜像列表文件是否存在
if [ ! -f "$IMAGES_LIST_FILE" ]; then
    echo "Image list file does not exist."
    exit 1
fi
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
    # 对镜像执行 docker tag
    image_tmp="$image"
    if [[ "$image_tmp" == "docker.io/library/"* ]]; then
        image_tmp=${image_tmp/docker.io\/library\//localhost\/}
    elif [[ "$image_tmp" == "docker.io/"* ]]; then
        image_tmp=${image_tmp/docker.io\//localhost\/}
    fi
    set +e
    docker inspect "$image_tmp" >/dev/null 2>&1
    inspect_ret=$?
    set -e
    if [[ "$inspect_ret" == "0" ]]; then
        docker tag "$image_tmp" "$new_image"
    else
        docker tag "$image" "$new_image"
    fi
    # 推送镜像到指定的 registry
    docker push "$new_image"
done < "$IMAGES_LIST_FILE"