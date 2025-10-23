#!/bin/bash

set -eu

readonly K8S_NAME=${k8s_name?}
readonly K8S_VERSION=${k8s_version?}
readonly SEALOS_VERSION=${sealos_version?}
readonly HELM_VERSION=${helm_version?}
readonly METRICS_SERVER_VERSION="${metrics_server_version?}"
readonly CALICO_VERSION="${calico_version?}"
readonly COREDNS_VERSION="${coredns_version?}"
readonly OPENEBS_VERSION="${openebs_version?}"

echo "K8S_NAME:"${K8S_NAME}
echo "K8S_VERSION:"${K8S_VERSION}
echo "SEALOS_VERSION:"${SEALOS_VERSION}
echo "HELM_VERSION:"${HELM_VERSION}
echo "METRICS_SERVER_VERSION:"${METRICS_SERVER_VERSION}
echo "CALICO_VERSION:"${CALICO_VERSION}
echo "COREDNS_VERSION:"${COREDNS_VERSION}
echo "OPENEBS_VERSION:"${OPENEBS_VERSION}

save_k8s_images_package() {
    # 1. create kube-airgap directory
    mkdir -p kube-airgap
    cd kube-airgap

    # 2. download sealos cli package
    echo "download sealos cli: ${SEALOS_DOWNLOAD_URL}"
    sealos_cli_pkg_name="${SEALOS_DOWNLOAD_URL##*/}"
    for i in {1..10}; do
        wget ${SEALOS_DOWNLOAD_URL}
        ret_msg=$?
        if [[ $ret_msg -eq 0 ]]; then
            echo "$(tput -T xterm setaf 2)download ${sealos_cli_pkg_name} success$(tput -T xterm sgr0)"
            break
        fi
        echo "$(tput -T xterm setaf 3)download sealos cli ...$(tput -T xterm sgr0)"
        rm -rf ${sealos_cli_pkg_name}*
        sleep 1
    done

    # install sealos cli
    if [[ -f "${sealos_cli_pkg_name}" && "${K8S_NAME}" != *"-arm64" ]]; then
        mkdir -p ../sealos
        tar -zxvf ${sealos_cli_pkg_name} -C ../sealos
        sudo chmod a+x ../sealos/sealos
        sudo mv ../sealos/sealos /usr/bin/
        sudo sealos version
    fi

    # 3. save images tar
    declare -A images_map=(
        [kubernetes-airgap]="docker.io/apecloud/kubernetes-airgap:${K8S_VERSION}"
        [helm]="docker.io/labring/helm:${HELM_VERSION_TMP}"
        [calico-airgap]="docker.io/apecloud/calico-airgap:${CALICO_VERSION_TMP}"
        [metrics-server]="docker.io/labring/metrics-server:${METRICS_SERVER_VERSION_TMP}"
        [coredns]="docker.io/labring/coredns:${COREDNS_VERSION_TMP}"
        [openebs]="docker.io/labring/openebs:${OPENEBS_VERSION_TMP}"
    )

    for image_name in ${!images_map[@]}; do
        image=${images_map[$image_name]}
        image_pkg_name="${image_name}.tar"
        echo "pull image $image"
        for i in {1..10}; do
            podman pull "$image"
            ret_msg=$?
            if [[ $ret_msg -eq 0 ]]; then
                echo "$(tput -T xterm setaf 2)pull image $image success$(tput -T xterm sgr0)"
                break
            fi
            echo "$(tput -T xterm setaf 3)pull image $image_name ...$(tput -T xterm sgr0)"
            sleep 1
        done
        sealos images
        echo "save image ${image_pkg_name}"
        for i in {1..10}; do
            sealos save -o ${image_pkg_name} ${image}
            ret_msg=$?
            if [[ $ret_msg -eq 0 ]]; then
                echo "$(tput -T xterm setaf 2)save ${image_pkg_name} success$(tput -T xterm sgr0)"
                break
            fi
            echo "$(tput -T xterm setaf 3)save package ${image_name} ...$(tput -T xterm sgr0)"
            sleep 1
        done
    done

    # 4. save k8s package
    cd ..
    ls kube-airgap
    for i in {1..10}; do
        tar -czvf ${K8S_PACKAGE_NAME} kube-airgap
        ret_msg=$?
        if [[ $ret_msg -eq 0 ]]; then
            echo "$(tput -T xterm setaf 2)save ${K8S_PACKAGE_NAME} success$(tput -T xterm sgr0)"
            break
        fi
        echo "$(tput -T xterm setaf 3)save k8s pacakge ...$(tput -T xterm sgr0)"
        rm -rf ${K8S_PACKAGE_NAME}
        sleep 1
    done
}

main() {
    local K8S_PACKAGE_NAME="${K8S_NAME}-${K8S_VERSION}.tar.gz"
    local SEALOS_DOWNLOAD_URL_HEAD="https://github.com/labring/sealos/releases/download"
    local SEALOS_DOWNLOAD_URL=""
    local SEALOS_VERSION_TMP=${SEALOS_VERSION}
    local HELM_VERSION_TMP=${HELM_VERSION}
    local METRICS_SERVER_VERSION_TMP=${METRICS_SERVER_VERSION}
    local CALICO_VERSION_TMP=${CALICO_VERSION}
    local COREDNS_VERSION_TMP=${COREDNS_VERSION}
    local OPENEBS_VERSION_TMP=${OPENEBS_VERSION}

    if [[ -z "${SEALOS_VERSION_TMP}" ]]; then
        SEALOS_VERSION_TMP="5.1.0-rc3"
    elif [[ "${SEALOS_VERSION_TMP}" == "v"* ]]; then
        SEALOS_VERSION_TMP="${SEALOS_VERSION_TMP/v/}"
    fi

    if [[ "${K8S_NAME}" == *"-arm64" ]]; then
        SEALOS_DOWNLOAD_URL="${SEALOS_DOWNLOAD_URL_HEAD}/v${SEALOS_VERSION_TMP}/sealos_${SEALOS_VERSION_TMP}_linux_arm64.tar.gz"

        # download sealos cli package
        sealos_cli_pkg_name_2="sealos_5.0.0_linux_arm64.tar.gz"
        SEALOS_DOWNLOAD_URL_2="${SEALOS_DOWNLOAD_URL_HEAD}/v5.0.0/${sealos_cli_pkg_name_2}"
        echo "download sealos cli: ${SEALOS_DOWNLOAD_URL_2}"
        for i in {1..10}; do
            wget ${SEALOS_DOWNLOAD_URL_2}
            ret_msg=$?
            if [[ $ret_msg -eq 0 ]]; then
                echo "$(tput -T xterm setaf 2)download ${sealos_cli_pkg_name_2} success$(tput -T xterm sgr0)"
                break
            fi
            echo "$(tput -T xterm setaf 3)download sealos cli ...$(tput -T xterm sgr0)"
            rm -rf ${sealos_cli_pkg_name_2}*
            sleep 1
        done

        # install sealos
        mkdir -p sealos_cli
        tar -zxvf ${sealos_cli_pkg_name_2} -C ./sealos_cli
        sudo chmod a+x ./sealos_cli/sealos
        sudo mv ./sealos_cli/sealos /usr/bin/
        sudo sealos version
    else
        SEALOS_DOWNLOAD_URL="${SEALOS_DOWNLOAD_URL_HEAD}/v${SEALOS_VERSION_TMP}/sealos_${SEALOS_VERSION_TMP}_linux_amd64.tar.gz"
    fi

    if [[ -z "${HELM_VERSION_TMP}" ]]; then
        HELM_VERSION_TMP="v3.18.4"
    fi

    if [[ -z "${METRICS_SERVER_VERSION_TMP}" ]]; then
        METRICS_SERVER_VERSION_TMP="v0.7.1"
    fi

    if [[ -z "${CALICO_VERSION_TMP}" ]]; then
        CALICO_VERSION_TMP="v3.28.0"
    fi

    if [[ -z "${COREDNS_VERSION_TMP}" ]]; then
        COREDNS_VERSION_TMP="v0.0.1"
    fi

    if [[ -z "${OPENEBS_VERSION_TMP}" ]]; then
        OPENEBS_VERSION_TMP="v3.10.0"
    fi

    save_k8s_images_package
}

main "$@"
