#!/bin/bash
MANIFESTS_FILE=${1:-""}
IMAGES_TXT_DIR=${2:-".github/images"}
CHECK_ENGINE_FILE=${3:-"./apecloud/fountain/hack/check-engine-images.py"}
ADD_CHART=${4:-"true"}
SKIP_DELETE_FILE=${5:-""}


add_chart_repo() {
    echo "helm repo add ${KB_REPO_NAME}  ${KB_REPO_URL}"
    helm repo add ${KB_REPO_NAME} ${KB_REPO_URL}
    helm repo update ${KB_REPO_NAME}

    echo "helm repo add ${KB_ENT_REPO_NAME} --username *** --password *** ${KB_ENT_REPO_URL}"
    helm repo add ${KB_ENT_REPO_NAME} --username ${CHART_ACCESS_USER} --password ${CHART_ACCESS_TOKEN} ${KB_ENT_REPO_URL}
    helm repo update ${KB_ENT_REPO_NAME}
}

check_service_version_images() {
    service_versions_tmp=${1:-""}
    chart_version_tmp=${2:-""}
    chart_name_tmp=${3:-""}
    chart_images_tmp=${4:-""}

    if [[ ! -f "${CHECK_ENGINE_FILE}" ]]; then
        return
    fi

    echo "check-engine-images -m manifests.yaml -e ${chart_name_tmp} --addonVersion ${chart_version_tmp} --serviceVersion ${service_versions_tmp}"
    for j in {1..10}; do
        python3 ${CHECK_ENGINE_FILE} -m ${MANIFESTS_FILE} -e ${chart_name_tmp} --addonVersion ${chart_version_tmp} --serviceVersion "${service_versions_tmp}" 2>/dev/null
        ret_tmp=$?
        check_engine_result_file="images-${chart_name_tmp}-${chart_version_tmp}.yaml"
        images=""
        if [[ -f "${check_engine_result_file}" ]]; then
            images=$(yq e '.'${chart_name_tmp}'[0].images[]' ${check_engine_result_file} | grep -v "IMAGE_TAG")
            echo "${check_engine_result_file}"
            if [[ -z "${SKIP_DELETE_FILE}" || "${check_engine_result_file}" != *"${SKIP_DELETE_FILE}"* ]]; then
                rm -rf ${check_engine_result_file}
                rm -rf charts/${chart_name_tmp}-${chart_version_tmp}.tgz
            fi
        fi
        repository=""
        for repository in $( echo "$images" ); do
            if [[ "${repository}" == "null" ]]; then
                continue
            fi

            if [[ "${IMAGES_TXT_DIR}" == ".github/images/1.0" && "${chart_name_tmp}" == "oceanbase" && "${repository}" == *"apecloud/oceanbase-ent:4.2.1.7-107000112024052920-arm64" ]]; then
                continue
            fi

            echo "check engine image: $repository"
            repository=docker.io/apecloud/${repository##*/}
            check_flag=0
            for chart_image in $( echo "$chart_images_tmp" ); do
                if [[ "$chart_image" == "$repository" ]]; then
                    check_flag=1
                    break
                fi
            done

            if [[ $check_flag -eq 0 ]]; then
                check_result_tmp="$(tput -T xterm setaf 1)Not found ${chart_name_tmp} ${chart_version_tmp} image:${repository} in ${IMAGES_TXT_DIR}/${chart_name_tmp}.txt $(tput -T xterm sgr0)"
                echo "${check_result_tmp}"
                CHECK_RESULTS="$(cat check_manifest_result)"
                if [[ "${CHECK_RESULTS}" != *"${check_result_tmp}"* ]]; then
                    echo "${check_result_tmp}" >> check_manifest_result
                fi
                echo 1 > exit_result
            fi
            repository=""
        done
        if [[ $ret_tmp -eq 0 && -n "$images" ]]; then
            echo "$(tput -T xterm setaf 2)Check chart ${chart_name_tmp} ${chart_version_tmp} success$(tput -T xterm sgr0)"
            break
        fi
        sleep 1
    done
}

check_images() {
    is_enterprise_tmp=${1:-""}
    chart_version_tmp=${2:-""}
    chart_name_tmp=${3:-""}
    chart_images_tmp=${4:-""}
    set_values_tmp=${5:-""}
    for j in {1..10}; do
        template_repo="${KB_REPO_NAME}"
        if [[ "$is_enterprise_tmp" == "true" ]]; then
            template_repo="${KB_ENT_REPO_NAME}"
        fi
        echo "helm template ${chart_name_tmp} ${template_repo}/${chart_name_tmp} --version ${chart_version_tmp} ${set_values_tmp}"
        images=$( helm template ${chart_name_tmp} ${template_repo}/${chart_name_tmp} --version ${chart_version_tmp} ${set_values_tmp} | egrep 'image:|repository:|tag:|docker.io/|apecloud-registry.cn-zhangjiakou.cr.aliyuncs.com/|infracreate-registry.cn-zhangjiakou.cr.aliyuncs.com/|ghcr.io/|quay.io/' | (grep -v '[A-Z]' || true) | awk '{print $2}' | sed 's/"//g' )
        ret_tmp=$?
        repository=""
        for image in $( echo "$images" ); do
            if [[ $image == *":"* ]]; then
                repository=$image
            elif [[ -z "$repository" || "$image" == *"/"* ]]; then
                repository=$image
                continue
            elif [[ -z "$image" || "$image" == "''" ]]; then
                repository=""
                continue
            else
                repository=$repository:$image
            fi

            case $chart_name_tmp in
                kubeblocks)
                    case $repository in
                        */prometheus:*|*/grafana:*|*/k8s-sidecar:*|*/alertmanager:*|*/configmap-reload:*|*/configmap-reload:*|*/node-exporter:*)
                            repository=""
                        ;;
                    esac
                ;;
                gemini)
                    case $repository in
                        */datasafed:*|busybox:busybox)
                            repository=""
                        ;;
                    esac
                ;;
                gemini-monitor)
                    case $repository in
                        */oteld:*)
                            repository=""
                        ;;
                    esac
                ;;
            esac

            if [[ -z "$repository" || "$repository" == "image:" || "$repository" == *':$('*')' || "$repository" == *"''" || "$repository" == *":'"*"'" ]]; then
                repository=""
                continue
            fi

            if [[ -n "$repository" && ("$repository" == *"apecloud/dm:8.1.4-48_pack4"*
                || "$repository" == *"apecloud/dm:8.1.3-162-20240827-sec"*
                || "$repository" == *"apecloud/dm:8.1.4-6-20241231"*
                || "$repository" == *"apecloud/dmdb-exporter:8.1.4"*
                || "$repository" == *"apecloud/dmdb-tool:8.1.4"*
                || "$repository" == *"apecloud/oceanbase-ent:"*"-arm64"*
                || "$repository" == *"apecloud/be-ubuntu"*
                || "$repository" == *"apecloud/"*"ubuntu:3.2.2"*
                || "$repository" == *"apecloud/"*"ubuntu:3.3.0"*
                || "$repository" == *"apecloud/"*"ubuntu:3.3.2"*) ]]; then
                repository=""
                continue
            fi

            if [[ "$repository" == "'"*"'" ]]; then
                repository=${repository//\'/}
            fi

            echo "check image: $repository"
            repository=docker.io/apecloud/${repository##*/}
            check_flag=0
            for chart_image in $( echo "$chart_images_tmp" ); do
                chart_image=docker.io/apecloud/${chart_image##*/}
                if [[ "$chart_image" == "$repository" ]]; then
                    check_flag=1
                    break
                fi
            done

            if [[ $check_flag -eq 0 ]]; then
                check_result_tmp="$(tput -T xterm setaf 1)Not found ${chart_name_tmp} ${chart_version_tmp} image:$repository in ${IMAGES_TXT_DIR}/${chart_name_tmp}.txt$(tput -T xterm sgr0)"
                echo "${check_result_tmp}"
                CHECK_RESULTS="$(cat check_airgap_result)"
                if [[ "${CHECK_RESULTS}" != *"${check_result_tmp}"* ]]; then
                    echo "${check_result_tmp}" >> check_airgap_result
                fi
                echo 1 > exit_result
            fi
            repository=""
        done
        if [[ $ret_tmp -eq 0 && -n "$images" ]]; then
            echo "$(tput -T xterm setaf 2)Template chart ${chart_name_tmp} ${chart_version_tmp} success$(tput -T xterm sgr0)"
            break
        fi
        sleep 1
    done
}

check_charts_images() {
    touch exit_result check_airgap_result
    echo 0 > exit_result
    echo "" > check_airgap_result
    if [[ ! -d "${IMAGES_TXT_DIR}" ]]; then
        echo "$(tput -T xterm setaf 1)Not found images path:${IMAGES_TXT_DIR} $(tput -T xterm sgr0)"
        return
    fi

    if [[ ! -f "${MANIFESTS_FILE}" ]]; then
        echo "$(tput -T xterm setaf 1)Not found manifests file:${MANIFESTS_FILE} $(tput -T xterm sgr0)"
        return
    fi

    for image_txt in $(ls "${IMAGES_TXT_DIR}"); do
        if [[ "${image_txt}" == "damengdb.txt" ]]; then
            continue
        fi
        image_txt_path="${IMAGES_TXT_DIR}/${image_txt}"
        if [[ ! -f "${image_txt_path}" ]]; then
            continue
        fi

        check_chart_name=$(head -n 1 "${image_txt_path}" | awk '{print $2}' | tr '[:upper:]' '[:lower:]')
        chart_name=${image_txt%.txt}
        is_enterprise="false"
        check_skip=0
        service_versions=""

        case $chart_name in
            xinference|dbdrag|dify|kata|kubechat|nvidia-device-plugin|pv-migrate|spiderpool|kubernetes|k3s)
                check_skip=1
            ;;
            kubeblocks-enterprise)
                chart_name="kubeblocks-cloud"
                is_enterprise="true"
            ;;
            kubeblocks-cloud)
                is_enterprise="true"
            ;;
        esac

        if [[ -z "${check_chart_name}" || "${check_chart_name}" != "${chart_name}" || $check_skip -eq 1 || "${check_chart_name}" == "kubeblocks-enterprise-patch" ]]; then
            continue
        fi

        set_values=""
        is_enterprise=$(yq e "."${chart_name}"[0].isEnterprise"  ${MANIFESTS_FILE})
        chart_version=$(head -n 1 "${image_txt_path}" | awk '{print $3}')
        if [[ -z "${chart_version}" ]]; then
            if [[ "${IMAGES_TXT_DIR}" == ".github/images" ]]; then
                chart_version=$(yq e "."${chart_name}"[0].version"  ${MANIFESTS_FILE})
            else
                chart_versions=$(yq e '[.'${chart_name}'[].version] | join("|")' ${MANIFESTS_FILE})
                ADDON_VERSION_HEAD=${IMAGES_TXT_DIR##*/}
                chart_index=0
                for chart_version_tmp in $(echo "$chart_versions" | sed 's/|/ /g'); do
                    if [[ "${ADDON_VERSION_HEAD}."* == "${chart_version_tmp}" ]]; then
                        chart_version=${chart_version_tmp}
                        break
                    fi
                    chart_index=$(( $chart_index + 1 ))
                done
                if yq e '.'${chart_name}'['${chart_index}'] | has("serviceVersions")' "${MANIFESTS_FILE}" >/dev/null 2>&1; then
                    if [[ "${chart_version}" == "v"* ]]; then
                        chart_version="${chart_version/v/}"
                    fi
                    service_versions=$(yq e '[.'${chart_name}'['${chart_index}'].serviceVersions[]] | join(",")' ${MANIFESTS_FILE})
                fi
            fi

            if [[ -z "${chart_version}" ]]; then
                continue
            fi
        elif [[ "${IMAGES_TXT_DIR}" != ".github/images" ]]; then
            chart_versions=$(yq e '[.'${chart_name}'[].version] | join("|")' ${MANIFESTS_FILE})
            chart_index=0
            for chart_version_tmp in $(echo "$chart_versions" | sed 's/|/ /g'); do
                if [[ "${chart_version}" == "v"* ]]; then
                    chart_version="${chart_version/v/}"
                fi
                if [[ "${chart_version_tmp}" == "${chart_version}" ]]; then
                    break
                fi
                chart_index=$(( $chart_index + 1 ))
            done
            if yq e '.'${chart_name}'['${chart_index}'] | has("serviceVersions")' "${MANIFESTS_FILE}" >/dev/null 2>&1; then
                service_versions=$(yq e '[.'${chart_name}'['${chart_index}'].serviceVersions[]] | join(",")' ${MANIFESTS_FILE})
            fi
        fi
        chart_images=$(cat "${image_txt_path}" | (grep -v "#" || true))
        case $chart_name in
            kubeblocks-cloud)
                set_values="${set_values} --set images.apiserver.tag=${chart_version} "
                set_values="${set_values} --set images.sentry.tag=${chart_version} "
                set_values="${set_values} --set images.sentryInit.tag=${chart_version} "
                set_values="${set_values} --set images.relay.tag=${chart_version} "
                set_values="${set_values} --set images.cr4w.tag=${chart_version} "
                set_values="${set_values} --set images.openconsole.tag=${chart_version} "
                set_values="${set_values} --set images.openconsoleAdmin.tag=${chart_version} "
                set_values="${set_values} --set images.taskManager.tag=${chart_version} "
            ;;
            kb-cloud-installer)
                set_values="${set_values} --set version=${chart_version} "
            ;;
            ingress-nginx)
                set_values="${set_values} --set controller.image.image=apecloud/controller "
                set_values="${set_values} --set controller.image.digest= "
                set_values="${set_values} --set controller.admissionWebhooks.patch.image.image=apecloud/kube-webhook-certgen "
                set_values="${set_values} --set controller.admissionWebhooks.patch.image.digest= "
            ;;
            gemini)
                set_values="${set_values} --set victoria-metrics-cluster.enabled=false "
                set_values="${set_values} --set loki.enabled=false "
                set_values="${set_values} --set kubeviewer.enabled=false "
                set_values="${set_values} --set cr-exporter.enabled=false "
            ;;
            kubebench)
                set_values="${set_values} --set image.tag=0.0.12 "
                set_values="${set_values} --set kubebenchImages.exporter=apecloud/kubebench:0.0.12"
                set_values="${set_values} --set kubebenchImages.tools=apecloud/kubebench:0.0.12"
                set_values="${set_values} --set kubebenchImages.tpcc=apecloud/benchmarksql:1.0"
            ;;
        esac

        if [[ -n "${service_versions}" ]]; then
            check_service_version_images "${service_versions}" "$chart_version" "$chart_name" "$chart_images" &
        else
            check_images "$is_enterprise" "$chart_version" "$chart_name" "$chart_images" "$set_values" &
        fi
    done
    wait
    cat check_airgap_result
    cat exit_result
    exit $(cat exit_result)
}

main() {
    local KB_REPO_NAME="kb-charts"
    local KB_REPO_URL="https://apecloud.github.io/helm-charts"
    local KB_ENT_REPO_NAME="kb-ent-charts"
    local KB_ENT_REPO_URL="https://jihulab.com/api/v4/projects/${CHART_PROJECT_ID}/packages/helm/stable"
    if [[ "${ADD_CHART}" == "true" ]]; then
        add_chart_repo
    else
        KB_REPO_NAME="kubeblocks-addons"
        KB_REPO_URL="https://jihulab.com/api/v4/projects/150246/packages/helm/stable"
    fi
    check_charts_images
}

main "$@"
