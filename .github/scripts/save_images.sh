#!/bin/bash

set -eu

readonly ADD_IMAGES_LIST=${add_images?}
readonly APP_NAME=${app_name?}
readonly IMAGE_FILE_PATH=${images_file?}
readonly APP_VERSION_TMP=${app_version?}
readonly KUBEBLOCKS_VERSION_TMP="${kubeblocks_version?}"
readonly GEMINI_VERSION_TMP="${gemini_version?}"
readonly OTELD_VERSION_TMP="${oteld_version?}"
readonly OFFLINE_INSTALLER_VERSION_TMP="${installer_version?}"
readonly DMS_VERSION_TMP="${dms_version?}"

echo "ADD_IMAGES_LIST:"${ADD_IMAGES_LIST}
echo "APP_NAME:"${APP_NAME}
echo "IMAGE_FILE_PATH:"${IMAGE_FILE_PATH}
echo "APP_VERSION:"${APP_VERSION_TMP}
echo "CLOUD_VERSION:"${APP_VERSION_TMP}
echo "KUBEBLOCKS_VERSION:"${KUBEBLOCKS_VERSION_TMP}
echo "GEMINI_VERSION:"${GEMINI_VERSION_TMP}
echo "OTELD_VERSION:"${OTELD_VERSION_TMP}
echo "OFFLINE_INSTALLER_VERSION:"${OFFLINE_INSTALLER_VERSION_TMP}
echo "DMS_VERSION:"${DMS_VERSION_TMP}

add_images_list() {
    if [[ -z "${ADD_IMAGES_LIST}" ]]; then
        return
    fi

    if [[ ! -f "$IMAGE_FILE_PATH" ]]; then
        touch "$IMAGE_FILE_PATH"
    fi
    echo "

" >> $IMAGE_FILE_PATH
    for image in $(echo "$ADD_IMAGES_LIST" | sed 's/|/ /g'); do
        image_name="${image%:*}"
        exists_images_list="$(cat $IMAGE_FILE_PATH | (grep "$image_name" || true))"
        if [[ -z "$exists_images_list" ]]; then
            echo "$image" >> $IMAGE_FILE_PATH
            continue
        fi
        exists_flag=0
        for e_image in $(echo "$exists_images_list"); do
            if [[ "$image" == "$e_image" ]]; then
                exists_flag=1
                break
            fi
            e_image_name="${e_image%:*}"
            if [[ "$e_image_name" == "$image_name" ]]; then
                e_image_tmp=$( echo ${e_image}| sed 's/\./\\./g;s/\//\\\//g' )
                image_tmp=$( echo ${image}| sed 's/\./\\./g;s/\//\\\//g' )
                if [[ "$UNAME" == "Darwin" ]]; then
                    sed -i '' "s/${e_image_tmp}/${image_tmp}/" $IMAGE_FILE_PATH
                else
                    sed -i "s/${e_image_tmp}/${image_tmp}/" $IMAGE_FILE_PATH
                fi
                exists_flag=1
                break
            fi
        done
        if [[ $exists_flag -eq 0 ]]; then
            echo "$image" >> $IMAGE_FILE_PATH
        fi
    done
}

save_images_package() {
    if [[ ! -f "$IMAGE_FILE_PATH" ]]; then
        echo "no found save images file"
        return
    fi

    if [[ "${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-cloud" || "$APP_NAME" == "kubeblocks-enterprise-patch" ]]; then
        if [[ "${APP_VERSION}" != "v"* ]]; then
            APP_VERSION="v${APP_VERSION}"
        fi
        HEAD_APP_VERSION="${APP_VERSION%%.*}"
        echo "change ${APP_NAME}.txt images tag"
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^# KubeBlocks-Cloud .*/# KubeBlocks-Cloud ${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/openconsole:.*[0-9]/docker.io\/apecloud\/openconsole:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/apiserver:.*/docker.io\/apecloud\/apiserver:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/task-manager:.*/docker.io\/apecloud\/task-manager:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/cubetran-front:.*/docker.io\/apecloud\/cubetran-front:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/cr4w:.*/docker.io\/apecloud\/cr4w:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/relay:.*/docker.io\/apecloud\/relay:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/sentry:.*/docker.io\/apecloud\/sentry:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/sentry-init:.*/docker.io\/apecloud\/sentry-init:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kb-cloud-installer:.*/docker.io\/apecloud\/kb-cloud-installer:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/apecloud-charts:.*/docker.io\/apecloud\/apecloud-charts:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/apecloud-addon-charts:${HEAD_APP_VERSION}.*/docker.io\/apecloud\/apecloud-addon-charts:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kb-cloud-hook:.*/docker.io\/apecloud\/kb-cloud-hook:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kb-cloud-docs:.*/docker.io\/apecloud\/kb-cloud-docs:${APP_VERSION}/" $IMAGE_FILE_PATH
        else
            sed -i "s/^# KubeBlocks-Cloud .*/# KubeBlocks-Cloud ${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/openconsole:.*[0-9]/docker.io\/apecloud\/openconsole:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/apiserver:.*/docker.io\/apecloud\/apiserver:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/task-manager:.*/docker.io\/apecloud\/task-manager:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/cubetran-front:.*/docker.io\/apecloud\/cubetran-front:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/cr4w:.*/docker.io\/apecloud\/cr4w:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/relay:.*/docker.io\/apecloud\/relay:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/sentry:.*/docker.io\/apecloud\/sentry:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/sentry-init:.*/docker.io\/apecloud\/sentry-init:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kb-cloud-installer:.*/docker.io\/apecloud\/kb-cloud-installer:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/apecloud-charts:.*/docker.io\/apecloud\/apecloud-charts:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/apecloud-addon-charts:${HEAD_APP_VERSION}.*/docker.io\/apecloud\/apecloud-addon-charts:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kb-cloud-hook:.*/docker.io\/apecloud\/kb-cloud-hook:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kb-cloud-docs:.*/docker.io\/apecloud\/kb-cloud-docs:${APP_VERSION}/" $IMAGE_FILE_PATH
        fi
    fi
    
    if [[ ("${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-enterprise-patch") && -n "$KUBEBLOCKS_VERSION" ]]; then
        echo "change KubeBlocks images tag"
        if [[ "${KUBEBLOCKS_VERSION}" == "v"* ]]; then
            KUBEBLOCKS_VERSION="${KUBEBLOCKS_VERSION/v/}"
        fi
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^# KubeBlocks .*/# KubeBlocks v${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kubeblocks-tools:0.8.2/#docker.io\/apecloud\/kubeblocks-tools:0.8.2/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kubeblocks:.*/docker.io\/apecloud\/kubeblocks:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kubeblocks-dataprotection:.*/docker.io\/apecloud\/kubeblocks-dataprotection:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kubeblocks-datascript:.*/docker.io\/apecloud\/kubeblocks-datascript:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kubeblocks-tools:.*/docker.io\/apecloud\/kubeblocks-tools:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kubeblocks-charts:.*/docker.io\/apecloud\/kubeblocks-charts:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^#docker.io\/apecloud\/kubeblocks-tools:0.8.2/docker.io\/apecloud\/kubeblocks-tools:0.8.2/" $IMAGE_FILE_PATH
        else
            sed -i "s/^# KubeBlocks .*/# KubeBlocks v${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kubeblocks-tools:0.8.2/#docker.io\/apecloud\/kubeblocks-tools:0.8.2/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kubeblocks:.*/docker.io\/apecloud\/kubeblocks:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kubeblocks-dataprotection:.*/docker.io\/apecloud\/kubeblocks-dataprotection:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kubeblocks-datascript:.*/docker.io\/apecloud\/kubeblocks-datascript:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kubeblocks-tools:.*/docker.io\/apecloud\/kubeblocks-tools:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kubeblocks-charts:.*/docker.io\/apecloud\/kubeblocks-charts:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^#docker.io\/apecloud\/kubeblocks-tools:0.8.2/docker.io\/apecloud\/kubeblocks-tools:0.8.2/" $IMAGE_FILE_PATH
        fi
    fi 
    
    if [[ ("${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-enterprise-patch") && -n "$GEMINI_VERSION" ]]; then
        echo "change Gemini images tag"
        if [[ "${GEMINI_VERSION}" == "v"* ]]; then
            GEMINI_VERSION="${GEMINI_VERSION/v/}"
        fi
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^# Gemini .*/# Gemini v${GEMINI_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/gemini:.*/docker.io\/apecloud\/gemini:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/gemini-tools:.*/docker.io\/apecloud\/gemini-tools:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/easymetrics:.*/docker.io\/apecloud\/easymetrics:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
        else
            sed -i "s/^# Gemini .*/# Gemini v${GEMINI_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/gemini:.*/docker.io\/apecloud\/gemini:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/gemini-tools:.*/docker.io\/apecloud\/gemini-tools:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/easymetrics:.*/docker.io\/apecloud\/easymetrics:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
        fi
    fi
    
    if [[ ("${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-enterprise-patch") && -n "$OTELD_VERSION" ]]; then
        echo "change Oteld images tag"
        if [[ "${OTELD_VERSION}" == "v"* ]]; then
            OTELD_VERSION="${OTELD_VERSION/v/}"
        fi
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/oteld:0.5.2-k8s21/#docker.io\/apecloud\/oteld:0.5.2-k8s21/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/oteld:.*/docker.io\/apecloud\/oteld:${OTELD_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^#docker.io\/apecloud\/oteld:0.5.2-k8s21/docker.io\/apecloud\/oteld:0.5.2-k8s21/" $IMAGE_FILE_PATH
        else
            sed -i "s/^docker.io\/apecloud\/oteld:0.5.2-k8s21/#docker.io\/apecloud\/oteld:0.5.2-k8s21/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/oteld:.*/docker.io\/apecloud\/oteld:${OTELD_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^#docker.io\/apecloud\/oteld:0.5.2-k8s21/docker.io\/apecloud\/oteld:0.5.2-k8s21/" $IMAGE_FILE_PATH
        fi
    fi

    if [[ ("${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-enterprise-patch") && -n "$OFFLINE_INSTALLER_VERSION" ]]; then
        echo "change Offline Installer images tag"
        if [[ "${OFFLINE_INSTALLER_VERSION}" != *"-offline" ]]; then
            OFFLINE_INSTALLER_VERSION="${OFFLINE_INSTALLER_VERSION}-offline"
        fi
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/kubeblocks-installer:.*/docker.io\/apecloud\/kubeblocks-installer:${OFFLINE_INSTALLER_VERSION}/" $IMAGE_FILE_PATH
        else
            sed -i "s/^docker.io\/apecloud\/kubeblocks-installer:.*/docker.io\/apecloud\/kubeblocks-installer:${OFFLINE_INSTALLER_VERSION}/" $IMAGE_FILE_PATH
        fi
    fi

    if [[ ("${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-enterprise-patch") && -n "$DMS_VERSION" ]]; then
        echo "change Dms images tag"
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/dms:.*/docker.io\/apecloud\/dms:${DMS_VERSION}/" $IMAGE_FILE_PATH
        else
            sed -i "s/^docker.io\/apecloud\/dms:.*/docker.io\/apecloud\/dms:${DMS_VERSION}/" $IMAGE_FILE_PATH
        fi
    fi

    if [[ ("${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-enterprise-patch") && -n "$APE_LOCAL_CSI_DRIVER_VERSION" ]]; then
        echo "change ape-local-csi-driver images tag"
        image_file_path_tmp=".github/images/ape-local-csi-driver.txt"
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^# ape-local-csi-driver .*/# ape-local-csi-driver v${APE_LOCAL_CSI_DRIVER_VERSION}/" $image_file_path_tmp
            sed -i '' "s/^docker.io\/apecloud\/ape-local:.*/docker.io\/apecloud\/ape-local:${APE_LOCAL_CSI_DRIVER_VERSION}/" $image_file_path_tmp
        else
            sed -i "s/^# ape-local-csi-driver .*/# ape-local-csi-driver v${APE_LOCAL_CSI_DRIVER_VERSION}/" $image_file_path_tmp
            sed -i "s/^docker.io\/apecloud\/ape-local:.*/docker.io\/apecloud\/ape-local:${APE_LOCAL_CSI_DRIVER_VERSION}/" $image_file_path_tmp
        fi
    fi

    if [[ "${APP_NAME}" == "kubeblocks-enterprise" && -n "$CUBETRAN_CORE_VERSION" ]]; then
        echo "change cubetran-core images tag"
        imageFiles=("gemini.txt" "kubeblocks-enterprise.txt")
        for imageFile in "${imageFiles[@]}"; do
            image_file_path_tmp=.github/images/${imageFile}
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "s/^docker.io\/apecloud\/cubetran-core:.*/docker.io\/apecloud\/cubetran-core:${CUBETRAN_CORE_VERSION}/" $image_file_path_tmp
            else
                sed -i "s/^docker.io\/apecloud\/cubetran-core:.*/docker.io\/apecloud\/cubetran-core:${CUBETRAN_CORE_VERSION}/" $image_file_path_tmp
            fi
        done
    fi

    if [[ "${APP_NAME}" == "kubeblocks-enterprise" && -n "$KUBEBENCH_VERSION" ]]; then
        echo "change kubebench images tag"
        imageFiles=("kubebench.txt" "kubeblocks-enterprise.txt" "kubeblocks-cloud.txt")
        for imageFile in "${imageFiles[@]}"; do
            image_file_path_tmp=.github/images/${imageFile}
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "s/^docker.io\/apecloud\/kubebench:.*/docker.io\/apecloud\/kubebench:${KUBEBENCH_VERSION}/" $image_file_path_tmp
            else
                sed -i "s/^docker.io\/apecloud\/kubebench:.*/docker.io\/apecloud\/kubebench:${KUBEBENCH_VERSION}/" $image_file_path_tmp
            fi
        done
    fi

    app_package_name=${APP_NAME}-${APP_VERSION}.tar.gz
    save_flag=0
    for i in {1..10}; do
        save_cmd="docker save "
        while read -r image
        do
            if [[ -z "$image" || "$image" == "#"* ]]; then
                continue
            fi
            echo "pull image $image"
            for j in {1..10}; do
                docker pull "$image"
                ret_msg=$?
                if [[ $ret_msg -eq 0 ]]; then
                    echo "$(tput -T xterm setaf 2)pull image $image success$(tput -T xterm sgr0)"
                    break
                fi
                sleep 1
            done
            save_cmd="${save_cmd} $image "
        done < $IMAGE_FILE_PATH
        save_cmd="${save_cmd} | gzip > ${app_package_name} "
        echo "$save_cmd"
        eval "$save_cmd"
        ret_msg=$?
        if [[ $ret_msg -eq 0 ]]; then
            echo "$(tput -T xterm setaf 2)save ${app_package_name} success$(tput -T xterm sgr0)"
            save_flag=1
            break
        fi
        sleep 1
    done
    if [[ $save_flag -eq 0 ]]; then
        echo "$(tput -T xterm setaf 1)save ${app_package_name} error$(tput -T xterm sgr0)"
        exit 1
    fi
}

check_manifests_version() {
    if [[ ! -f "${MANIFESTS_FILE}" ]]; then
        return
    fi
    APP_VERSION=$(yq e ".kubeblocks-cloud[0].version"  ${MANIFESTS_FILE})
    KUBEBLOCKS_VERSION=$(yq e ".kubeblocks[0].version"  ${MANIFESTS_FILE})
    GEMINI_VERSION=$(yq e ".gemini[0].version"  ${MANIFESTS_FILE})
    APE_LOCAL_CSI_DRIVER_VERSION=$(yq e ".ape-local-csi-driver[0].version"  ${MANIFESTS_FILE})

    OTELD_IMAGE=$(yq e ".gemini-monitor[0].images[]"  ${MANIFESTS_FILE} | grep "apecloud/oteld:")
    if [[ -n "$OTELD_IMAGE" ]]; then
        OTELD_VERSION="${OTELD_IMAGE#*:}"
    fi

    OFFLINE_INSTALLER_IMAGE=$(yq e ".kubeblocks-cloud[0].images[]"  ${MANIFESTS_FILE} | grep "apecloud/kubeblocks-installer:")
    if [[ -n "$OFFLINE_INSTALLER_IMAGE" ]]; then
        OFFLINE_INSTALLER_VERSION="${OFFLINE_INSTALLER_IMAGE#*:}"
    fi

    DMS_IMAGE=$(yq e ".kubeblocks-cloud[0].images[]"  ${MANIFESTS_FILE} | grep "apecloud/dms:")
    if [[ -n "$DMS_IMAGE" ]]; then
        DMS_VERSION="${DMS_IMAGE#*:}"
    fi

    CUBETRAN_CORE_IMAGE=$(yq e ".gemini[0].images[]"  ${MANIFESTS_FILE} | grep "apecloud/cubetran-core:")
    if [[ -n "$CUBETRAN_CORE_IMAGE" ]]; then
        CUBETRAN_CORE_VERSION="${CUBETRAN_CORE_IMAGE#*:}"
    fi

    KUBEBENCH_IMAGE=$(yq e ".kubebench[0].images[]"  ${MANIFESTS_FILE} | grep "apecloud/kubebench:")
    if [[ -n "$KUBEBENCH_IMAGE" ]]; then
        KUBEBENCH_VERSION="${KUBEBENCH_IMAGE#*:}"
    fi

    echo "MANIFESTS APP_VERSION:"${APP_VERSION}
    echo "MANIFESTS CLOUD_VERSION:"${APP_VERSION}
    echo "MANIFESTS KUBEBLOCKS_VERSION:"${KUBEBLOCKS_VERSION}
    echo "MANIFESTS GEMINI_VERSION:"${GEMINI_VERSION}
    echo "MANIFESTS OTELD_VERSION:"${OTELD_VERSION}
    echo "MANIFESTS OFFLINE_INSTALLER_VERSION:"${OFFLINE_INSTALLER_VERSION}
    echo "MANIFESTS DMS_VERSION:"${DMS_VERSION}
    echo "MANIFESTS APE_LOCAL_CSI_DRIVER_VERSION:${APE_LOCAL_CSI_DRIVER_VERSION}"
    echo "MANIFESTS CUBETRAN_CORE_VERSION:${CUBETRAN_CORE_VERSION}"
    echo "MANIFESTS KUBEBENCH_VERSION:${KUBEBENCH_VERSION}"
}

main() {
    local UNAME=`uname -s`
    local APP_VERSION=${APP_VERSION_TMP}
    local KUBEBLOCKS_VERSION="${KUBEBLOCKS_VERSION_TMP}"
    local GEMINI_VERSION="${GEMINI_VERSION_TMP}"
    local OTELD_VERSION="${OTELD_VERSION_TMP?}"
    local OFFLINE_INSTALLER_VERSION="${OFFLINE_INSTALLER_VERSION_TMP}"
    local DMS_VERSION="${DMS_VERSION_TMP}"
    local MANIFESTS_FILE="apecloud/manifests/deploy-manifests.yaml"
    local APE_LOCAL_CSI_DRIVER_VERSION=""
    local CUBETRAN_CORE_VERSION=""
    local KUBEBENCH_VERSION=""

    check_manifests_version

    add_images_list

    save_images_package
}

main "$@"
