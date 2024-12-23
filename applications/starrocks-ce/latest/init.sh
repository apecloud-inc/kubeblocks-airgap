#!/bin/bash
set -ex

cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
export readonly ARCH=${1:-amd64}
export readonly NAME=${2:-$(basename "${PWD%/*}")}
export readonly VERSION=${3:-$(basename "$PWD")}

rm -rf charts
mkdir charts

repo_url="https://github.com/apecloud/helm-charts/releases/download"

charts=("starrocks-ce")

for chart in "${charts[@]}"; do
    helm fetch -d charts --untar "$repo_url"/"${chart}"-"${VERSION#v}"/"${chart}"-"${VERSION#v}".tgz
    rm -rf charts/"${chart}"-"${VERSION#v}".tgz
done

# add extra images
mkdir -p images/shim
echo "docker.io/apecloud/be-ubuntu:3.2.2" > images/shim/kubeblocksImages
echo "docker.io/apecloud/be-ubuntu:3.3.0" >> images/shim/kubeblocksImages
echo "docker.io/apecloud/fe-ubuntu:3.2.2" >> images/shim/kubeblocksImages
echo "docker.io/apecloud/fe-ubuntu:3.3.0" >> images/shim/kubeblocksImages
