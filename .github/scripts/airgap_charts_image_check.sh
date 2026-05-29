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

            if [[ "${IMAGES_TXT_DIR}" == ".github/images/1.0"
                && "${chart_name_tmp}" == "oceanbase"
                && "${repository}" == *"apecloud/oceanbase-ent:"*"-arm64" ]]; then
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
                CHECK_RESULTS="$(cat check_airgap_result)"
                if [[ "${CHECK_RESULTS}" != *"${check_result_tmp}"* ]]; then
                    echo "${check_result_tmp}" >> check_airgap_result
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
        if [[ "$is_enterprise_tmp" == "true" || "${chart_name_tmp}" == "victoria-logs" ]]; then
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

            if [[ -n "$repository" && ("$repository" == *"apecloud/dm:"*"pack"*
                || "$repository" == *"apecloud/dm:"*"-sec"*
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

check_kubeblocks_enterprise_txt() {
    local enterprise_txt="${IMAGES_TXT_DIR}/kubeblocks-enterprise.txt"
    
    if [[ ! -f "${enterprise_txt}" ]]; then
        echo "$(tput -T xterm setaf 3)Warning: Not found kubeblocks-enterprise.txt:${enterprise_txt} $(tput -T xterm sgr0)"
        return
    fi

    if [[ ! -f "${MANIFESTS_FILE}" ]]; then
        echo "$(tput -T xterm setaf 1)Not found manifests file:${MANIFESTS_FILE} $(tput -T xterm sgr0)"
        return
    fi

    echo "Checking kubeblocks-enterprise.txt images consistency with deploy-manifests.yaml..."
    
    # Define which sections to check based on comments in the file
    declare -A sections_to_check
    sections_to_check=(
        ["KubeBlocks-Cloud"]=1
        ["KubeBlocks v"]=1
        ["Gemini v"]=1
        ["Minio"]=1
        ["Loki"]=1
    )
    
    # Step 1: Parse enterprise txt and collect images from specified sections
    declare -A txt_images_map
    local txt_image_count=0
    local current_section=""
    local in_target_section=0
    
    while IFS= read -r line; do
        # Check if this is a comment line indicating a new section
        if [[ "$line" == \#* ]]; then
            current_section="$line"
            # Check if this section should be checked
            in_target_section=0
            for section_keyword in "${!sections_to_check[@]}"; do
                if [[ "$line" == *"$section_keyword"* ]]; then
                    in_target_section=1
                    break
                fi
            done
            continue
        fi
        
        # Skip empty lines or lines not in target sections
        if [[ -z "$line" || $in_target_section -eq 0 ]]; then
            continue
        fi
        
        # Parse image (format: docker.io/apecloud/image:tag)
        local txt_image=$(echo "$line" | sed 's|^docker.io/||')
        local txt_image_name=$(echo "$txt_image" | cut -d':' -f1)
        local txt_image_tag=$(echo "$txt_image" | rev | cut -d':' -f1 | rev)
        
        if [[ -n "$txt_image_name" && -n "$txt_image_tag" ]]; then
            # Store full image as key for exact matching
            txt_images_map["$txt_image"]=1
            txt_image_count=$((txt_image_count + 1))
        fi
    done < "${enterprise_txt}"
    
    echo "  Total images in target sections of kubeblocks-enterprise.txt: ${txt_image_count}"
    
    # Step 2: Collect ALL images from deploy-manifests.yaml for the corresponding charts
    # Map txt sections to chart names in manifests
    declare -A section_to_charts
    section_to_charts=(
        ["KubeBlocks-Cloud"]="kubeblocks-cloud kb-cloud-installer"
        ["KubeBlocks v"]="kubeblocks"
        ["Gemini v"]="gemini gemini-monitor"
        ["Minio"]="minio"
        ["Loki"]="loki"
    )
    
    # Images to skip from checking
    local skip_images=(
        "apecloud/postgres-exporter:v0.13.2"
        "apecloud/kubeblocks-tools:1.0.0"
    )
    declare -A skip_images_map
    for skip_img in "${skip_images[@]}"; do
        skip_images_map["$skip_img"]=1
    done
    
    declare -A manifest_images_map
    declare -A image_to_module  # Track which module each image belongs to
    local manifest_image_count=0
    
    for section_keyword in "${!sections_to_check[@]}"; do
        local charts="${section_to_charts[$section_keyword]}"
        for chart in $charts; do
            # For minio and loki, only check specific versions based on txt comments
            local chart_versions_to_check=""
            if [[ "$chart" == "minio" || "$chart" == "loki" ]]; then
                # Extract version from txt comment (e.g., "# Minio v1.0.3")
                local target_version=""
                while IFS= read -r line; do
                    if [[ "$line" == \#*"${section_keyword}"* ]]; then
                        target_version=$(echo "$line" | sed -n 's/.*[vV]\([0-9][^ ]*\).*/\1/p')
                        break
                    fi
                done < "${enterprise_txt}"
                
                if [[ -n "$target_version" ]]; then
                    # Get all versions for this chart
                    local all_versions=$(yq e '[.'${chart}'[].version] | .[]' "${MANIFESTS_FILE}" 2>/dev/null)
                    for ver in $all_versions; do
                        # Remove 'v' prefix for comparison
                        local ver_clean=${ver#v}
                        local target_clean=${target_version#v}
                        if [[ "$ver_clean" == "$target_clean" ]]; then
                            chart_versions_to_check="$ver"
                            break
                        fi
                    done
                fi
            fi
            
            local chart_images=""
            if [[ -n "$chart_versions_to_check" ]]; then
                # Only get images for specific version
                chart_images=$(yq e '.'${chart}'[] | select(.version == "'${chart_versions_to_check}'") | .images[]' "${MANIFESTS_FILE}" 2>/dev/null)
            else
                # Get all images for this chart
                chart_images=$(yq e '.'${chart}'[].images[]' "${MANIFESTS_FILE}" 2>/dev/null)
            fi
            
            if [[ -n "$chart_images" ]]; then
                while IFS= read -r img; do
                    if [[ -n "$img" ]]; then
                        # Skip images in the skip list
                        if [[ -n "${skip_images_map[$img]}" ]]; then
                            continue
                        fi
                        manifest_images_map["$img"]=1
                        image_to_module["$img"]="$chart"  # Store module name
                        manifest_image_count=$((manifest_image_count + 1))
                    fi
                done <<< "$chart_images"
            fi
        done
    done
    
    echo "  Total images in corresponding charts of deploy-manifests.yaml: ${manifest_image_count}"
    
    # Step 3: Check manifests -> txt (reverse check)
    # Find images that exist in manifests but NOT in txt, or have different tags
    echo ""
    echo "Checking for images in manifests but missing or mismatched in kubeblocks-enterprise.txt..."
    local missing_count=0
    
    # Build a map of image names to tags from txt for tag comparison
    declare -A txt_image_name_to_tag
    for txt_image in "${!txt_images_map[@]}"; do
        local img_name=$(echo "$txt_image" | cut -d':' -f1)
        local img_tag=$(echo "$txt_image" | rev | cut -d':' -f1 | rev)
        txt_image_name_to_tag["$img_name"]="$img_tag"
    done
    
    for manifest_image in "${!manifest_images_map[@]}"; do
        local manifest_img_name=$(echo "$manifest_image" | cut -d':' -f1)
        local manifest_img_tag=$(echo "$manifest_image" | rev | cut -d':' -f1 | rev)
        local module_name="${image_to_module[$manifest_image]}"
        
        # Check if this exact image exists in txt
        if [[ -z "${txt_images_map[$manifest_image]}" ]]; then
            # Image not found with exact match, check if same name but different tag
            if [[ -n "${txt_image_name_to_tag[$manifest_img_name]}" ]]; then
                local txt_tag="${txt_image_name_to_tag[$manifest_img_name]}"
                if [[ "$txt_tag" != "$manifest_img_tag" ]]; then
                    # Tag mismatch
                    check_result_tmp="$(tput -T xterm setaf 1)[${module_name}] Tag mismatch: ${manifest_image}$(tput -T xterm sgr0)"
                    echo "${check_result_tmp}"
                    echo "${check_result_tmp}" >> check_airgap_result
                    echo 1 > exit_result
                    missing_count=$((missing_count + 1))
                fi
            else
                # Completely missing from txt
                check_result_tmp="$(tput -T xterm setaf 1)[${module_name}] Missing: ${manifest_image}$(tput -T xterm sgr0)"
                echo "${check_result_tmp}"
                echo "${check_result_tmp}" >> check_airgap_result
                echo 1 > exit_result
                missing_count=$((missing_count + 1))
            fi
        fi
    done
    
    echo ""
    echo "Summary: Found ${missing_count} images in manifests but missing or mismatched in kubeblocks-enterprise.txt"
    
    # Step 4: Check txt -> manifests (find images in txt but not in manifests)
    echo ""
    echo "Checking for images in kubeblocks-enterprise.txt but not in deploy-manifests.yaml..."
    local obsolete_count=0
    
    for txt_image in "${!txt_images_map[@]}"; do
        # Check if this image exists in manifests
        if [[ -z "${manifest_images_map[$txt_image]}" ]]; then
            # Image not found in manifests - this is a warning, not an error
            check_result_tmp="$(tput -T xterm setaf 3)[Warning] Obsolete in txt: ${txt_image}$(tput -T xterm sgr0)"
            echo "${check_result_tmp}"
            # Write to check_airgap_result but don't set exit code
            echo "${check_result_tmp}" >> check_airgap_result
            obsolete_count=$((obsolete_count + 1))
        fi
    done
    
    echo ""
    echo "Summary: Found ${obsolete_count} images in kubeblocks-enterprise.txt but not in manifests (warnings only)"
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

    # Check kubeblocks-enterprise.txt consistency first
    check_kubeblocks_enterprise_txt

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

        if [[ -n "${SKIP_DELETE_FILE}" && "${chart_name}" != "${SKIP_DELETE_FILE}" ]]; then
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
            chart_version_include=0
            for chart_version_tmp in $(echo "$chart_versions" | sed 's/|/ /g'); do
                if [[ "${chart_version}" == "v"* ]]; then
                    chart_version="${chart_version/v/}"
                fi
                if [[ "${chart_version_tmp}" == "${chart_version}" ]]; then
                    chart_version_include=1
                    break
                fi
                chart_index=$(( $chart_index + 1 ))
            done
            if [[ $chart_version_include -eq 0 && -n "${chart_versions}" ]]; then
                check_result_tmp="$(tput -T xterm setaf 1)Not found ${chart_name} ${chart_version} in manifests ${chart_versions} $(tput -T xterm sgr0)"
                echo "${check_result_tmp}"
                echo "${check_result_tmp}" >> check_airgap_result
            fi
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
