#!/bin/bash

set -eu


show_help() {
cat << EOF
Usage: $(basename "$0") <options>

    -h, --help                    Display help
    -t, --type                    Operation type
                                    1) upgrade version
                                    2) generate release note
    -cv, --cloud-version          KubeBlocks Cloud Version
    -kv, --kubeblocks-version     KubeBlocks Version
    -gv, --gemini-version         Gemini Version
    -ov, --oteld-version          Oteld Version
    -iv, --installer-version      Offline Installer Version
    -dv, --dms-version            Dms Version
    -mf, --manifests-file         Cloud Manifests File Path
EOF
}

parse_command_line() {
    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
                ;;
            -t|--type)
                if [[ -n "${2:-}" ]]; then
                    TYPE="$2"
                    shift
                fi
                ;;
            -cv|--cloud-version)
                if [[ -n "${2:-}" ]]; then
                    CLOUD_VERSION="$2"
                    shift
                fi
                ;;
            -kv|--kubeblocks-version)
                if [[ -n "${2:-}" ]]; then
                    KUBEBLOCKS_VERSIONS="$2"
                    shift
                fi
                ;;
            -gv|--gemini-version)
                if [[ -n "${2:-}" ]]; then
                    GEMINI_VERSION="$2"
                    shift
                fi
                ;;
            -ov|--oteld-version)
                if [[ -n "${2:-}" ]]; then
                    OTELD_VERSION="$2"
                    shift
                fi
                ;;
            -iv|--installer-version)
                if [[ -n "${2:-}" ]]; then
                    OFFLINE_INSTALLER_VERSION="$2"
                    shift
                fi
                ;;
            -dv|--dms-version)
                if [[ -n "${2:-}" ]]; then
                    DMS_VERSION="$2"
                    shift
                fi
                ;;
            -mf|--manifests-file)
                if [[ -n "${2:-}" ]]; then
                    MANIFESTS_FILE="$2"
                    shift
                fi
                ;;
            *)
                break
                ;;
        esac

        shift
    done
}

change_cloud_version() {
    echo "$(tput -T xterm setaf 3)change kubeblocks-cloud image version:${CLOUD_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("kubeblocks-cloud.txt" "kubeblocks-enterprise.txt" "kubeblocks-enterprise-patch.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        HEAD_CLOUD_VERSION="${CLOUD_VERSION%%.*}"
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^# kubeblocks-enterprise .*/# kubeblocks-enterprise ${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^# kubeblocks-enterprise-patch .*/# kubeblocks-enterprise-patch ${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^# KubeBlocks-Cloud .*/# KubeBlocks-Cloud ${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/openconsole:.*[0-9]/docker.io\/apecloud\/openconsole:${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/apiserver:.*/docker.io\/apecloud\/apiserver:${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/task-manager:.*/docker.io\/apecloud\/task-manager:${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/cubetran-front:.*/docker.io\/apecloud\/cubetran-front:${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/cr4w:.*/docker.io\/apecloud\/cr4w:${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/relay:.*/docker.io\/apecloud\/relay:${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/sentry:.*/docker.io\/apecloud\/sentry:${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/sentry-init:.*/docker.io\/apecloud\/sentry-init:${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/kb-cloud-installer:.*/docker.io\/apecloud\/kb-cloud-installer:${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/kb-cloud-hook:.*/docker.io\/apecloud\/kb-cloud-hook:${CLOUD_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/kb-cloud-docs:.*/docker.io\/apecloud\/kb-cloud-docs:${CLOUD_VERSION}/" $image_file_path
        else
            sed -i "s/^# kubeblocks-enterprise .*/# kubeblocks-enterprise ${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^# kubeblocks-enterprise-patch .*/# kubeblocks-enterprise-patch ${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^# KubeBlocks-Cloud .*/# KubeBlocks-Cloud ${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/openconsole:.*[0-9]/docker.io\/apecloud\/openconsole:${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/apiserver:.*/docker.io\/apecloud\/apiserver:${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/task-manager:.*/docker.io\/apecloud\/task-manager:${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/cubetran-front:.*/docker.io\/apecloud\/cubetran-front:${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/cr4w:.*/docker.io\/apecloud\/cr4w:${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/relay:.*/docker.io\/apecloud\/relay:${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/sentry:.*/docker.io\/apecloud\/sentry:${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/sentry-init:.*/docker.io\/apecloud\/sentry-init:${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/kb-cloud-installer:.*/docker.io\/apecloud\/kb-cloud-installer:${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/kb-cloud-hook:.*/docker.io\/apecloud\/kb-cloud-hook:${CLOUD_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/kb-cloud-docs:.*/docker.io\/apecloud\/kb-cloud-docs:${CLOUD_VERSION}/" $image_file_path
        fi
    done
    echo "$(tput -T xterm setaf 3)change kubeblocks-cloud chart version:${CLOUD_VERSION}$(tput -T xterm sgr0)"
    chartFiles=("kubeblocks-cloud.txt" "kubeblocks-enterprise.txt")
    for chartFile in "${chartFiles[@]}"; do
        echo "change ${chartFile} chart version"
        chart_file_path=.github/charts/${chartFile}
        CLOUD_VERSION_TEMP=${CLOUD_VERSION}
        if [[ "${CLOUD_VERSION}" == "v"* ]]; then
            CLOUD_VERSION_TEMP="${CLOUD_VERSION/v/}"
        fi
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^kubeblocks-cloud:.*/kubeblocks-cloud:${CLOUD_VERSION}/" $chart_file_path
            sed -i '' "s/^kb-cloud-installer:.*/kb-cloud-installer:${CLOUD_VERSION_TEMP}/" $chart_file_path
        else
            sed -i "s/^kubeblocks-cloud:.*/kubeblocks-cloud:${CLOUD_VERSION}/" $chart_file_path
            sed -i "s/^kb-cloud-installer:.*/kb-cloud-installer:${CLOUD_VERSION_TEMP}/" $chart_file_path
        fi
    done
}

change_kubeblocks_versions() {
    echo "$(tput -T xterm setaf 3)change kubeblocks image version:${KUBEBLOCKS_VERSIONS}$(tput -T xterm sgr0)"
    for KUBEBLOCKS_VERSION in $(echo "${KUBEBLOCKS_VERSIONS}" | sed 's/|/ /g'); do
        IFS='.' read -r major_v minor_v rest_v <<< "${KUBEBLOCKS_VERSION}"
        KUBEBLOCKS_VERSION_HEAD="$major_v.$minor_v."

        imageFiles=("kubeblocks.txt" "kubeblocks-enterprise.txt" "kubeblocks-enterprise-patch.txt" "gemini.txt")
        for imageFile in "${imageFiles[@]}"; do
            echo "change ${imageFile} images tag"
            image_file_path=.github/images/${imageFile}
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "s/^# KubeBlocks v${KUBEBLOCKS_VERSION_HEAD}.*/# KubeBlocks v${KUBEBLOCKS_VERSION}/" $image_file_path
                sed -i '' "s/^docker.io\/apecloud\/kubeblocks:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks:${KUBEBLOCKS_VERSION}/" $image_file_path
                sed -i '' "s/^docker.io\/apecloud\/kubeblocks-dataprotection:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-dataprotection:${KUBEBLOCKS_VERSION}/" $image_file_path
                sed -i '' "s/^docker.io\/apecloud\/kubeblocks-datascript:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-datascript:${KUBEBLOCKS_VERSION}/" $image_file_path
                sed -i '' "s/^docker.io\/apecloud\/kubeblocks-tools:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-tools:${KUBEBLOCKS_VERSION}/" $image_file_path
                sed -i '' "s/^docker.io\/apecloud\/kubeblocks-charts:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-charts:${KUBEBLOCKS_VERSION}/" $image_file_path
            else
                sed -i "s/^# KubeBlocks v${KUBEBLOCKS_VERSION_HEAD}.*/# KubeBlocks v${KUBEBLOCKS_VERSION}/" $image_file_path
                sed -i "s/^docker.io\/apecloud\/kubeblocks:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks:${KUBEBLOCKS_VERSION}/" $image_file_path
                sed -i "s/^docker.io\/apecloud\/kubeblocks-dataprotection:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-dataprotection:${KUBEBLOCKS_VERSION}/" $image_file_path
                sed -i "s/^docker.io\/apecloud\/kubeblocks-datascript:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-datascript:${KUBEBLOCKS_VERSION}/" $image_file_path
                sed -i "s/^docker.io\/apecloud\/kubeblocks-tools:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-tools:${KUBEBLOCKS_VERSION}/" $image_file_path
                sed -i "s/^docker.io\/apecloud\/kubeblocks-charts:${KUBEBLOCKS_VERSION_HEAD}.*/docker.io\/apecloud\/kubeblocks-charts:${KUBEBLOCKS_VERSION}/" $image_file_path
            fi
        done

        echo "$(tput -T xterm setaf 3)change kubeblocks chart version:${KUBEBLOCKS_VERSION}$(tput -T xterm sgr0)"
        chartFiles=("kubeblocks.txt" "kubeblocks-enterprise.txt")
        for chartFile in "${chartFiles[@]}"; do
            echo "change ${chartFile} chart version"
            chart_file_path=.github/charts/${chartFile}
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "s/^kubeblocks:${KUBEBLOCKS_VERSION_HEAD}.*/kubeblocks:${KUBEBLOCKS_VERSION}/" $chart_file_path
            else
                sed -i "s/^kubeblocks:${KUBEBLOCKS_VERSION_HEAD}.*/kubeblocks:${KUBEBLOCKS_VERSION}/" $chart_file_path
            fi
        done
    done
}

change_gemini_version() {
    echo "$(tput -T xterm setaf 3)change gemini image version:${GEMINI_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("gemini.txt" "kubeblocks-enterprise.txt" "kubeblocks-enterprise-patch.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^# Gemini .*/# Gemini v${GEMINI_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/gemini:.*/docker.io\/apecloud\/gemini:${GEMINI_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/gemini-tools:.*/docker.io\/apecloud\/gemini-tools:${GEMINI_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/easymetrics:.*/docker.io\/apecloud\/easymetrics:${GEMINI_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/sla:.*/docker.io\/apecloud\/sla:${GEMINI_VERSION}/" $image_file_path
        else
            sed -i "s/^# Gemini .*/# Gemini v${GEMINI_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/gemini:.*/docker.io\/apecloud\/gemini:${GEMINI_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/gemini-tools:.*/docker.io\/apecloud\/gemini-tools:${GEMINI_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/easymetrics:.*/docker.io\/apecloud\/easymetrics:${GEMINI_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/sla:.*/docker.io\/apecloud\/sla:${GEMINI_VERSION}/" $image_file_path
        fi
    done

    echo "$(tput -T xterm setaf 3)change gemini chart version:${GEMINI_VERSION}$(tput -T xterm sgr0)"
    chartFiles=("gemini.txt" "kubeblocks-enterprise.txt")
    for chartFile in "${chartFiles[@]}"; do
        echo "change ${chartFile} chart version"
        chart_file_path=.github/charts/${chartFile}
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^gemini:.*/gemini:${GEMINI_VERSION}/" $chart_file_path
            sed -i '' "s/^gemini-monitor:.*/gemini-monitor:${GEMINI_VERSION}/" $chart_file_path
        else
            sed -i "s/^gemini:.*/gemini:${GEMINI_VERSION}/" $chart_file_path
            sed -i "s/^gemini-monitor:.*/gemini-monitor:${GEMINI_VERSION}/" $chart_file_path
        fi
    done
}

change_oteld_version() {
    echo "$(tput -T xterm setaf 3)change oteld image version:${OTELD_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("gemini.txt" "kubeblocks-enterprise.txt" "kubeblocks-enterprise-patch.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/oteld:0.5.2-k8s21/#docker.io\/apecloud\/oteld:0.5.2-k8s21/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/oteld:.*/docker.io\/apecloud\/oteld:${OTELD_VERSION}/" $image_file_path
            sed -i '' "s/^#docker.io\/apecloud\/oteld:0.5.2-k8s21/docker.io\/apecloud\/oteld:0.5.2-k8s21/" $image_file_path
        else
            sed -i "s/^docker.io\/apecloud\/oteld:0.5.2-k8s21/#docker.io\/apecloud\/oteld:0.5.2-k8s21/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/oteld:.*/docker.io\/apecloud\/oteld:${OTELD_VERSION}/" $image_file_path
            sed -i "s/^#docker.io\/apecloud\/oteld:0.5.2-k8s21/docker.io\/apecloud\/oteld:0.5.2-k8s21/" $image_file_path
        fi
    done
}

change_offline_installer_version() {
    echo "$(tput -T xterm setaf 3)change offline installer image version:${OFFLINE_INSTALLER_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("kubeblocks-cloud.txt" "kubeblocks-enterprise.txt" "kubeblocks-enterprise-patch.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/kubeblocks-installer:.*/docker.io\/apecloud\/kubeblocks-installer:${OFFLINE_INSTALLER_VERSION}/" $image_file_path
        else
            sed -i "s/^docker.io\/apecloud\/kubeblocks-installer:.*/docker.io\/apecloud\/kubeblocks-installer:${OFFLINE_INSTALLER_VERSION}/" $image_file_path
        fi
    done
}

change_dms_version() {
    echo "$(tput -T xterm setaf 3)change dms image version:${DMS_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("kubeblocks-cloud.txt" "kubeblocks-enterprise.txt" "kubeblocks-enterprise-patch.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/dms:.*/docker.io\/apecloud\/dms:${DMS_VERSION}/" $image_file_path
        else
            sed -i "s/^docker.io\/apecloud\/dms:.*/docker.io\/apecloud\/dms:${DMS_VERSION}/" $image_file_path
        fi
    done
}

change_ape_local_csi_drive_version() {
    echo "$(tput -T xterm setaf 3)change ape-local-csi-driver image version:${APE_LOCAL_CSI_DRIVER_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("ape-local-csi-driver.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^# ape-local-csi-driver .*/# ape-local-csi-driver v${APE_LOCAL_CSI_DRIVER_VERSION}/" $image_file_path
            sed -i '' "s/^docker.io\/apecloud\/ape-local:.*/docker.io\/apecloud\/ape-local:${APE_LOCAL_CSI_DRIVER_VERSION}/" $image_file_path
        else
            sed -i "s/^# ape-local-csi-driver .*/# ape-local-csi-driver v${APE_LOCAL_CSI_DRIVER_VERSION}/" $image_file_path
            sed -i "s/^docker.io\/apecloud\/ape-local:.*/docker.io\/apecloud\/ape-local:${APE_LOCAL_CSI_DRIVER_VERSION}/" $image_file_path
        fi
    done

    echo "$(tput -T xterm setaf 3)change ape-local-csi-driver chart version:${APE_LOCAL_CSI_DRIVER_VERSION}$(tput -T xterm sgr0)"
    chartFiles=("kubeblocks-enterprise.txt")
    for chartFile in "${chartFiles[@]}"; do
        echo "change ${chartFile} chart version"
        chart_file_path=.github/charts/${chartFile}
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^ape-local-csi-driver:.*/ape-local-csi-driver:${APE_LOCAL_CSI_DRIVER_VERSION}/" $chart_file_path
        else
            sed -i "s/^ape-local-csi-driver:.*/ape-local-csi-driver:${APE_LOCAL_CSI_DRIVER_VERSION}/" $chart_file_path
        fi
    done
}

change_cloud_ape_dts_version() {
    echo "$(tput -T xterm setaf 3)change cloud ape-dts image version:${CLOUD_APE_DTS_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("kubeblocks-cloud.txt" "kubeblocks-enterprise.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        if [[ "${imageFile}" == "kubeblocks-enterprise.txt" ]]; then
            cloud_line=$(grep -n "apecloud/ape-dts" $image_file_path | head -1 | cut -d: -f1)
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "${cloud_line}s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${CLOUD_APE_DTS_VERSION}/" $image_file_path
            else
                sed -i "${cloud_line}s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${CLOUD_APE_DTS_VERSION}/" $image_file_path
            fi
        else
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${CLOUD_APE_DTS_VERSION}/" $image_file_path
            else
                sed -i "s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${CLOUD_APE_DTS_VERSION}/" $image_file_path
            fi
        fi
    done
}

change_gemini_ape_dts_version() {
    echo "$(tput -T xterm setaf 3)change gemini ape-dts image version:${GEMINI_APE_DTS_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("gemini.txt" "kubeblocks-enterprise.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        if [[ "${imageFile}" == "kubeblocks-enterprise.txt" ]]; then
            gemini_line=$(grep -n "apecloud/ape-dts" $image_file_path | sed -n '2p' | cut -d: -f1)
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "${gemini_line}s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${GEMINI_APE_DTS_VERSION}/" $image_file_path
            else
                sed -i "${gemini_line}s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${GEMINI_APE_DTS_VERSION}/" $image_file_path
            fi
        else
            if [[ "$UNAME" == "Darwin" ]]; then
                sed -i '' "s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${GEMINI_APE_DTS_VERSION}/" $image_file_path
            else
                sed -i "s/^docker.io\/apecloud\/ape-dts:.*/docker.io\/apecloud\/ape-dts:${GEMINI_APE_DTS_VERSION}/" $image_file_path
            fi
        fi
    done
}

change_cubetran_platform_version() {
    echo "$(tput -T xterm setaf 3)change cubetran-platform image version:${CUBETRAN_PLATFORM_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("gemini.txt" "kubeblocks-enterprise.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/cubetran-platform:.*/docker.io\/apecloud\/cubetran-platform:${CUBETRAN_PLATFORM_VERSION}/" $image_file_path
        else
            sed -i "s/^docker.io\/apecloud\/cubetran-platform:.*/docker.io\/apecloud\/cubetran-platform:${CUBETRAN_PLATFORM_VERSION}/" $image_file_path
        fi
    done
}

change_kubebench_version() {
    echo "$(tput -T xterm setaf 3)change kubebench image version:${KUBEBENCH_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("kubebench.txt" "kubeblocks-enterprise.txt" "kubeblocks-cloud.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/kubebench:.*/docker.io\/apecloud\/kubebench:${KUBEBENCH_VERSION}/" $image_file_path
        else
            sed -i "s/^docker.io\/apecloud\/kubebench:.*/docker.io\/apecloud\/kubebench:${KUBEBENCH_VERSION}/" $image_file_path
        fi
    done
}

change_servicemirror_version() {
    echo "$(tput -T xterm setaf 3)change servicemirror image version:${SERVICEMIRROR_VERSION}$(tput -T xterm sgr0)"
    imageFiles=("kubeblocks-enterprise.txt" "kubeblocks-cloud.txt")
    for imageFile in "${imageFiles[@]}"; do
        echo "change ${imageFile} images tag"
        image_file_path=.github/images/${imageFile}
        if [[ "$UNAME" == "Darwin" ]]; then
            sed -i '' "s/^docker.io\/apecloud\/servicemirror:0.4.*/docker.io\/apecloud\/servicemirror:${SERVICEMIRROR_VERSION}/" $image_file_path
        else
            sed -i "s/^docker.io\/apecloud\/servicemirror:0.4.*/docker.io\/apecloud\/servicemirror:${SERVICEMIRROR_VERSION}/" $image_file_path
        fi
    done
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
content = content.rstrip('\\n') + '\\n'
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
    
    # Debug: Show file state before deduplication
    echo "  DEBUG: File state before deduplication:"
    grep -E "^(mssql|loki):" "$charts_file" | cat -n
    
    # First, deduplicate the entire file to start with a clean state
    echo "  DEBUG: Deduplicating charts file before processing..."
    local lines_before=$(wc -l < "$charts_file")
    local tmp_dedup=$(mktemp)
    awk '!seen[$0]++' "$charts_file" > "$tmp_dedup"
    mv "$tmp_dedup" "$charts_file"
    local lines_after=$(wc -l < "$charts_file")
    echo "  DEBUG: Deduplication complete: ${lines_before} -> ${lines_after} lines"
    
    # Debug: Show file state after deduplication
    echo "  DEBUG: File state after deduplication:"
    grep -E "^(mssql|loki):" "$charts_file" | cat -n
    
    # List of engine addons to sync
    local engine_addons=(
        "clickhouse" "elasticsearch" "kafka" "mongodb" "mysql" "greatdb"
        "oceanbase" "postgresql" "qdrant" "rabbitmq" "redis" "starrocks"
        "zookeeper" "damengdb" "kingbase" "tidb" "vastbase" "minio"
        "victoria-metrics" "gaussdb" "loki" "mssql" "oceanbase-proxy"
        "pulsar" "rocketmq" "goldendb" "tdsql" "influxdb" "etcd"
        "milvus" "nebula" "tdengine" "oracle" "doris" "hadoop"
        "hive" "nacos" "camellia-redis-proxy"
    )
    
    for addon_name in "${engine_addons[@]}"; do
        # Get versions from manifest
        mapfile -t manifest_versions < <(yq e ".${addon_name}[].version" ${MANIFESTS_FILE} 2>/dev/null || true)
        
        if [[ ${#manifest_versions[@]} -eq 0 ]]; then
            # No versions in manifest, skip
            continue
        fi
        
        echo "  Processing ${addon_name}: ${#manifest_versions[@]} version(s) in manifest"
        
        # Get existing versions from charts file
        mapfile -t existing_lines < <(grep "^${addon_name}:" "$charts_file" || true)
        
        echo "    DEBUG: Found ${#existing_lines[@]} existing line(s): ${existing_lines[*]}"
        
        # Build arrays of existing and manifest versions for comparison
        local existing_versions=()
        for line in "${existing_lines[@]}"; do
            if [[ -n "$line" ]]; then
                local ver="${line#*:}"
                existing_versions+=("$ver")
            fi
        done
        
        echo "    DEBUG: Existing versions: ${existing_versions[*]}"
        echo "    DEBUG: Manifest versions: ${manifest_versions[*]}"
        
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
                echo "    DEBUG: Will add ${addon_name}:${manifest_ver} (not found in existing: ${existing_versions[*]})"
                versions_to_add+=("$manifest_ver")
            else
                echo "    DEBUG: ${addon_name}:${manifest_ver} already exists, skip adding"
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
            echo "    DEBUG: versions_to_add count: ${#versions_to_add[@]}, content: ${versions_to_add[*]}"
            for ver in "${versions_to_add[@]}"; do
                echo "    Adding ${addon_name}:${ver}"
                echo "${addon_name}:${ver}" >> "$charts_file"
            done
        else
            echo "    DEBUG: No new versions to add (manifest_count=$manifest_count, existing_count=$existing_count)"
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
    
    # List of engine addons to sync
    local engine_addons=(
        "clickhouse" "elasticsearch" "kafka" "mongodb" "mysql" "greatdb"
        "oceanbase" "postgresql" "qdrant" "rabbitmq" "redis" "starrocks"
        "zookeeper" "damengdb" "kingbase" "tidb" "vastbase" "minio"
        "victoria-metrics" "gaussdb" "loki" "mssql" "oceanbase-proxy"
        "pulsar" "rocketmq" "goldendb" "tdsql" "influxdb" "etcd"
        "milvus" "nebula" "tdengine" "oracle" "doris" "hadoop"
        "hive" "nacos" "camellia-redis-proxy"
    )
    
    for images_file in "${images_files[@]}"; do
        if [[ ! -f "$images_file" ]]; then
            echo "  WARNING: Images file not found: $images_file, skipping"
            continue
        fi
        
        echo "  Processing file: $images_file"
        
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

generate_release_note() {
    release_note_file="./docs/release-notes/${CLOUD_VERSION}.md"
    kubeblocks_enterprise_txt="./.github/images/kubeblocks-enterprise.txt"
    cp -r "$kubeblocks_enterprise_txt" "$release_note_file"
    
    # add apps images to release note
    imageFiles=("ape-local-csi-driver" "kubebench")
    for imageFile in "${imageFiles[@]}"; do
        echo "add ${imageFile} to release note "
        image_file_path=.github/images/${imageFile}.txt
        if [[ -f "${image_file_path}" ]]; then
            cat ${image_file_path} >> "$release_note_file"
        fi
    done

    # add addons images to release note
    imageFiles=("clickhouse" "damengdb-arm" "elasticsearch" "etcd" "gaussdb" "goldendb" "influxdb" "kafka" "kingbase" "loki" "milvus" "minio" "mongodb" "mssql" "mysql" "nebula" "oceanbase" "oceanbase-proxy" "oracle" "postgresql" "qdrant" "rabbitmq" "redis" "rocketmq" "starrocks" "tdengine" "tdsql" "tidb" "vastbase" "victoria-metrics" "zookeeper" "doris" "hadoop" "hive", "nacos")
    for imageFile in "${imageFiles[@]}"; do
        echo "add ${imageFile} to release note "
        image_file_path=.github/images/0.9/${imageFile}.txt
        if [[ -f "${image_file_path}" ]]; then
            cat ${image_file_path} >> "$release_note_file"
        fi

        if [[ "${imageFile}" == "oceanbase" ]]; then
            imageFile="oceanbase-arm"
        fi
        image_file_path=.github/images/1.0/${imageFile}.txt
        if [[ -f "${image_file_path}" ]]; then
            cat ${image_file_path} >> "$release_note_file"
        fi
    done
    git add "$release_note_file"
}

main() {
    local TYPE=""
    local UNAME=`uname -s`
    local CLOUD_VERSION=""
    local KUBEBLOCKS_VERSIONS=""
    local GEMINI_VERSION=""
    local OTELD_VERSION=""
    local OFFLINE_INSTALLER_VERSION=""
    local DMS_VERSION=""
    local MANIFESTS_FILE=""
    local APE_LOCAL_CSI_DRIVER_VERSION=""
    local CLOUD_APE_DTS_VERSION=""
    local GEMINI_APE_DTS_VERSION=""
    local CUBETRAN_PLATFORM_VERSION=""
    local KUBEBENCH_VERSION=""
    local SERVICEMIRROR_VERSION=""

    parse_command_line "$@"

    echo "CLOUD_VERSION:"${CLOUD_VERSION}
    echo "KUBEBLOCKS_VERSIONS:"${KUBEBLOCKS_VERSIONS}
    echo "GEMINI_VERSION:"${GEMINI_VERSION}
    echo "OTELD_VERSION:"${OTELD_VERSION}
    echo "OFFLINE_INSTALLER_VERSION:"${OFFLINE_INSTALLER_VERSION}
    echo "DMS_VERSION:"${DMS_VERSION}

    case $TYPE in
        1)
            if [[ -n "$MANIFESTS_FILE" && -f "${MANIFESTS_FILE}" ]]; then
                CLOUD_VERSION=$(yq e ".kubeblocks-cloud[0].version"  ${MANIFESTS_FILE})
                KUBEBLOCKS_VERSIONS=$(yq e '[.kubeblocks[].version] | join("|")' ${MANIFESTS_FILE})
                GEMINI_VERSION=$(yq e ".gemini[0].version"  ${MANIFESTS_FILE})
                APE_LOCAL_CSI_DRIVER_VERSION=$(yq e ".ape-local-csi-driver[0].version"  ${MANIFESTS_FILE})

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

                echo "MANIFESTS CLOUD_VERSION:"${CLOUD_VERSION}
                echo "MANIFESTS KUBEBLOCKS_VERSIONS:"${KUBEBLOCKS_VERSIONS}
                echo "MANIFESTS GEMINI_VERSION:"${GEMINI_VERSION}
                echo "MANIFESTS OTELD_VERSION:"${OTELD_VERSION}
                echo "MANIFESTS OFFLINE_INSTALLER_VERSION:"${OFFLINE_INSTALLER_VERSION}
                echo "MANIFESTS DMS_VERSION:"${DMS_VERSION}
                echo "MANIFESTS APE_LOCAL_CSI_DRIVER_VERSION:${APE_LOCAL_CSI_DRIVER_VERSION}"
                echo "MANIFESTS CLOUD_APE_DTS_VERSION:${CLOUD_APE_DTS_VERSION}"
                echo "MANIFESTS GEMINI_APE_DTS_VERSION:${GEMINI_APE_DTS_VERSION}"
                echo "MANIFESTS CUBETRAN_PLATFORM_VERSION:${CUBETRAN_PLATFORM_VERSION}"
                echo "MANIFESTS KUBEBENCH_VERSION:${KUBEBENCH_VERSION}"
            fi


            if [[ -n "$CLOUD_VERSION" ]]; then
                if [[ "${CLOUD_VERSION}" != "v"* ]]; then
                    CLOUD_VERSION="v${CLOUD_VERSION}"
                fi
                change_cloud_version
            fi

            if [[ -n "$KUBEBLOCKS_VERSIONS" ]]; then
                if [[ "${KUBEBLOCKS_VERSIONS}" == "v"* ]]; then
                    KUBEBLOCKS_VERSIONS="${KUBEBLOCKS_VERSIONS//v/}"
                fi
                change_kubeblocks_versions
            fi

            if [[ -n "$GEMINI_VERSION" ]]; then
                if [[ "${GEMINI_VERSION}" == "v"* ]]; then
                    GEMINI_VERSION="${GEMINI_VERSION/v/}"
                fi
                change_gemini_version
            fi

            if [[ -n "$OTELD_VERSION" ]]; then
                if [[ "${OTELD_VERSION}" == "v"* ]]; then
                    OTELD_VERSION="${OTELD_VERSION/v/}"
                fi
                change_oteld_version
            fi

            if [[ -n "$OFFLINE_INSTALLER_VERSION" ]]; then
                if [[ "${OFFLINE_INSTALLER_VERSION}" != *"-offline" ]]; then
                    OFFLINE_INSTALLER_VERSION="${OFFLINE_INSTALLER_VERSION}-offline"
                fi
                change_offline_installer_version
            fi

            if [[ -n "$DMS_VERSION" ]]; then
                if [[ "${DMS_VERSION}" == "v"* ]]; then
                    $DMS_VERSION="${DMS_VERSION/v/}"
                fi
                change_dms_version
            fi

            if [[ -n "$APE_LOCAL_CSI_DRIVER_VERSION" ]]; then
                change_ape_local_csi_drive_version
            fi

            if [[ -n "$CLOUD_APE_DTS_VERSION" ]]; then
                change_cloud_ape_dts_version
            fi

            if [[ -n "$GEMINI_APE_DTS_VERSION" ]]; then
                change_gemini_ape_dts_version
            fi

            if [[ -n "$CUBETRAN_PLATFORM_VERSION" ]]; then
                change_cubetran_platform_version
            fi

            if [[ -n "$KUBEBENCH_VERSION" ]]; then
                change_kubebench_version
            fi

            if [[ -n "$SERVICEMIRROR_VERSION" ]]; then
                change_servicemirror_version
            fi

            # Update addon images from deploy-manifests.yaml
            if [[ -n "$MANIFESTS_FILE" && -f "${MANIFESTS_FILE}" ]]; then
                echo "$(tput -T xterm setaf 3)Updating addon images from manifest$(tput -T xterm sgr0)"
                update_addon_images_from_manifest "clickhouse"
                update_addon_images_from_manifest "elasticsearch"
                update_addon_images_from_manifest "kafka"
                update_addon_images_from_manifest "mongodb"
                update_addon_images_from_manifest "mysql"
                update_addon_images_from_manifest "greatdb"
                update_addon_images_from_manifest "oceanbase"
                update_addon_images_from_manifest "postgresql"
                update_addon_images_from_manifest "qdrant"
                update_addon_images_from_manifest "rabbitmq"
                update_addon_images_from_manifest "redis"
                update_addon_images_from_manifest "starrocks"
                update_addon_images_from_manifest "zookeeper"
                update_addon_images_from_manifest "damengdb"
                update_addon_images_from_manifest "kingbase"
                update_addon_images_from_manifest "tidb"
                update_addon_images_from_manifest "vastbase"
                update_addon_images_from_manifest "minio"
                update_addon_images_from_manifest "victoria-metrics"
                update_addon_images_from_manifest "gaussdb"
                update_addon_images_from_manifest "loki"
                update_addon_images_from_manifest "mssql"
                update_addon_images_from_manifest "oceanbase-proxy"
                update_addon_images_from_manifest "pulsar"
                update_addon_images_from_manifest "rocketmq"
                update_addon_images_from_manifest "goldendb"
                update_addon_images_from_manifest "tdsql"
                update_addon_images_from_manifest "influxdb"
                update_addon_images_from_manifest "etcd"
                update_addon_images_from_manifest "milvus"
                update_addon_images_from_manifest "nebula"
                update_addon_images_from_manifest "tdengine"
                update_addon_images_from_manifest "oracle"
                update_addon_images_from_manifest "doris"
                update_addon_images_from_manifest "hadoop"
                update_addon_images_from_manifest "hive"
                update_addon_images_from_manifest "nacos"
                update_addon_images_from_manifest "camellia-redis-proxy"
                
                # Update addon chart versions in kubeblocks-enterprise.txt
                update_addon_chart_versions_from_manifest
                
                # Update addon image chart versions in kubeblocks-enterprise.txt
                update_addon_image_chart_versions_from_manifest
            fi
        ;;
        2)
            if [[ -n "$CLOUD_VERSION" ]]; then
                if [[ "${CLOUD_VERSION}" != "v"* ]]; then
                    CLOUD_VERSION="v${CLOUD_VERSION}"
                fi
                generate_release_note
            fi
        ;;
        *)
            show_help
        ;;
    esac
}

main "$@"
