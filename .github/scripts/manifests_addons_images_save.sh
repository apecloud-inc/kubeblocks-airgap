#!/bin/bash

MANIFESTS_FILE=${1:-"deploy-manifests.yaml"}
IMAGE_NAME=${2:-""}
ARM64_IMAGE=${3:-"false"}


pull_chart_images() {
    chart_images_tmp=${1:-""}
    image_name_tmp=${2:-""}

    for image in $(echo "$chart_images_tmp"); do
        if [[ "${ARM64_IMAGE}" == "true" && "$image_name_tmp" == "mysql" ]]; then
            if [[ "${image}" == "apecloud/mysql:5.7.44" || "${image}" == "apecloud/mysql_audit_log:5.7.44" || "${image}" == "apecloud/percona-xtrabackup:2.4" || "${image}" == "apecloud/xtrabackup:2.4" ]]; then
                continue
            fi
        elif [[ "${ARM64_IMAGE}" == "true" && "$image_name_tmp" == "elasticsearch" ]]; then
            if [[ "${image}" == "apecloud/elasticsearch:7.7.1" || "${image}" == "apecloud/kibana:7.10.1" || "${image}" == "apecloud/kibana:7.8.1" || "${image}" == "apecloud/kibana:7.7.1" ]]; then
                continue
            fi
        fi

        repository="${SRC_REGISTRY}/${image}"
        if [[ "${ARM64_IMAGE}" == "true" ]]; then
            echo "docker pull --platform linux/arm64 $repository"
        else
            echo "docker pull $repository"
        fi
        for i in {1..10}; do
            if [[ "${ARM64_IMAGE}" == "true" ]]; then
                docker pull --platform linux/arm64 "$repository"
            else
                docker pull "$repository"
            fi
            ret_msg=$?
            if [[ $ret_msg -eq 0 ]]; then
                echo "$(tput -T xterm setaf 2)pull image $repository success$(tput -T xterm sgr0)"
                break
            fi
            sleep 1
        done
        SAVE_CHART_IMAGES="$SAVE_CHART_IMAGES $repository"
    done

    if [[ "${ARM64_IMAGE}" == "true" && "$image_name_tmp" == "damengdb" ]]; then
        repository="${SRC_REGISTRY}/apecloud/dm:8.1.4-6-20241231"
        if [[ "${ARM64_IMAGE}" == "true" ]]; then
            echo "docker pull --platform linux/arm64 $repository"
        else
            echo "docker pull $repository"
        fi
        for i in {1..10}; do
            if [[ "${ARM64_IMAGE}" == "true" ]]; then
                docker pull --platform linux/arm64 "$repository"
            else
                docker pull "$repository"
            fi
            ret_msg=$?
            if [[ $ret_msg -eq 0 ]]; then
                echo "$(tput -T xterm setaf 2)pull image $repository success$(tput -T xterm sgr0)"
                break
            fi
            sleep 1
        done
        SAVE_CHART_IMAGES="$SAVE_CHART_IMAGES $repository"

        repository="${SRC_REGISTRY}/apecloud/dmdb-exporter:8.1.4"
        if [[ "${ARM64_IMAGE}" == "true" ]]; then
            echo "docker pull --platform linux/arm64 $repository"
        else
            echo "docker pull $repository"
        fi
        for i in {1..10}; do
            if [[ "${ARM64_IMAGE}" == "true" ]]; then
                docker pull --platform linux/arm64 "$repository"
            else
                docker pull "$repository"
            fi
            ret_msg=$?
            if [[ $ret_msg -eq 0 ]]; then
                echo "$(tput -T xterm setaf 2)pull image $repository success$(tput -T xterm sgr0)"
                break
            fi
            sleep 1
        done
        SAVE_CHART_IMAGES="$SAVE_CHART_IMAGES $repository"

        repository="${SRC_REGISTRY}/apecloud/dmdb-tool:8.1.4"
        if [[ "${ARM64_IMAGE}" == "true" ]]; then
            echo "docker pull --platform linux/arm64 $repository"
        else
            echo "docker pull $repository"
        fi
        for i in {1..10}; do
            if [[ "${ARM64_IMAGE}" == "true" ]]; then
                docker pull --platform linux/arm64 "$repository"
            else
                docker pull "$repository"
            fi
            ret_msg=$?
            if [[ $ret_msg -eq 0 ]]; then
                echo "$(tput -T xterm setaf 2)pull image $repository success$(tput -T xterm sgr0)"
                break
            fi
            sleep 1
        done
        SAVE_CHART_IMAGES="$SAVE_CHART_IMAGES $repository"
    fi
}

save_charts_images() {
    if [[ ! -f "${MANIFESTS_FILE}" ]]; then
        echo "$(tput -T xterm setaf 1)Not found manifests file:${MANIFESTS_FILE}$(tput -T xterm sgr0)"
        return
    fi

    if [[ -z "${IMAGE_NAME}" ]]; then
        echo "$(tput -T xterm setaf 1)Enable Addon Name is empty$(tput -T xterm sgr0)"
        return
    fi

    RELEASE_VERSIONS=$(yq e '[.'${IMAGE_NAME}'[].version] | join("|")' ${MANIFESTS_FILE})
    version_index=0
    for release_version in $(echo "${RELEASE_VERSIONS}" | sed 's/|/ /g'); do
        IMAGE_PKG_NAME="${IMAGE_NAME}-images-${release_version}.tar.gz"
        chart_images=$(yq e "."${IMAGE_NAME}"[].images[]" "${MANIFESTS_FILE}")
        if [[ -z "$chart_images" ]]; then
            echo "$(tput -T xterm setaf 3)Not found ${chart_name} images$(tput -T xterm sgr0)"
            exit 1
        fi

        pull_chart_images "$chart_images" "${IMAGE_NAME}"

        echo " Pull images done!"
        df -h
        save_cmd="docker save ${SAVE_CHART_IMAGES} | gzip > ${IMAGE_PKG_NAME}"
        echo "$save_cmd"
        save_flag=0
        for i in {1..10}; do
            eval "$save_cmd"
            ret_msg=$?
            if [[ $ret_msg -eq 0 ]]; then
                echo "$(tput -T xterm setaf 2)save ${IMAGE_PKG_NAME} success$(tput -T xterm sgr0)"
                save_flag=1
                break
            fi
            sleep 1
        done
        rm -rf ${IMAGES_FILE_DIR}
        if [[ $save_flag -eq 0 ]]; then
            echo "$(tput -T xterm setaf 1)save ${IMAGE_PKG_NAME} error$(tput -T xterm sgr0)"
            exit 1
        fi
        version_index=$(( $version_index + 1 ))
    done
}

main() {
    local SRC_REGISTRY="docker.io"
    local IMAGE_PKG_NAME=""
    local SAVE_CHART_IMAGES=""

    save_charts_images
}

main "$@"
