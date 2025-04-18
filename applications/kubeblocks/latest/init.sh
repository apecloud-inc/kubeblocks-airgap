#!/bin/bash
set -ex

cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly ARCH=${1:-amd64}
export readonly NAME=${2:-$(basename "${PWD%/*}")}
export readonly VERSION=${3:-$(basename "$PWD")}
export readonly BIN_DOWNLOAD=${4:-"true"}
export readonly REDUCE_VERSION=${5:-"true"}

if [[ -z "${BIN_DOWNLOAD}" || "${BIN_DOWNLOAD}" == "true" ]]; then
    mkdir -p opt
    if [[ "$VERSION" == "v1.0.0-beta."* ]]; then
        wget https://github.com/apecloud/kbcli/releases/download/v1.0.0-beta.15/kbcli-linux-"${ARCH}"-"v1.0.0-beta.15".tar.gz -O kbcli.tar.gz
    else
        wget https://github.com/apecloud/kbcli/releases/download/"${VERSION}"/kbcli-linux-"${ARCH}"-"${VERSION}".tar.gz -O kbcli.tar.gz
    fi
    tar -zxvf kbcli.tar.gz linux-"${ARCH}"/kbcli
    mv linux-"${ARCH}"/kbcli opt/kbcli
    chmod a+x opt/kbcli
    rm -rf linux-"${ARCH}" kbcli.tar.gz
    echo "download kbcli success"
fi

mkdir charts

repo_url="https://github.com/apecloud/helm-charts/releases/download"
charts=("kubeblocks")
if [[ "$REDUCE_VERSION" != "true" ]]; then
    charts=("kubeblocks" "apecloud-mysql" "mongodb" "postgresql" "redis" "kafka" "qdrant" "clickhouse" "oceanbase")
    if [[ "${VERSION}" == "v0.6."* ]]; then
        charts=("kubeblocks" "apecloud-mysql" "mongodb" "postgresql" "redis" "kafka")
    fi
fi

for chart in "${charts[@]}"; do
    chart_version=${VERSION#v}
    if [[ "$REDUCE_VERSION" != "true" ]]; then
        if [[ "$chart" != "kubeblocks" && "$VERSION" != "v0.5."* && "$VERSION" != "v0.6."*  && "$VERSION" != "v0.7."*  ]]; then
            chart_version=$(cat charts/kubeblocks/templates/addons/$chart-addon.yaml | (grep "\"version\"" || true) | awk '{print $2}'| sed 's/"//g')
        fi
    fi
    helm fetch -d charts --untar "$repo_url"/"${chart}"-"${chart_version}"/"${chart}"-"${chart_version}".tgz
    if [[ "$chart" == "kubeblocks" && "$VERSION" != "v0.5."* && "$VERSION" != "v0.6."*  && "$VERSION" != "v0.7."*  ]]; then
        kubeblocks_crds_file="kubeblocks_crds.yaml"
        wget https://github.com/apecloud/kubeblocks/releases/download/${VERSION}/${kubeblocks_crds_file} -O ${kubeblocks_crds_file}
        kubeblocks_crds_dir="charts/${chart}/crds"
        mkdir -p ${kubeblocks_crds_dir}
        if [[ -f "${kubeblocks_crds_file}" ]]; then
            mv ${kubeblocks_crds_file} ${kubeblocks_crds_dir}
        fi
    fi
#    if [[ "$REDUCE_VERSION" == "true" ]]; then
#        case $chart in
#            mongodb)
#                yq e -i '.enabledClusterVersions=[ "mongodb-5.0", "mongodb-6.0" ]' charts/${chart}/values.yaml
#            ;;
#            postgresql)
#                yq e -i '.enabledClusterVersions=[ "postgresql-14.7.2", "postgresql-12.15.0" ]' charts/${chart}/values.yaml
#            ;;
#        esac
#    fi
    rm -rf charts/"${chart}"-"${chart_version}".tgz
done

# add extra images
mkdir -p images/shim
echo "apecloud/kubeblocks-charts:${VERSION#v}" >images/shim/kubeblocksImages
echo "apecloud/datasafed:0.2.0" >>images/shim/kubeblocksImages
