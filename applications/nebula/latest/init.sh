#!/bin/bash
set -ex

cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly ARCH=${1:-amd64}
export readonly NAME=${2:-$(basename "${PWD%/*}")}
export readonly VERSION=${3:-$(basename "$PWD")}

rm -rf charts
mkdir charts

repo_url="https://github.com/apecloud/helm-charts/releases/download"
charts=( "nebula")
for chart in "${charts[@]}"; do
    helm fetch -d charts --untar "$repo_url"/"${chart}"-"${VERSION#v}"/"${chart}"-"${VERSION#v}".tgz
    rm -rf charts/"${chart}"-"${VERSION#v}".tgz
done

if [[ "${chart}" == "nebula" && "${VERSION}" == "v0.9.1" ]]; then
    # add extra images
    mkdir -p images/shim
    echo "apecloud/alpine:3.16" >images/shim/kubeblocksImages
    echo "apecloud/nebula-console:v3.5.0" >>images/shim/kubeblocksImages
    echo "apecloud/nebula-graphd:v3.5.0" >>images/shim/kubeblocksImages
    echo "apecloud/nebula-metad:v3.5.0" >>images/shim/kubeblocksImages
    echo "apecloud/nebula-storaged:v3.5.0" >>images/shim/kubeblocksImages
fi
