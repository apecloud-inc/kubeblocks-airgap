#!/bin/bash
MANIFESTS_FILE=${1:-""}
ADD_CHART=${2:-"true"}
CHECK_ENGINE_FILE=${3:-"./apecloud/fountain/hack/check-engine-images.py"}


is_chart_enabled() {
    local chart_name_tmp="${1:-}"
    local deploy_values_file
    deploy_values_file="$(dirname "${MANIFESTS_FILE}")/deploy-values.yaml"
    if [[ ! -f "${deploy_values_file}" ]]; then
        return 0
    fi
    local enable_val
    enable_val=$(yq e ".${chart_name_tmp}.enable" "${deploy_values_file}" 2>/dev/null || echo "true")
    if [[ "${enable_val}" == "false" ]]; then
        echo "$(tput -T xterm setaf 3)Skip check chart ${chart_name_tmp}, enable is false in deploy-values.yaml$(tput -T xterm sgr0)"
        return 1
    fi
    return 0
}

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

    for j in {1..10}; do
        python3 ${CHECK_ENGINE_FILE} -m ${MANIFESTS_FILE} -e ${chart_name_tmp} --addonVersion ${chart_version_tmp} --serviceVersion "${service_versions_tmp}" 2>/dev/null
        ret_tmp=$?
        check_engine_result_file="images-${chart_name_tmp}-${chart_version_tmp}.yaml"
        images=""
        if [[ -f "${check_engine_result_file}" ]]; then
            images=$(yq e '.'${chart_name_tmp}'[0].images[]' ${check_engine_result_file} | grep -v "IMAGE_TAG")
            rm -rf ${check_engine_result_file}
        fi
        repository=""
        for repository in $( echo "$images" ); do
            if [[ "${repository}" == "null" ]]; then
                continue
            fi
            echo "check engine image: $repository"
            check_flag=0
            for chart_image in $( echo "$chart_images_tmp" ); do
                if [[ "$chart_image" == "$repository" ]]; then
                    check_flag=1
                    break
                fi
            done

            if [[ $check_flag -eq 0 ]]; then
                check_result_tmp="$(tput -T xterm setaf 1)Not found ${chart_name_tmp} ${chart_version_tmp} image:${repository} in manifests file:${MANIFESTS_FILE}$(tput -T xterm sgr0)"
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
            repository=apecloud/${repository##*/}
            check_flag=0
            for chart_image in $( echo "$chart_images_tmp" ); do
                if [[ "$chart_image" == "$repository" ]]; then
                    check_flag=1
                    break
                fi
            done

            if [[ $check_flag -eq 0 ]]; then
                check_result_tmp="$(tput -T xterm setaf 1)Not found ${chart_name_tmp} ${chart_version_tmp} image:${repository} in manifests file:${MANIFESTS_FILE}$(tput -T xterm sgr0)"
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
            echo "$(tput -T xterm setaf 2)Template chart ${chart_name_tmp} ${chart_version_tmp} success$(tput -T xterm sgr0)"
            break
        fi
        sleep 1
    done
}

check_addon_charts_images() {
    chart_version_tmp=${1:-""}
    chart_name_tmp=${2:-""}
    chart_images_tmp=${3:-""}
    addon_charts_images=""

    # Get ALL addon chart images (with suffix) from the manifests by scanning every engine
    # This is more reliable than relying only on the kubeblocks-cloud section
    charts_name=$(yq e "to_entries|map(.key)|.[]"  ${MANIFESTS_FILE})
    for chart_name in $(echo "$charts_name"); do
        if [[ -z "$chart_name" || "$chart_name" == "#"* || "$chart_name" == "kata" ]]; then
            continue
        fi

        if ! is_chart_enabled "$chart_name"; then
            continue
        fi

        if [[ "$chart_name" == "apecloud-mysql" || "$chart_name" == "mogdb" || "$chart_name" == "greatsql" ]]; then
            continue
        fi
        chart_versions=$(yq e '[.'${chart_name}'[].version] | join("|")' ${MANIFESTS_FILE})
        chart_index=0
        for chart_version in $(echo "$chart_versions" | sed 's/|/ /g'); do
            engine_type=$(yq e "."${chart_name}"[${chart_index}].type"  ${MANIFESTS_FILE})
            if [[ "${engine_type}" == "engine" ]]; then
                # Look for the actual suffixed chart image in this addon's images list (new manifest structure)
                suffixed_chart=$(yq e '.'${chart_name}'['${chart_index}'].images[] | select(. == "*apecloud-addon-charts:'${chart_name}'-'${chart_version}'*")' ${MANIFESTS_FILE} 2>/dev/null || true)
                if [[ -n "$suffixed_chart" ]]; then
                    addon_charts_images="${addon_charts_images}|${suffixed_chart}"
                else
                    # Fallback to base (for compatibility with older manifests)
                    addon_charts_image="apecloud/apecloud-addon-charts:${chart_name}-${chart_version}"
                    addon_charts_images="${addon_charts_images}|${addon_charts_image}"
                fi
            fi
            chart_index=$(( $chart_index + 1 ))
        done
    done

    # Read the actual list from airgap txt files (authoritative source after upgrade_version.sh)
    # This is more reliable than only using the images passed from kubeblocks-cloud section
    local airgap_chart_list=""
    for txt_file in ".github/images/kubeblocks-cloud.txt" ".github/images/kubeblocks-enterprise.txt"; do
        if [[ -f "$txt_file" ]]; then
            while IFS= read -r line; do
                if [[ "$line" == *"apecloud-addon-charts:"* ]]; then
                    # Extract the full chart identifier (with or without suffix)
                    chart_part=$(echo "$line" | sed -E 's|.*(apecloud-addon-charts:[^ ]+).*|\1|')
                    airgap_chart_list="${airgap_chart_list}|${chart_part}"
                fi
            done < "$txt_file"
        fi
    done

    if [[ -n "$addon_charts_images" ]]; then
        echo "Checking addon chart images (normalized comparison)..."
        repository=""
        check_flag_all=0
        for image in $( echo "$addon_charts_images" | sed 's/|/ /g'); do
            if [[ -z "$image" || "$image" == "null" ]]; then
                continue
            fi
            repository=$image
            echo "check image: $repository"
            check_flag=0

            # Check against both the manifest-derived list and the airgap txt list (more robust)
            for chart_image in $( echo "$airgap_chart_list $chart_images_tmp" | tr ' ' '\n' | sort -u ); do
                if [[ -z "$chart_image" ]]; then
                    continue
                fi
                local normalized_chart_image="$chart_image"
                local normalized_repo="$repository"

                # Normalize both sides aggressively for cloud suffix and version:
                # Remove -v2.3.xx, -vX.Y.Z, or any cloud version suffix
                normalized_chart_image=$(echo "$normalized_chart_image" | sed 's/-v[0-9][^ ]*//g')
                normalized_repo=$(echo "$normalized_repo" | sed 's/-v[0-9][^ ]*//g')
                # Also normalize the full repo path for comparison
                base_chart=$(echo "$normalized_chart_image" | sed 's|.*/||')
                base_repo=$(echo "$normalized_repo" | sed 's|.*/||')

                if [[ "$normalized_chart_image" == "$normalized_repo" ]] || \
                   [[ "$base_chart" == "$base_repo" ]] || \
                   [[ "$chart_image" == *"${repository#*/}"* ]] || \
                   [[ "$normalized_chart_image" == *"${base_repo}"* ]]; then
                    check_flag=1
                    break
                fi
            done

            if [[ $check_flag -eq 0 ]]; then
                check_flag_all=1
                check_result_tmp="$(tput -T xterm setaf 1)Not found ${chart_name_tmp} ${chart_version_tmp} image:${repository} in manifests file:${MANIFESTS_FILE}$(tput -T xterm sgr0)"
                echo "${check_result_tmp}"
                CHECK_RESULTS="$(cat check_manifest_result)"
                if [[ "${CHECK_RESULTS}" != *"${check_result_tmp}"* ]]; then
                    echo "${check_result_tmp}" >> check_manifest_result
                fi
                echo 1 > exit_result
            fi
            repository=""
        done
        if [[ $check_flag_all -eq 0 ]]; then
            echo "$(tput -T xterm setaf 2)Check addon charts in ${chart_name_tmp} ${chart_version_tmp} success$(tput -T xterm sgr0)"
        else
            echo "$(tput -T xterm setaf 3)Some addon chart images had matching issues (see above). Check normalization logic.$(tput -T xterm sgr0)"
        fi
    fi
}

check_charts_images() {
    touch exit_result check_manifest_result
    echo 0 > exit_result
    echo "" > check_manifest_result
    if [[ ! -f "${MANIFESTS_FILE}" ]]; then
        echo "$(tput -T xterm setaf 1)Not found manifests file:${MANIFESTS_FILE} $(tput -T xterm sgr0)"
        return
    fi

    charts_name=$(yq e "to_entries|map(.key)|.[]"  ${MANIFESTS_FILE})
    for chart_name in $(echo "$charts_name"); do
        if [[ -z "$chart_name" || "$chart_name" == "#"* || "$chart_name" == "kata" ]]; then
            continue
        fi

        if ! is_chart_enabled "$chart_name"; then
            continue
        fi

        if [[ "$chart_name" == "apecloud-mysql" || "$chart_name" == "mogdb" || "$chart_name" == "greatsql" ]]; then
            continue
        fi
        set_values=""
        chart_versions=$(yq e '[.'${chart_name}'[].version] | join("|")' ${MANIFESTS_FILE})
        chart_index=0
        for chart_version in $(echo "$chart_versions" | sed 's/|/ /g'); do
            is_enterprise=$(yq e "."${chart_name}"[${chart_index}].isEnterprise"  ${MANIFESTS_FILE})
            chart_images=$(yq e "."${chart_name}"[${chart_index}].images[]"  ${MANIFESTS_FILE})

            service_versions=""
            if yq e '.'${chart_name}'['${chart_index}'] | has("serviceVersions")' "${MANIFESTS_FILE}" >/dev/null 2>&1; then
                service_versions=$(yq e '[.'${chart_name}'['${chart_index}'].serviceVersions[]] | join(",")' ${MANIFESTS_FILE})
            fi

            if [[ -n "${service_versions}" ]]; then
                check_service_version_images "${service_versions}" "$chart_version" "$chart_name" "$chart_images" &
            else
                case $chart_name in
                    kubeblocks-cloud)
                        set_values="${set_values} --set images.apiserver.tag=${chart_version} "
                        set_values="${set_values} --set images.sentry.tag=${chart_version} "
                        set_values="${set_values} --set images.sentryInit.tag=${chart_version} "
                        set_values="${set_values} --set images.relay.tag=${chart_version} "
                        set_values="${set_values} --set images.cr4w.tag=${chart_version} "
                        set_values="${set_values} --set images.console.tag=${chart_version} "
                        set_values="${set_values} --set images.taskManager.tag=${chart_version} "
                        set_values="${set_values} --set onlyNewConsole=true "
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
                    dbdrag)
                        continue
                    ;;
                esac
                if [[ "$chart_name" == "kubeblocks-cloud" ]]; then
                    check_addon_charts_images "$chart_version" "$chart_name" "$chart_images" &
                fi
                check_images "$is_enterprise" "$chart_version" "$chart_name" "$chart_images" "$set_values" &

            fi
            chart_index=$(( $chart_index + 1 ))
        done
    done
    wait
    cat check_manifest_result
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
    fi
    check_charts_images
}

main "$@"
