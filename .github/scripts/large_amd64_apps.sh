#!/bin/bash

set -eu

readonly APP_NAME=${app?}
readonly APP_VERSION=${version?}
readonly APP_ARCH=amd64

readonly IMAGE_HUB_REGISTRY=${registry?}
readonly IMAGE_HUB_REPO=${repo?}
readonly IMAGE_HUB_USERNAME=${username?}
readonly IMAGE_HUB_PASSWORD=${password?}

readonly buildDir=.build-image

rm -rf $buildDir
mkdir -p $buildDir

if [[ ! -d "applications/$APP_NAME/latest" ]]; then

    case $APP_NAME in
        apecloud-mysql|etcd|kafka|llm|mongodb|mysql|postgresql|pulsar|qdrant|redis)
            sed -i "s/^CMD.*/CMD [\"kbcli addon enable $APP_NAME\"]/" applications/addons/latest/Dockerfile
        ;;
        *)
            sed -i "s/^CMD.*/CMD [\"helm upgrade --install kb-addon-$APP_NAME charts\/$APP_NAME --namespace kb-system --create-namespace\"]/" applications/addons/latest/Dockerfile
        ;;
    esac
    sed -i "s/^charts=.*/charts=(\"$APP_NAME\")/" applications/addons/latest/init.sh
    cp -af applications/addons applications/$APP_NAME
fi

if [[ -d "applications/$APP_NAME/latest" ]] && ! [[ -d "applications/$APP_NAME/$APP_VERSION" ]]; then
    cp -af .github/scripts/apps/ /tmp/scripts_apps
    cp -af "applications/$APP_NAME/latest" "applications/$APP_NAME/$APP_VERSION"
fi

cp -rf "applications/$APP_NAME/$APP_VERSION"/* $buildDir

cd $buildDir && {
    [[ -s Dockerfile ]] && Kubefile="Dockerfile" || Kubefile="Kubefile"

    if [[ -s "build_arch" ]]; then
        FILE_CONTENT=$(cat "build_arch"| tr -d '[:space:]'| tr -d '\n'| tr -d '\t')
        if [[ "$FILE_CONTENT" != "$APP_ARCH" ]]; then
            echo "The content of build_arch does not match the ARCH variable. Exiting."
            exit 0
        fi
    fi
    if [[ -s init.sh ]]; then
        bash init.sh "$APP_ARCH" "$APP_NAME" "$APP_VERSION"
    fi

    IMAGE_NAME="$IMAGE_HUB_REGISTRY/$IMAGE_HUB_REPO/$APP_NAME-airgap:$APP_VERSION"

    sudo sealos login -u "$IMAGE_HUB_USERNAME" -p "$IMAGE_HUB_PASSWORD" "$IMAGE_HUB_REGISTRY"

    IMAGE_BUILD="${IMAGE_NAME%%:*}:build-$(date +%s)"

    sudo sealos build -t "$IMAGE_BUILD" --max-pull-procs=20 --isolation=chroot --platform "linux/$APP_ARCH" -f $Kubefile .

    echo "init $IMAGE_NAME success"
}

sudo buildah images
