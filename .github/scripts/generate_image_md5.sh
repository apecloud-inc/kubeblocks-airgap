#!/usr/bin/env bash
# nohup bash upload_image_md5.sh > upload_image_md5.log &

set +e
set -o nounset

CHECKSUM_MD5=${1:-"checksums.md5"}
IMAGES_PATH=${2:-".github/images"}
OSS_URL=""
OSS_URL_ARM64=""

generate_checksums_md5() {
    if [[ ! -d "${IMAGES_PATH}" ]]; then
        echo echo "$(tput -T xterm setaf 1)${IMAGES_PATH} dir not found$(tput -T xterm sgr0)"
        return
    fi

    rm -rf ${CHECKSUM_MD5}
    touch ${CHECKSUM_MD5}

    for image_file in $(find ${IMAGES_PATH} -name "*.txt"|sort -V); do
        check_flag=0
        image_file_name=$(basename ${image_file})
        case ${image_file_name} in
            calico.txt|chaos-mesh.txt|dify.txt|gemini.txt|k3s.txt|\
            kata.txt|kubeblocks.txt|kubeblocks-cloud.txt|kubechat.txt\
            |kubernetes.txt|nvidia-device-plugin.txt|pv-migrate.txt|\
            starrocks-3.2.2.txt|starrocks-3.3.0.txt|starrocks-3.3.2.txt|\
            starrocks-3.3.3.txt|starrocks-3.4.1.txt|xinference-cpu.txt|xinference-gpu.txt)
                check_flag=1
            ;;
            mysql.txt|mongodb.txt|damengdb.txt|elasticsearch.txt)
                check_flag=2
            ;;
        esac

        if [[ -z "${image_file}" || $check_flag -eq 1 ]]; then
            continue
        fi
        image_md5=""
        image_arm_md5=""
        if [[ "${image_file}" == *"-arm.txt" ]]; then
            image_tmp=$(cat ${image_file}|head -1|awk '{print $2"-arm-"$3}')
            image_arm="${image_tmp}-arm64.tar.gz"
            image_md5=""
            image_arm_md5="${image_arm}.md5"
        elif [[ $check_flag -eq 2 ]]; then
            image_tmp=$(cat ${image_file}|head -1|awk '{print $2"-"$3}')
            image="${image_tmp}.tar.gz"
            image_md5="${image}.md5"
            image_arm_md5=""
        else
            image_tmp=$(cat ${image_file}|head -1|awk '{print $2"-"$3}')
            image="${image_tmp}.tar.gz"
            image_arm="${image_tmp}-arm64.tar.gz"
            image_md5="${image}.md5"
            image_arm_md5="${image_arm}.md5"
        fi

        if [[ -z "${image_md5}" ]]; then
            OSS_URL=""
        else
            OSS_URL="oss://kubeblocks-oss/images/${image_md5}"
        fi

        if [[ -z "${image_arm_md5}" ]]; then
            OSS_URL_ARM64=""
        else
            OSS_URL_ARM64="oss://kubeblocks-oss/images/arm64/${image_arm_md5}"
        fi

        for index in {1..2}; do
            # check image md5 exists
            OSS_MD5_URL="${OSS_URL}"
            image_md5_tmp="${image_md5}"
            if [[ $index -eq 2 ]]; then
                OSS_MD5_URL="${OSS_URL_ARM64}"
                image_md5_tmp="${image_arm_md5}"
            fi

            if [[ -z "${OSS_MD5_URL}" ]]; then
                continue
            fi

            check_exists=0
            for i in {1..5}; do
                md5_stat_info=$(ossutilmac64 stat "${OSS_MD5_URL}")
                md5_stat_ret=$?
                if [[ "${md5_stat_info}" == *"404"* && "${md5_stat_info}" == *"The specified key does not exist."*  ]]; then
                    echo "$(tput -T xterm setaf 1)${image_md5_tmp} does not exist$(tput -T xterm sgr0)"
                    check_exists=2
                elif [[ $md5_stat_ret -eq 0 && "${md5_stat_info}" == *"Etag"* ]]; then
                    echo "$(tput -T xterm setaf 2)${image_md5_tmp} exist$(tput -T xterm sgr0)"
                    check_exists=1
                fi

                if [[ $check_exists -ne 0 ]]; then
                    break
                fi
                sleep 1
            done

            if [[ $check_exists -eq 2 ]]; then
                continue
            fi

            echo "download ${image_md5_tmp} ..."
            for i in {1..5}; do
                ossutilmac64 cp -rf ${OSS_MD5_URL} ./
                download_ret=$?
                if [[ $download_ret -eq 0 && -f ${image_md5_tmp} ]]; then
                    echo "$(tput -T xterm setaf 2)download ${image_md5_tmp} success$(tput -T xterm sgr0)"
                    cat ${image_md5_tmp} >> ${CHECKSUM_MD5}
                    rm -rf ${image_md5_tmp}
                    break
                else
                    rm -rf ${image_md5_tmp}*
                fi
                sleep 1
            done
        done
    done
}

upload_checksums_md5() {
    if [[ ! -d "${IMAGES_PATH}" ]]; then
        return
    fi

    cat ${CHECKSUM_MD5}
    if [[ ! -s ${CHECKSUM_MD5} ]]; then
        echo "$(tput -T xterm setaf 1)${CHECKSUM_MD5} is empty$(tput -T xterm sgr0)"
        return
    fi
    OSS_MD5_URL="oss://kubeblocks-oss/images/md5/${CHECKSUM_MD5}"
    for i in {1..5}; do
        echo "upload ${CHECKSUM_MD5} ..."
        ossutilmac64 cp -rf ${CHECKSUM_MD5} ${OSS_MD5_URL}
        upload_ret=$?
        if [[ $upload_ret -eq 0 ]]; then
            echo "$(tput -T xterm setaf 2)upload ${CHECKSUM_MD5} success$(tput -T xterm sgr0)"
            break
        fi
        sleep 1
    done
}

generate_checksums_md5
upload_checksums_md5
