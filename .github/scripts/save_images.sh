#!/bin/bash

set -euo pipefail

readonly ADD_IMAGES_LIST=${add_images?}
readonly APP_NAME=${app_name?}
readonly IMAGE_FILE_PATH=${images_file?}
readonly APP_VERSION_TMP=${app_version?}
readonly KUBEBLOCKS_VERSION_TMP="${kubeblocks_version?}"
readonly GEMINI_VERSION_TMP="${gemini_version?}"
readonly OTELD_VERSION_TMP="${oteld_version?}"
readonly OFFLINE_INSTALLER_VERSION_TMP="${installer_version?}"
readonly DMS_VERSION_TMP="${dms_version?}"
readonly APECLOUD_MCP_VERSION_TMP="${apecloud_mcp_version?}"
readonly PLATFORM="${platform?}"

echo "ADD_IMAGES_LIST:"${ADD_IMAGES_LIST}
echo "APP_NAME:"${APP_NAME}
echo "IMAGE_FILE_PATH:"${IMAGE_FILE_PATH}
echo "APP_VERSION:"${APP_VERSION_TMP}
echo "CLOUD_VERSION:"${APP_VERSION_TMP}
echo "KUBEBLOCKS_VERSIONS:"${KUBEBLOCKS_VERSION_TMP}
echo "GEMINI_VERSION:"${GEMINI_VERSION_TMP}
echo "OTELD_VERSION:"${OTELD_VERSION_TMP}
echo "OFFLINE_INSTALLER_VERSION:"${OFFLINE_INSTALLER_VERSION_TMP}
echo "DMS_VERSION:"${DMS_VERSION_TMP}
echo "APECLOUD_MCP_VERSION:"${APECLOUD_MCP_VERSION_TMP}
echo "PLATFORM:"${PLATFORM}

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
            sed -i '' "s/^# kubeblocks-enterprise .*/# kubeblocks-enterprise ${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^# kubeblocks-enterprise-patch .*/# kubeblocks-enterprise-patch ${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^# KubeBlocks-Cloud .*/# KubeBlocks-Cloud ${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/openconsole:.*[0-9]/docker.io\/apecloud\/openconsole:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/apiserver:.*/docker.io\/apecloud\/apiserver:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/task-manager:.*/docker.io\/apecloud\/task-manager:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/cubetran-front:.*/docker.io\/apecloud\/cubetran-front:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/cr4w:.*/docker.io\/apecloud\/cr4w:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kubeblocks-console:.*[0-9]/docker.io\/apecloud\/kubeblocks-console:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/relay:.*/docker.io\/apecloud\/relay:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/sentry:.*/docker.io\/apecloud\/sentry:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/sentry-init:.*/docker.io\/apecloud\/sentry-init:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kb-cloud-installer:.*/docker.io\/apecloud\/kb-cloud-installer:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kb-cloud-hook:.*/docker.io\/apecloud\/kb-cloud-hook:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i '' "s/^docker.io\/apecloud\/kb-cloud-docs:.*/docker.io\/apecloud\/kb-cloud-docs:${APP_VERSION}/" $IMAGE_FILE_PATH
        else
            sed -i "s/^# kubeblocks-enterprise .*/# kubeblocks-enterprise ${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^# kubeblocks-enterprise-patch .*/# kubeblocks-enterprise-patch ${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^# KubeBlocks-Cloud .*/# KubeBlocks-Cloud ${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/openconsole:.*[0-9]/docker.io\/apecloud\/openconsole:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/apiserver:.*/docker.io\/apecloud\/apiserver:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/task-manager:.*/docker.io\/apecloud\/task-manager:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/cubetran-front:.*/docker.io\/apecloud\/cubetran-front:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/cr4w:.*/docker.io\/apecloud\/cr4w:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kubeblocks-console:.*[0-9]/docker.io\/apecloud\/kubeblocks-console:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/relay:.*/docker.io\/apecloud\/relay:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/sentry:.*/docker.io\/apecloud\/sentry:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/sentry-init:.*/docker.io\/apecloud\/sentry-init:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kb-cloud-installer:.*/docker.io\/apecloud\/kb-cloud-installer:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kb-cloud-hook:.*/docker.io\/apecloud\/kb-cloud-hook:${APP_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/kb-cloud-docs:.*/docker.io\/apecloud\/kb-cloud-docs:${APP_VERSION}/" $IMAGE_FILE_PATH
        fi
    fi
    
    if [[ ("${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-enterprise-patch" || "$APP_NAME" == "gemini") && -n "$KUBEBLOCKS_VERSIONS" ]]; then
        echo "change KubeBlocks images tag"
        for KUBEBLOCKS_VERSION in $(echo "${KUBEBLOCKS_VERSIONS}" | sed 's/|/ /g'); do
            if [[ "${KUBEBLOCKS_VERSION}" == "v"* ]]; then
                KUBEBLOCKS_VERSION="${KUBEBLOCKS_VERSION/v/}"
            fi
            IFS='.' read -r major_v minor_v rest_v <<< "${KUBEBLOCKS_VERSION}"
            KUBEBLOCKS_VERSION_HEAD="$major_v.$minor_v."
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "s/^# KubeBlocks v${KUBEBLOCKS_VERSION_HEAD}.*/# KubeBlocks v${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
                sed -i '' "s/^docker.io\/apecloud\/kubeblocks:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
                sed -i '' "s/^docker.io\/apecloud\/kubeblocks-dataprotection:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-dataprotection:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
                sed -i '' "s/^docker.io\/apecloud\/kubeblocks-datascript:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-datascript:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
                sed -i '' "s/^docker.io\/apecloud\/kubeblocks-tools:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-tools:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
                sed -i '' "s/^docker.io\/apecloud\/kubeblocks-charts:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-charts:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            else
                sed -i "s/^# KubeBlocks .*/# KubeBlocks v${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
                sed -i "s/^docker.io\/apecloud\/kubeblocks:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
                sed -i "s/^docker.io\/apecloud\/kubeblocks-dataprotection:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-dataprotection:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
                sed -i "s/^docker.io\/apecloud\/kubeblocks-datascript:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-datascript:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
                sed -i "s/^docker.io\/apecloud\/kubeblocks-tools:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-tools:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
                sed -i "s/^docker.io\/apecloud\/kubeblocks-charts:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-charts:${KUBEBLOCKS_VERSION}/" $IMAGE_FILE_PATH
            fi
        done
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
            sed -i '' "s/^docker.io\/apecloud\/sla:.*/docker.io\/apecloud\/sla:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
        else
            sed -i "s/^# Gemini .*/# Gemini v${GEMINI_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/gemini:.*/docker.io\/apecloud\/gemini:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/gemini-tools:.*/docker.io\/apecloud\/gemini-tools:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/easymetrics:.*/docker.io\/apecloud\/easymetrics:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
            sed -i "s/^docker.io\/apecloud\/sla:.*/docker.io\/apecloud\/sla:${GEMINI_VERSION}/" $IMAGE_FILE_PATH
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

    if [[ ("${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-enterprise-patch") && -n "$APECLOUD_MCP_VERSION" ]]; then
        echo "change Apecloud-MCP images tag"
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/apecloud-mcp:.*/docker.io\/apecloud\/apecloud-mcp:${APECLOUD_MCP_VERSION}/" $IMAGE_FILE_PATH
        else
            sed -i "s/^docker.io\/apecloud\/apecloud-mcp:.*/docker.io\/apecloud\/apecloud-mcp:${APECLOUD_MCP_VERSION}/" $IMAGE_FILE_PATH
        fi
    fi

    if [[ ("${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-enterprise-patch") && -n "$OB_GRPC_SERVER_VERSION" ]]; then
        echo "change OB-GRPC-Server images tag"
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/ob-grpc-server:.*/docker.io\/apecloud\/ob-grpc-server:${OB_GRPC_SERVER_VERSION}/" $IMAGE_FILE_PATH
        else
            sed -i "s/^docker.io\/apecloud\/ob-grpc-server:.*/docker.io\/apecloud\/ob-grpc-server:${OB_GRPC_SERVER_VERSION}/" $IMAGE_FILE_PATH
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

    if [[ "${APP_NAME}" == "kubeblocks-enterprise" && -n "$CLOUD_APE_DTS_VERSION" ]]; then
        echo "change cloud ape-dts images tag"
        imageFiles=("kubeblocks-cloud.txt" "kubeblocks-enterprise.txt")
        for imageFile in "${imageFiles[@]}"; do
            image_file_path_tmp=.github/images/${imageFile}
            if [[ "${imageFile}" == "kubeblocks-enterprise.txt" ]]; then
                cloud_line=$(grep -n "apecloud/ape-dts" $image_file_path_tmp | head -1 | cut -d: -f1)
                if [[ "$UNAME" == "Darwin" ]]; then
                    sed -i '' "${cloud_line}s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${CLOUD_APE_DTS_VERSION}/" $image_file_path_tmp
                else
                    sed -i "${cloud_line}s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${CLOUD_APE_DTS_VERSION}/" $image_file_path_tmp
                fi
            else
                if [[ "$UNAME" == "Darwin" ]]; then
                    sed -i '' "s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${CLOUD_APE_DTS_VERSION}/" $image_file_path_tmp
                else
                    sed -i "s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${CLOUD_APE_DTS_VERSION}/" $image_file_path_tmp
                fi
            fi
        done
    fi

    if [[ "${APP_NAME}" == "kubeblocks-enterprise" && -n "$GEMINI_APE_DTS_VERSION" ]]; then
        echo "change gemini ape-dts images tag"
        imageFiles=("gemini.txt" "kubeblocks-enterprise.txt")
        for imageFile in "${imageFiles[@]}"; do
            image_file_path_tmp=.github/images/${imageFile}
            if [[ "${imageFile}" == "kubeblocks-enterprise.txt" ]]; then
                gemini_line=$(grep -n "apecloud/ape-dts" $image_file_path_tmp | sed -n '2p' | cut -d: -f1)
                if [[ "$UNAME" == "Darwin" ]]; then
                    sed -i '' "${gemini_line}s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${GEMINI_APE_DTS_VERSION}/" $image_file_path_tmp
                else
                    sed -i "${gemini_line}s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${GEMINI_APE_DTS_VERSION}/" $image_file_path_tmp
                fi
            else
                if [[ "$UNAME" == "Darwin" ]]; then
                    sed -i '' "s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${GEMINI_APE_DTS_VERSION}/" $image_file_path_tmp
                else
                    sed -i "s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${GEMINI_APE_DTS_VERSION}/" $image_file_path_tmp
                fi
            fi
        done
    fi

    if [[ "${APP_NAME}" == "kubeblocks-enterprise" && -n "$CUBETRAN_PLATFORM_VERSION" ]]; then
        echo "change cubetran-platform images tag"
        imageFiles=("gemini.txt" "kubeblocks-enterprise.txt")
        for imageFile in "${imageFiles[@]}"; do
            image_file_path_tmp=.github/images/${imageFile}
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "s/^docker.io\/apecloud\/cubetran-platform:.*/docker.io\/apecloud\/cubetran-platform:${CUBETRAN_PLATFORM_VERSION}/" $image_file_path_tmp
            else
                sed -i "s/^docker.io\/apecloud\/cubetran-platform:.*/docker.io\/apecloud\/cubetran-platform:${CUBETRAN_PLATFORM_VERSION}/" $image_file_path_tmp
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

    if [[ ("${APP_NAME}" == "kubeblocks-enterprise" || "$APP_NAME" == "kubeblocks-cloud" || "$APP_NAME" == "kubeblocks-enterprise-patch") && -n "$CASDOOR_VERSION" ]]; then
        echo "change casdoor images tag"
        imageFiles=("kubeblocks-enterprise.txt" "kubeblocks-cloud.txt")
        for imageFile in "${imageFiles[@]}"; do
            image_file_path_tmp=.github/images/${imageFile}
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "s/^# casdoor .*/# casdoor ${CASDOOR_VERSION}/" $image_file_path_tmp
                sed -i '' "s|^docker.io/apecloud/casdoor:.*|docker.io/apecloud/casdoor:${CASDOOR_VERSION}|" $image_file_path_tmp
            else
                sed -i "s/^# casdoor .*/# casdoor ${CASDOOR_VERSION}/" $image_file_path_tmp
                sed -i "s|^docker.io/apecloud/casdoor:.*|docker.io/apecloud/casdoor:${CASDOOR_VERSION}|" $image_file_path_tmp
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

            if [[ "${PLATFORM}" == *"arm64"* ]]; then
                echo "docker pull --platform linux/arm64 $image"
            else
                echo "docker pull $image"
            fi
            for j in {1..10}; do
                if [[ "${PLATFORM}" == *"arm64"* ]]; then
                    docker pull --platform linux/arm64 "$image"
                else
                    docker pull "$image"
                fi
                ret_msg=$?
                if [[ $ret_msg -eq 0 ]]; then
                    echo "$(tput -T xterm setaf 2)pull image $image success$(tput -T xterm sgr0)"
                    break
                fi
                sleep 1
            done
            save_cmd="${save_cmd} $image "
        done < $IMAGE_FILE_PATH
        df -h
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
    KUBEBLOCKS_VERSIONS=$(yq e '[.kubeblocks[].version] | join("|")' ${MANIFESTS_FILE})
    GEMINI_VERSION=$(yq e ".gemini[0].version"  ${MANIFESTS_FILE})
    APE_LOCAL_CSI_DRIVER_VERSION=$(yq e ".ape-local-csi-driver[0].version"  ${MANIFESTS_FILE})
    CASDOOR_VERSION=$(yq e ".casdoor-helm-charts[0].version"  ${MANIFESTS_FILE})

    OTELD_IMAGE=$(yq e ".gemini-monitor[0].images[]"  ${MANIFESTS_FILE} | (grep "apecloud/oteld:" || true))
    if [[ -n "$OTELD_IMAGE" ]]; then
        OTELD_VERSION="${OTELD_IMAGE#*:}"
    fi

    OFFLINE_INSTALLER_IMAGE=$(yq e ".kubeblocks-cloud[0].images[]"  ${MANIFESTS_FILE} | (grep "apecloud/kubeblocks-installer:" || true))
    if [[ -n "$OFFLINE_INSTALLER_IMAGE" ]]; then
        OFFLINE_INSTALLER_VERSION="${OFFLINE_INSTALLER_IMAGE#*:}"
    fi

    DMS_IMAGE=$(yq e ".kubeblocks-cloud[0].images[]"  ${MANIFESTS_FILE} | (grep "apecloud/dms:" || true))
    if [[ -n "$DMS_IMAGE" ]]; then
        DMS_VERSION="${DMS_IMAGE#*:}"
    fi

    APECLOUD_MCP_IMAGE=$(yq e ".kubeblocks-cloud[0].images[]"  ${MANIFESTS_FILE} | (grep "apecloud/apecloud-mcp:" || true))
    if [[ -n "$APECLOUD_MCP_IMAGE" ]]; then
        APECLOUD_MCP_VERSION="${APECLOUD_MCP_IMAGE#*:}"
    fi

    OB_GRPC_SERVER_IMAGE=$(yq e ".kubeblocks-cloud[0].images[]"  ${MANIFESTS_FILE} | (grep "apecloud/ob-grpc-server:" || true))
    if [[ -n "$OB_GRPC_SERVER_IMAGE" ]]; then
        OB_GRPC_SERVER_VERSION="${OB_GRPC_SERVER_IMAGE#*:}"
    fi

    CLOUD_APE_DTS_IMAGE=$(yq e ".kubeblocks-cloud[0].images[]"  ${MANIFESTS_FILE} | (grep "apecloud/ape-dts:" || true))
    if [[ -n "$CLOUD_APE_DTS_IMAGE" ]]; then
        CLOUD_APE_DTS_VERSION="${CLOUD_APE_DTS_IMAGE#*:}"
    fi

    GEMINI_APE_DTS_IMAGE=$(yq e ".gemini[0].images[]"  ${MANIFESTS_FILE} | (grep "apecloud/ape-dts:" || true))
    if [[ -n "$GEMINI_APE_DTS_IMAGE" ]]; then
        GEMINI_APE_DTS_VERSION="${GEMINI_APE_DTS_IMAGE#*:}"
    fi

    CUBETRAN_PLATFORM_IMAGE=$(yq e ".gemini[0].images[]"  ${MANIFESTS_FILE} | (grep "apecloud/cubetran-platform:" || true))
    if [[ -n "$CUBETRAN_PLATFORM_IMAGE" ]]; then
        CUBETRAN_PLATFORM_VERSION="${CUBETRAN_PLATFORM_IMAGE#*:}"
    fi

    KUBEBENCH_IMAGE=$(yq e ".kubebench[0].images[]"  ${MANIFESTS_FILE} | (grep "apecloud/kubebench:" || true))
    if [[ -n "$KUBEBENCH_IMAGE" ]]; then
        KUBEBENCH_VERSION="${KUBEBENCH_IMAGE#*:}"
    fi

    echo "MANIFESTS APP_VERSION:"${APP_VERSION}
    echo "MANIFESTS CLOUD_VERSION:"${APP_VERSION}
    echo "MANIFESTS KUBEBLOCKS_VERSIONS:"${KUBEBLOCKS_VERSIONS}
    echo "MANIFESTS GEMINI_VERSION:"${GEMINI_VERSION}
    echo "MANIFESTS OTELD_VERSION:"${OTELD_VERSION}
    echo "MANIFESTS OFFLINE_INSTALLER_VERSION:"${OFFLINE_INSTALLER_VERSION}
    echo "MANIFESTS DMS_VERSION:"${DMS_VERSION}
    echo "MANIFESTS APECLOUD_MCP_VERSION:"${APECLOUD_MCP_VERSION}
    echo "MANIFESTS OB_GRPC_SERVER_VERSION:${OB_GRPC_SERVER_VERSION}"
    echo "MANIFESTS APE_LOCAL_CSI_DRIVER_VERSION:${APE_LOCAL_CSI_DRIVER_VERSION}"
    echo "MANIFESTS CLOUD_APE_DTS_VERSION:${CLOUD_APE_DTS_VERSION}"
    echo "MANIFESTS GEMINI_APE_DTS_VERSION:${GEMINI_APE_DTS_VERSION}"
    echo "MANIFESTS CUBETRAN_PLATFORM_VERSION:${CUBETRAN_PLATFORM_VERSION}"
    echo "MANIFESTS KUBEBENCH_VERSION:${KUBEBENCH_VERSION}"
    echo "MANIFESTS CASDOOR_VERSION:${CASDOOR_VERSION}"
}

update_addon_images_from_manifest() {
    local addon_name="$1"
    
    # Extract all versions for this addon from deploy-manifests.yaml
    mapfile -t versions < <(yq e ".${addon_name}[].version" ${MANIFESTS_FILE} 2>/dev/null || true)
    
    if [[ ${#versions[@]} -eq 0 ]]; then
        echo "  No versions found for ${addon_name} in manifest"
        return
    fi
    
    echo "$(tput -T xterm setaf 3)Updating ${addon_name} images from manifest (${#versions[@]} versions)$(tput -T xterm sgr0)"
    
    # Determine if this addon has ARM-specific files and special handling
    local has_arm_files=0
    local arm_only=0  # For damengdb: only update arm file, skip regular file
    case "$addon_name" in
        damengdb)
            has_arm_files=1
            arm_only=1  # Only update arm file
            ;;
        elasticsearch|mysql|oceanbase)
            has_arm_files=1
            ;;
    esac
    
    # Process each version
    for i in "${!versions[@]}"; do
        local version="${versions[$i]}"
        local major_minor="${version%%.*}"
        local target_dir=""
        
        # Determine target directory based on version prefix
        if [[ "$version" == 0.9.* ]]; then
            target_dir=".github/images/0.9"
        elif [[ "$version" == 1.0.* ]]; then
            target_dir=".github/images/1.0"
        else
            echo "  WARNING: Unknown version prefix for ${addon_name} v${version}, skipping"
            continue
        fi
        
        # List of files to update (regular file and optionally ARM file)
        local files_to_update=()
        
        # For damengdb, only update arm file
        if [[ $arm_only -eq 1 ]]; then
            files_to_update=("${target_dir}/${addon_name}-arm.txt")
        else
            # For other addons, update regular file
            files_to_update=("${target_dir}/${addon_name}.txt")
            # And also arm file if applicable
            if [[ $has_arm_files -eq 1 ]]; then
                files_to_update+=("${target_dir}/${addon_name}-arm.txt")
            fi
        fi
        
        # Process each file (regular and ARM)
        for txt_file in "${files_to_update[@]}"; do
            if [[ ! -f "$txt_file" ]]; then
                echo "  WARNING: File not found: ${txt_file}, skipping"
                continue
            fi
            
            echo "  Processing ${addon_name} v${version} -> ${txt_file}"
            
            # Extract images for this specific version from manifest
            mapfile -t manifest_images < <(yq e ".${addon_name}[${i}].images[]" ${MANIFESTS_FILE} 2>/dev/null || true)
            
            if [[ ${#manifest_images[@]} -eq 0 ]]; then
                echo "    WARNING: No images found for ${addon_name} v${version}"
                continue
            fi
            
            # Apply special filtering rules for ARM-specific files
            local filtered_images=()
            for img in "${manifest_images[@]}"; do
                local should_include=1
                
                # Check if this is an ARM-specific file
                if [[ "$txt_file" == *"-arm.txt" ]]; then
                    # elasticsearch-arm: exclude 6.8.23 versions
                    if [[ "$addon_name" == "elasticsearch" ]]; then
                        if [[ "$img" == *"elasticsearch:6.8.23"* ]] || [[ "$img" == *"kibana:6.8.23"* ]]; then
                            should_include=0
                        fi
                    fi
                    
                    # mysql-arm: exclude 5.7.44 and xtrabackup 2.4
                    if [[ "$addon_name" == "mysql" ]]; then
                        if [[ "$img" == *"mysql:5.7.44"* ]] || \
                           [[ "$img" == *"mysql_audit_log:5.7.44"* ]] || \
                           [[ "$img" == *"percona-xtrabackup:2.4"* ]] || \
                           [[ "$img" == *"xtrabackup:2.4"* ]]; then
                            should_include=0
                        fi
                    fi
                    
                    # oceanbase-arm: exclude ocp suffix
                    if [[ "$addon_name" == "oceanbase" ]]; then
                        if [[ "$img" == *"-ocp"* ]]; then
                            should_include=0
                        fi
                    fi
                else
                    # For non-ARM files, apply oceanbase filtering (exclude arm64 suffix)
                    if [[ "$addon_name" == "oceanbase" ]]; then
                        if [[ "$img" == *"-arm64"* ]]; then
                            should_include=0
                        fi
                    fi
                fi
                
                if [[ $should_include -eq 1 ]]; then
                    filtered_images+=("$img")
                fi
            done
            
            # Use filtered images
            manifest_images=("${filtered_images[@]}")
        
        # Read the original file and find where the first comment section ends
        # We need to preserve everything after the first block of images (including other # comments)
        local first_comment_line=1
        local first_image_block_end=0
        local line_num=0
        local found_first_image=0
        
        while IFS= read -r line; do
            line_num=$((line_num + 1))
            
            # Skip empty lines at the beginning
            if [[ $line_num -eq 1 && -z "$line" ]]; then
                continue
            fi
            
            # First line should be the version comment
            if [[ $line_num -eq 1 && "$line" == \#* ]]; then
                first_comment_line=1
                continue
            fi
            
            # Check if this is an image line (starts with docker.io or contains /)
            if [[ "$line" == docker.io/* || "$line" == *"/"* ]] && [[ "$line" != \#* ]]; then
                if [[ $found_first_image -eq 0 ]]; then
                    found_first_image=1
                fi
                first_image_block_end=$line_num
            elif [[ "$line" == \#* ]] && [[ $found_first_image -eq 1 ]]; then
                # Found a new comment section after images, this is where first block ends
                break
            elif [[ -z "$line" ]] && [[ $found_first_image -eq 1 ]]; then
                # Empty line after images might be end of first block
                # Check if next non-empty line is a comment
                local next_line_num=$((line_num + 1))
                local next_line=$(sed -n "${next_line_num}p" "$txt_file")
                if [[ "$next_line" == \#* ]]; then
                    first_image_block_end=$line_num
                    break
                fi
            fi
        done < "$txt_file"
        
        # If we didn't find a clear boundary, assume all content after first comment is first block
        if [[ $first_image_block_end -eq 0 ]]; then
            first_image_block_end=$(wc -l < "$txt_file")
        fi
        
        # Extract content to preserve (everything after first image block)
        local preserved_content=""
        if [[ $first_image_block_end -lt $(wc -l < "$txt_file") ]]; then
            preserved_content=$(tail -n +$((first_image_block_end + 1)) "$txt_file")
        fi
        
        # Create temporary file with new content
        local tmp_file="${txt_file}.tmp"
        
        # Write version comment
        echo "# ${addon_name} v${version}" > "$tmp_file"
        
        # Write images from manifest (add docker.io/ prefix if needed)
        for img in "${manifest_images[@]}"; do
            # Ensure proper prefix
            if [[ "$img" != docker.io/* ]]; then
                echo "docker.io/${img}" >> "$tmp_file"
            else
                echo "$img" >> "$tmp_file"
            fi
        done
        
        # Append preserved content if exists
        if [[ -n "$preserved_content" ]]; then
            # Remove trailing blank lines from preserved content before appending
            local cleaned_content=$(echo "$preserved_content" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')
            if [[ -n "$cleaned_content" ]]; then
                echo "$cleaned_content" >> "$tmp_file"
            fi
        fi
        
        # Ensure exactly one trailing newline
        # Simple and reliable approach: use perl to remove all trailing newlines, then add one
        if command -v perl &> /dev/null; then
            perl -pi -e 'chomp if eof' "$tmp_file"  # Remove trailing newlines
            echo "" >> "$tmp_file"  # Add exactly one
        else
            # Fallback: use python if available
            if command -v python3 &> /dev/null; then
                python3 -c "
import sys
with open('$tmp_file', 'r') as f:
    content = f.read()
content = content.rstrip('\n') + '\n'
with open('$tmp_file', 'w') as f:
    f.write(content)
"
            else
                # Last resort: manual approach with sed
                # Remove all trailing empty lines
                while [[ $(tail -c 1 "$tmp_file" | wc -l) -eq 1 ]] && [[ -s "$tmp_file" ]]; do
                    if [[ "$UNAME" == "Darwin" ]]; then
                        sed -i '' -e '${/^$/d;}' "$tmp_file"
                    else
                        sed -i -e '${/^$/d;}' "$tmp_file"
                    fi
                done
                echo "" >> "$tmp_file"
            fi
        fi
        
        # Replace original file
        mv "$tmp_file" "$txt_file"
        
        echo "    Updated ${#manifest_images[@]} images for ${addon_name} v${version}"
        done  # End of for txt_file loop
    done  # End of for i loop
}

update_addon_chart_versions_from_manifest() {
    local charts_file=".github/charts/kubeblocks-enterprise.txt"
    
    if [[ ! -f "$charts_file" ]]; then
        echo "Charts file not found: $charts_file"
        return
    fi
    
    echo "$(tput -T xterm setaf 3)Updating addon chart versions in kubeblocks-enterprise.txt$(tput -T xterm sgr0)"
    
    # Dynamically extract all engine addons from manifest
    mapfile -t engine_addons < <(yq e 'with_entries(select(.value[0].type == "engine" and .value[0].isAddon == true)) | keys | .[]' "${MANIFESTS_FILE}" 2>/dev/null || true)
    
    for addon_name in "${engine_addons[@]}"; do
        # Get versions from manifest
        mapfile -t manifest_versions < <(yq e ".${addon_name}[].version" ${MANIFESTS_FILE} 2>/dev/null || true)
        
        if [[ ${#manifest_versions[@]} -eq 0 ]]; then
            # No versions in manifest, skip
            continue
        fi
        
        # Get existing versions from charts file
        mapfile -t existing_lines < <(grep "^${addon_name}:" "$charts_file" || true)
        
        # Build arrays of existing and manifest versions for comparison
        local existing_versions=()
        for line in "${existing_lines[@]}"; do
            if [[ -n "$line" ]]; then
                local ver="${line#*:}"
                existing_versions+=("$ver")
            fi
        done
        
        # Find versions to add (in manifest but not in existing)
        local versions_to_add=()
        for manifest_ver in "${manifest_versions[@]}"; do
            local found=0
            for existing_ver in "${existing_versions[@]}"; do
                if [[ "$manifest_ver" == "$existing_ver" ]]; then
                    found=1
                    break
                fi
            done
            if [[ $found -eq 0 ]]; then
                versions_to_add+=("$manifest_ver")
            fi
        done
        
        # Find versions to remove (in existing but not in manifest)
        local versions_to_remove=()
        for existing_ver in "${existing_versions[@]}"; do
            local found=0
            for manifest_ver in "${manifest_versions[@]}"; do
                if [[ "$existing_ver" == "$manifest_ver" ]]; then
                    found=1
                    break
                fi
            done
            if [[ $found -eq 0 ]]; then
                versions_to_remove+=("$existing_ver")
            fi
        done
        
        # Update existing versions (match by position) - only update positions that exist in both arrays
        local existing_count=${#existing_lines[@]}
        local manifest_count=${#manifest_versions[@]}
        local min_count=$((existing_count < manifest_count ? existing_count : manifest_count))
        
        for ((idx=0; idx<min_count; idx++)); do
            local manifest_ver="${manifest_versions[$idx]}"
            local existing_line="${existing_lines[$idx]}"
            local existing_ver="${existing_line#*:}"
            
            if [[ "$manifest_ver" != "$existing_ver" ]]; then
                echo "    Updating ${addon_name}:${existing_ver} -> ${addon_name}:${manifest_ver}"
                # Use fixed string replacement instead of regex to avoid escaping issues
                if [[ "$UNAME" == "Darwin" ]]; then
                    local tmp_charts=$(mktemp)
                    awk -v old="$existing_line" -v new="${addon_name}:${manifest_ver}" '{if ($0 == old) print new; else print}' "$charts_file" > "$tmp_charts"
                    mv "$tmp_charts" "$charts_file"
                else
                    local tmp_charts=$(mktemp)
                    awk -v old="$existing_line" -v new="${addon_name}:${manifest_ver}" '{if ($0 == old) print new; else print}' "$charts_file" > "$tmp_charts"
                    mv "$tmp_charts" "$charts_file"
                fi
            fi
        done
        
        # Add new versions (only if manifest has more versions than existing)
        if [[ $manifest_count -gt $existing_count ]]; then
            for ver in "${versions_to_add[@]}"; do
                echo "    Adding ${addon_name}:${ver}"
                echo "${addon_name}:${ver}" >> "$charts_file"
            done
        fi
        
        # Remove obsolete versions (only if existing has more versions than manifest)
        if [[ $existing_count -gt $manifest_count ]]; then
            for ver in "${versions_to_remove[@]}"; do
                echo "    Removing ${addon_name}:${ver}"
                if [[ "$UNAME" == "Darwin" ]]; then
                    sed -i '' "/^${addon_name}:${ver}$/d" "$charts_file"
                else
                    sed -i "/^${addon_name}:${ver}$/d" "$charts_file"
                fi
            done
        fi
    done
    
    echo "$(tput -T xterm setaf 2)Addon chart versions updated successfully$(tput -T xterm sgr0)"
}

update_addon_image_chart_versions_from_manifest() {
    local images_files=(".github/images/kubeblocks-enterprise.txt" ".github/images/kubeblocks-cloud.txt")
    local charts_file=".github/charts/kubeblocks-enterprise.txt"
    
    echo "$(tput -T xterm setaf 3)Updating addon image chart versions in kubeblocks-enterprise.txt and kubeblocks-cloud.txt$(tput -T xterm sgr0)"
    
    # Dynamically extract all engine addons from manifest
    mapfile -t engine_addons < <(yq e 'with_entries(select(.value[0].type == "engine" and .value[0].isAddon == true)) | keys | .[]' "${MANIFESTS_FILE}" 2>/dev/null || true)
    
    for images_file in "${images_files[@]}"; do
        if [[ ! -f "$images_file" ]]; then
            echo "  WARNING: Images file not found: $images_file, skipping"
            continue
        fi
        
        for addon_name in "${engine_addons[@]}"; do
            # Get versions from manifest
            mapfile -t manifest_versions < <(yq e ".${addon_name}[].version" ${MANIFESTS_FILE} 2>/dev/null || true)
            
            if [[ ${#manifest_versions[@]} -eq 0 ]]; then
                # No versions in manifest, skip
                continue
            fi
            
            # Check if this addon exists in charts file
            if [[ -f "$charts_file" ]]; then
                local charts_lines=$(grep "^${addon_name}:" "$charts_file" || true)
                if [[ -z "$charts_lines" ]]; then
                    # Addon not in charts file, skip
                    continue
                fi
            fi
            
            # Get existing image chart lines from images file
            # Use word boundary or end-of-pattern matching to avoid matching similar addon names (e.g., oceanbase vs oceanbase-proxy)
            mapfile -t existing_lines < <(grep "docker.io/apecloud/apecloud-addon-charts:${addon_name}-[0-9]" "$images_file" || true)
            
            # Build arrays of existing and manifest versions for comparison
            local existing_versions=()
            for line in "${existing_lines[@]}"; do
                if [[ -n "$line" ]]; then
                    # Extract version from line like docker.io/apecloud/apecloud-addon-charts:addon_name-version
                    local ver="${line#*${addon_name}-}"
                    ver="${ver%% *}"  # Remove any trailing spaces
                    existing_versions+=("$ver")
                fi
            done
            
            # Find versions to add (in manifest but not in existing)
            local versions_to_add=()
            for manifest_ver in "${manifest_versions[@]}"; do
                local found=0
                for existing_ver in "${existing_versions[@]}"; do
                    if [[ "$manifest_ver" == "$existing_ver" ]]; then
                        found=1
                        break
                    fi
                done
                if [[ $found -eq 0 ]]; then
                    versions_to_add+=("$manifest_ver")
                fi
            done
            
            # Find versions to remove (in existing but not in manifest)
            local versions_to_remove=()
            for existing_ver in "${existing_versions[@]}"; do
                local found=0
                for manifest_ver in "${manifest_versions[@]}"; do
                    if [[ "$existing_ver" == "$manifest_ver" ]]; then
                        found=1
                        break
                    fi
                done
                if [[ $found -eq 0 ]]; then
                    versions_to_remove+=("$existing_ver")
                fi
            done
            
            # Update existing image chart versions (match by position) - only update positions that exist in both arrays
            local existing_count=${#existing_lines[@]}
            local manifest_count=${#manifest_versions[@]}
            local min_count=$((existing_count < manifest_count ? existing_count : manifest_count))
            
            for ((idx=0; idx<min_count; idx++)); do
                local manifest_ver="${manifest_versions[$idx]}"
                local existing_line="${existing_lines[$idx]}"
                local existing_ver="${existing_line#*${addon_name}-}"
                existing_ver="${existing_ver%% *}"  # Extract version
                
                if [[ "$manifest_ver" != "$existing_ver" ]]; then
                    echo "    Updating ${existing_line} -> docker.io/apecloud/apecloud-addon-charts:${addon_name}-${manifest_ver}"
                    # Use fixed string replacement instead of regex to avoid escaping issues
                    if [[ "$UNAME" == "Darwin" ]]; then
                        local tmp_images=$(mktemp)
                        awk -v old="$existing_line" -v new="docker.io/apecloud/apecloud-addon-charts:${addon_name}-${manifest_ver}" '{if ($0 == old) print new; else print}' "$images_file" > "$tmp_images"
                        mv "$tmp_images" "$images_file"
                    else
                        local tmp_images=$(mktemp)
                        awk -v old="$existing_line" -v new="docker.io/apecloud/apecloud-addon-charts:${addon_name}-${manifest_ver}" '{if ($0 == old) print new; else print}' "$images_file" > "$tmp_images"
                        mv "$tmp_images" "$images_file"
                    fi
                fi
            done
            
            # Add new image chart versions (only if manifest has more versions than existing)
            if [[ $manifest_count -gt $existing_count ]]; then
                for ver in "${versions_to_add[@]}"; do
                    echo "    Adding docker.io/apecloud/apecloud-addon-charts:${addon_name}-${ver}"
                    
                    # Find the insertion point: before the first comment line that's not a version comment at the beginning
                    # We want to insert before lines like "# casdoor", "# KubeBlocks", etc.
                    local insert_line=""
                    
                    # Find all comment lines
                    while IFS=: read -r line_num line_content; do
                        # Skip comments at the very beginning of file (lines 1-5)
                        if [[ $line_num -le 5 ]]; then
                            continue
                        fi
                        # This is a good insertion point (before this comment)
                        insert_line=$((line_num - 1))
                        break
                    done < <(grep -n "^# " "$images_file")
                    
                    if [[ -z "$insert_line" ]]; then
                        # If no suitable comment found, append to end
                        echo "docker.io/apecloud/apecloud-addon-charts:${addon_name}-${ver}" >> "$images_file"
                    else
                        # Insert before the comment line
                        local tmp_images=$(mktemp)
                        head -n "$insert_line" "$images_file" > "$tmp_images"
                        echo "docker.io/apecloud/apecloud-addon-charts:${addon_name}-${ver}" >> "$tmp_images"
                        tail -n +$((insert_line + 1)) "$images_file" >> "$tmp_images"
                        mv "$tmp_images" "$images_file"
                    fi
                done
            fi
            
            # Remove obsolete image chart versions (only if existing has more versions than manifest)
            if [[ $existing_count -gt $manifest_count ]]; then
                for ver in "${versions_to_remove[@]}"; do
                    echo "    Removing docker.io/apecloud/apecloud-addon-charts:${addon_name}-${ver}"
                    if [[ "$UNAME" == "Darwin" ]]; then
                        sed -i '' "/docker.io\/apecloud\/apecloud-addon-charts:${addon_name}-${ver}/d" "$images_file"
                    else
                        sed -i "/docker.io\/apecloud\/apecloud-addon-charts:${addon_name}-${ver}/d" "$images_file"
                    fi
                done
            fi
        done
    done
    
    echo "$(tput -T xterm setaf 2)Addon image chart versions updated successfully$(tput -T xterm sgr0)"
}

update_kubeblocks_enterprise_sections_from_manifest() {
    local enterprise_txt=".github/images/kubeblocks-enterprise.txt"
    
    if [[ ! -f "$enterprise_txt" ]]; then
        echo "  WARNING: kubeblocks-enterprise.txt not found, skipping"
        return
    fi
    
    echo "$(tput -T xterm setaf 3)Checking and updating kubeblocks-enterprise.txt target sections$(tput -T xterm sgr0)"
    
    # Define the 5 target sections and their corresponding charts in manifests
    declare -A section_charts
    section_charts=(
        ["KubeBlocks-Cloud"]="kubeblocks-cloud kb-cloud-installer"
        ["KubeBlocks v"]="kubeblocks"
        ["Gemini v"]="gemini gemini-monitor"
        ["Minio"]="minio"
        ["Loki"]="loki"
    )
    
    # Images to skip (as defined in airgap_charts_image_check.sh)
    local skip_images=(
        "apecloud/postgres-exporter:v0.13.2"
        "apecloud/kubeblocks-tools:1.0.0"
    )
    
    for section_keyword in "${!section_charts[@]}"; do
        echo "  Processing section: ${section_keyword}"
        
        # Find the line number where this section starts in txt file
        local section_start_line=0
        local line_num=0
        while IFS= read -r line; do
            line_num=$((line_num + 1))
            if [[ "$line" == \#*"${section_keyword}"* ]]; then
                section_start_line=$line_num
                break
            fi
        done < "$enterprise_txt"
        
        if [[ $section_start_line -eq 0 ]]; then
            echo "    WARNING: Section '${section_keyword}' not found in txt file"
            continue
        fi
        
        # Find the end of this section (next comment line or EOF)
        local section_end_line=0
        line_num=0
        while IFS= read -r line; do
            line_num=$((line_num + 1))
            if [[ $line_num -le $section_start_line ]]; then
                continue
            fi
            if [[ "$line" == \#* ]]; then
                section_end_line=$((line_num - 1))
                break
            fi
        done < "$enterprise_txt"
        
        # If no next comment found, section goes to end of file
        if [[ $section_end_line -eq 0 ]]; then
            section_end_line=$(wc -l < "$enterprise_txt")
        fi
        
        # Collect images from manifests for this section
        declare -A manifest_images_map
        local charts="${section_charts[$section_keyword]}"
        
        for chart in $charts; do
            # Extract target version from txt comment (e.g., "# KubeBlocks v1.0.3-beta.5")
            local target_version=""
            local ver_line=$(sed -n "${section_start_line}p" "$enterprise_txt")
            if [[ "$ver_line" == \#* ]]; then
                target_version=$(echo "$ver_line" | sed -n 's/.*[vV]\([0-9][^ ]*\).*/\1/p')
            fi
            
            # For charts with multiple versions (kubeblocks, minio, loki), filter by version
            if [[ -n "$target_version" && ("$chart" == "kubeblocks" || "$chart" == "minio" || "$chart" == "loki") ]]; then
                # Get all versions for this chart
                local all_versions=$(yq e '[.'${chart}'[].version] | .[]' ${MANIFESTS_FILE} 2>/dev/null)
                local matched_version=""
                for ver in $all_versions; do
                    local ver_clean=${ver#v}
                    local target_clean=${target_version#v}
                    if [[ "$ver_clean" == "$target_clean" ]]; then
                        matched_version="$ver"
                        break
                    fi
                done
                
                if [[ -n "$matched_version" ]]; then
                    # Only get images for matched version
                    local chart_images=$(yq e '.'${chart}'[] | select(.version == "'${matched_version}'") | .images[]' ${MANIFESTS_FILE} 2>/dev/null)
                    if [[ -n "$chart_images" ]]; then
                        while IFS= read -r img; do
                            if [[ -n "$img" ]]; then
                                # Remove docker.io/ prefix to match txt format
                                local normalized_img=$(echo "$img" | sed 's|^docker.io/||')
                                
                                # Skip images that are already handled by other update functions:
                                # 1. apecloud-addon-charts: handled by update_addon_image_chart_versions_from_manifest()
                                # 2. openconsole and other cloud components: handled by sed commands at the beginning
                                # 3. kubeblocks core images: handled by sed commands with KUBEBLOCKS_VERSIONS
                                # 4. gemini images: handled by sed commands with GEMINI_VERSION
                                # 5. Other specific images: handled by their respective version variables
                                case "$normalized_img" in
                                    apecloud/apecloud-addon-charts:*) continue ;;
                                    apecloud/openconsole:*) continue ;;
                                    apecloud/apiserver:*) continue ;;
                                    apecloud/task-manager:*) continue ;;
                                    apecloud/cubetran-front:*) continue ;;
                                    apecloud/cr4w:*) continue ;;
                                    apecloud/kubeblocks-console:*) continue ;;
                                    apecloud/relay:*) continue ;;
                                    apecloud/sentry:*) continue ;;
                                    apecloud/sentry-init:*) continue ;;
                                    apecloud/kb-cloud-installer:*) continue ;;
                                    apecloud/kb-cloud-hook:*) continue ;;
                                    apecloud/kb-cloud-docs:*) continue ;;
                                    apecloud/kubeblocks-dataprotection:*) continue ;;
                                    apecloud/kubeblocks-datascript:*) continue ;;
                                    apecloud/kubeblocks-tools:*) continue ;;
                                    apecloud/kubeblocks-charts:*) continue ;;
                                    apecloud/gemini-tools:*) continue ;;
                                    apecloud/easymetrics:*) continue ;;
                                    apecloud/sla:*) continue ;;
                                    apecloud/oteld:*) continue ;;
                                    apecloud/kubeblocks-installer:*) continue ;;
                                    apecloud/dms:*) continue ;;
                                    apecloud/apecloud-mcp:*) continue ;;
                                    apecloud/ob-grpc-server:*) continue ;;
                                    apecloud/ape-local:*) continue ;;
                                    apecloud/ape-dts:*) continue ;;
                                    apecloud/cubetran-platform:*) continue ;;
                                    apecloud/kubebench:*) continue ;;
                                esac
                                
                                # Check if image should be skipped
                                local should_skip=0
                                for skip_img in "${skip_images[@]}"; do
                                    if [[ "$normalized_img" == "$skip_img" ]]; then
                                        should_skip=1
                                        break
                                    fi
                                done
                                if [[ $should_skip -eq 0 ]]; then
                                    manifest_images_map["$normalized_img"]=1
                                fi
                            fi
                        done <<< "$chart_images"
                    fi
                else
                    echo "    WARNING: No matching version found for ${chart} in manifests (looking for ${target_version})"
                fi
            else
                # For charts without version filtering (kubeblocks-cloud, gemini, etc.), get all images
                local chart_images=$(yq e '.'${chart}'[].images[]' ${MANIFESTS_FILE} 2>/dev/null)
                if [[ -n "$chart_images" ]]; then
                    while IFS= read -r img; do
                        if [[ -n "$img" ]]; then
                            # Remove docker.io/ prefix to match txt format
                            local normalized_img=$(echo "$img" | sed 's|^docker.io/||')
                            
                            # Skip images that are already handled by other update functions (same list as above)
                            case "$normalized_img" in
                                apecloud/apecloud-addon-charts:*) continue ;;
                                apecloud/openconsole:*) continue ;;
                                apecloud/apiserver:*) continue ;;
                                apecloud/task-manager:*) continue ;;
                                apecloud/cubetran-front:*) continue ;;
                                apecloud/cr4w:*) continue ;;
                                apecloud/kubeblocks-console:*) continue ;;
                                apecloud/relay:*) continue ;;
                                apecloud/sentry:*) continue ;;
                                apecloud/sentry-init:*) continue ;;
                                apecloud/kb-cloud-installer:*) continue ;;
                                apecloud/kb-cloud-hook:*) continue ;;
                                apecloud/kb-cloud-docs:*) continue ;;
                                apecloud/kubeblocks-dataprotection:*) continue ;;
                                apecloud/kubeblocks-datascript:*) continue ;;
                                apecloud/kubeblocks-tools:*) continue ;;
                                apecloud/kubeblocks-charts:*) continue ;;
                                apecloud/gemini-tools:*) continue ;;
                                apecloud/easymetrics:*) continue ;;
                                apecloud/sla:*) continue ;;
                                apecloud/oteld:*) continue ;;
                                apecloud/kubeblocks-installer:*) continue ;;
                                apecloud/dms:*) continue ;;
                                apecloud/apecloud-mcp:*) continue ;;
                                apecloud/ob-grpc-server:*) continue ;;
                                apecloud/ape-local:*) continue ;;
                                apecloud/ape-dts:*) continue ;;
                                apecloud/cubetran-platform:*) continue ;;
                                apecloud/kubebench:*) continue ;;
                            esac
                            
                            # Check if image should be skipped
                            local should_skip=0
                            for skip_img in "${skip_images[@]}"; do
                                if [[ "$normalized_img" == "$skip_img" ]]; then
                                    should_skip=1
                                    break
                                fi
                            done
                            if [[ $should_skip -eq 0 ]]; then
                                manifest_images_map["$normalized_img"]=1
                            fi
                        fi
                    done <<< "$chart_images"
                fi
            fi
        done
        
        # Now check and fix issues one by one
        local fixed_count=0
        
        for manifest_image in "${!manifest_images_map[@]}"; do
            local manifest_img_name=$(echo "$manifest_image" | cut -d':' -f1)
            local manifest_img_tag=$(echo "$manifest_image" | rev | cut -d':' -f1 | rev)
            
            # Search for this image name in current section
            local found_in_section=0
            local line_to_update=0
            
            line_num=$section_start_line
            while IFS= read -r line; do
                line_num=$((line_num + 1))
                if [[ $line_num -gt $section_end_line ]]; then
                    break
                fi
                
                if [[ -n "$line" && "$line" != \#* ]]; then
                    # Normalize the line to match manifest format (remove docker.io/ prefix)
                    local normalized_line=$(echo "$line" | sed 's|^docker.io/||')
                    local existing_img_name=$(echo "$normalized_line" | cut -d':' -f1)
                    local existing_img_tag=$(echo "$normalized_line" | rev | cut -d':' -f1 | rev)
                    
                    # Special handling for images where tag distinguishes different components:
                    # 1. apecloud-addon-charts (tag contains addon name)
                    # 2. openconsole (multiple variants with different tags)
                    if [[ "$existing_img_name" == "apecloud/apecloud-addon-charts" || 
                          "$manifest_img_name" == "apecloud/apecloud-addon-charts" ||
                          "$existing_img_name" == "apecloud/openconsole" || 
                          "$manifest_img_name" == "apecloud/openconsole" ]]; then
                        # For these images, compare the entire image string
                        if [[ "$normalized_line" == "$manifest_image" ]]; then
                            found_in_section=1
                            # Exact match, no update needed
                            break
                        fi
                    elif [[ "$existing_img_name" == "$manifest_img_name" ]]; then
                        # For other images, compare by name and check tag
                        found_in_section=1
                        # Check if tag needs update
                        if [[ "$existing_img_tag" != "$manifest_img_tag" ]]; then
                            # Fix: update tag in-place, keep original format (with or without docker.io/)
                            if [[ "$UNAME" == "Darwin" ]]; then
                                sed -i '' "${line_num}s|^.*$|${line%%:*}:${manifest_img_tag}|" "$enterprise_txt"
                            else
                                sed -i "${line_num}s|^.*$|${line%%:*}:${manifest_img_tag}|" "$enterprise_txt"
                            fi
                            echo "    Fixed tag: ${line} -> ${line%%:*}:${manifest_img_tag}"
                            fixed_count=$((fixed_count + 1))
                        fi
                        break
                    fi
                fi
            done < <(sed -n "$((section_start_line + 1)),${section_end_line}p" "$enterprise_txt")
            
            # If not found, add to end of section
            if [[ $found_in_section -eq 0 ]]; then
                # Ensure docker.io/ prefix is present
                local img_to_add="$manifest_image"
                if [[ "$manifest_image" != docker.io/* ]]; then
                    img_to_add="docker.io/$manifest_image"
                fi
                
                # Use a temporary file approach for more reliable line insertion
                local tmp_file=$(mktemp)
                local current_line=0
                while IFS= read -r txt_line; do
                    current_line=$((current_line + 1))
                    echo "$txt_line" >> "$tmp_file"
                    # After writing the section_end_line, add the new image
                    if [[ $current_line -eq $section_end_line ]]; then
                        echo "$img_to_add" >> "$tmp_file"
                    fi
                done < "$enterprise_txt"
                mv "$tmp_file" "$enterprise_txt"
                
                echo "    Added missing: ${img_to_add}"
                fixed_count=$((fixed_count + 1))
                section_end_line=$((section_end_line + 1))
            fi
        done
        
        if [[ $fixed_count -eq 0 ]]; then
            echo "    No changes needed"
        else
            echo "    Fixed ${fixed_count} issue(s)"
        fi
        
        unset manifest_images_map
    done
    
    echo "$(tput -T xterm setaf 2)kubeblocks-enterprise.txt target sections updated successfully$(tput -T xterm sgr0)"
}

main() {
    local UNAME=`uname -s`
    local APP_VERSION=${APP_VERSION_TMP}
    local KUBEBLOCKS_VERSIONS="${KUBEBLOCKS_VERSION_TMP}"
    local GEMINI_VERSION="${GEMINI_VERSION_TMP}"
    local OTELD_VERSION="${OTELD_VERSION_TMP?}"
    local OFFLINE_INSTALLER_VERSION="${OFFLINE_INSTALLER_VERSION_TMP}"
    local DMS_VERSION="${DMS_VERSION_TMP}"
    local APECLOUD_MCP_VERSION="${APECLOUD_MCP_VERSION_TMP}"
    local OB_GRPC_SERVER_VERSION=""
    local MANIFESTS_FILE="apecloud/manifests/deploy-manifests.yaml"
    local APE_LOCAL_CSI_DRIVER_VERSION=""
    local CLOUD_APE_DTS_VERSION=""
    local GEMINI_APE_DTS_VERSION=""
    local CUBETRAN_PLATFORM_VERSION=""
    local KUBEBENCH_VERSION=""
    local APECLOUD_MCP_VERSION=""
    local CASDOOR_VERSION=""

    check_manifests_version

    # Update addon images from deploy-manifests.yaml
    if [[ -f "${MANIFESTS_FILE}" ]]; then
        echo "$(tput -T xterm setaf 3)Updating addon images from manifest$(tput -T xterm sgr0)"
        # Dynamically extract all engine addons from manifest
        mapfile -t engine_addons < <(yq e 'with_entries(select(.value[0].type == "engine" and .value[0].isAddon == true)) | keys | .[]' "${MANIFESTS_FILE}" 2>/dev/null || true)

        for addon_name in "${engine_addons[@]}"; do
            update_addon_images_from_manifest "$addon_name"
        done

        # Update addon chart versions in kubeblocks-enterprise.txt
        update_addon_chart_versions_from_manifest

        # Update addon image chart versions in kubeblocks-enterprise.txt and kubeblocks-cloud.txt
        update_addon_image_chart_versions_from_manifest
        
        # Update kubeblocks-enterprise.txt target sections (5 key sections)
        update_kubeblocks_enterprise_sections_from_manifest
    fi

    add_images_list

    save_images_package
}

main "$@"
