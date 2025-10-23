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

    # 3. save images tar
    declare -A images_map=(
        [kubernetes-airgap]="apecloud/kubernetes-airgap:${K8S_VERSION}"
        [helm]="labring/helm:${HELM_VERSION_TMP}"
        [calico-airgap]="apecloud/calico-airgap:${CALICO_VERSION_TMP}"
        [metrics-server]="labring/metrics-server:${METRICS_SERVER_VERSION_TMP}"
        [coredns]="labring/coredns:${COREDNS_VERSION_TMP}"
        [openebs]="labring/openebs:${OPENEBS_VERSION_TMP}"
    )

    for image in ${!images_map[@]}; do
        echo "pull image $image"
        for i in {1..10}; do
            sealos pull "$image"
            ret_msg=$?
            if [[ $ret_msg -eq 0 ]]; then
                echo "$(tput -T xterm setaf 2)pull image $image success$(tput -T xterm sgr0)"
                break
            fi
            echo "$(tput -T xterm setaf 3)pull image $image ...$(tput -T xterm sgr0)"
            sleep 1
        done

        echo "save image ${image}.tar"
        for i in {1..10}; do
            sealos save ${images_map[$image]} -o ${image}.tar
            ret_msg=$?
            if [[ $ret_msg -eq 0 ]]; then
                echo "$(tput -T xterm setaf 2)save ${K8S_PACKAGE_NAME} success$(tput -T xterm sgr0)"
                break
            fi
            echo "$(tput -T xterm setaf 3)save ${image}.tar ...$(tput -T xterm sgr0)"
            sleep 1
        done
    done

    # 4. save k8s package
    cd ..
    ls kube-airgap
    for i in {1..10}; do
        tar -cvzf ${K8S_PACKAGE_NAME} kube-airgap
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
    local SEALOS_DOWNLOAD_URL="https://github.com/labring/sealos/releases/download/"

    echo SEALOS_VERSION_TMP=${SEALOS_VERSION}
    echo HELM_VERSION_TMP=${HELM_VERSION}
    echo METRICS_SERVER_VERSION_TMP=${METRICS_SERVER_VERSION}
    echo CALICO_VERSION_TMP=${CALICO_VERSION}
    echo COREDNS_VERSION_TMP=${COREDNS_VERSION}
    echo OPENEBS_VERSION_TMP=${OPENEBS_VERSION}

    if [[ -z "${SEALOS_VERSION_TMP}"  ]]; then
        SEALOS_VERSION_TMP="5.1.0-rc3"
    elif [[ "${SEALOS_VERSION_TMP}" == "v"* ]]; then
        SEALOS_VERSION_TMP="${SEALOS_VERSION_TMP/v/}"
    fi

    if [[ "${K8S_NAME}" == *"-arm64"  ]]; then
        SEALOS_DOWNLOAD_URL="v${SEALOS_VERSION_TMP}/sealos_${SEALOS_VERSION_TMP}_linux_arm64.tar.gz"
    else
        SEALOS_DOWNLOAD_URL="v${SEALOS_VERSION_TMP}/sealos_${SEALOS_VERSION_TMP}_linux_amd64.tar.gz"
    fi

    if [[ -z "${HELM_VERSION_TMP}"  ]]; then
        HELM_VERSION_TMP="v3.18.4"
    fi

    if [[ -z "${METRICS_SERVER_VERSION_TMP}"  ]]; then
        METRICS_SERVER_VERSION_TMP="v0.7.1"
    fi

    if [[ -z "${CALICO_VERSION_TMP}"  ]]; then
        CALICO_VERSION_TMP="v3.28.0"
    fi

    if [[ -z "${COREDNS_VERSION_TMP}"  ]]; then
        COREDNS_VERSION_TMP="v0.0.1"
    fi

    if [[ -z "${OPENEBS_VERSION_TMP}"  ]]; then
        OPENEBS_VERSION_TMP="v3.10.0"
    fi

    save_k8s_images_package
}

main "$@"
