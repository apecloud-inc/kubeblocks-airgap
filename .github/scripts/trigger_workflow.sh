#!/usr/bin/env bash

set -o nounset

DEFAULT_DELETE_FORCE="false"
REGISTRY_DEFAULT=docker.io

show_help() {
cat << EOF
Usage: $(basename "$0") <options>

    -h, --help                Display help
    -gr, --github-repo        Github Repo
    -gt, --github-token       Github token
    -bn, --branch-name        The branch name that triggers the workflow
    -wi, --workflow-id        The workflow id that triggers the workflow
    -v, --version             Release version
    -ea, --extra-args         The extra args for workflow
EOF
}

GITHUB_API="https://api.github.com"
DEFAULT_GITHUB_REPO=apecloud-inc/kubeblocks-airgap

gh_curl() {
    if [[ -z "$GITHUB_TOKEN" ]]; then
        curl -H "Accept: application/vnd.github.v3.raw" \
            $@
    else
        curl -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3.raw" \
            $@
    fi
}

trigger_repo_workflow() {
    data='{"ref":"'$BRANCH_NAME'"}'
    if [[ -n "$EXTRA_ARGS" ]]; then
        extra_args_json=""
        if [[ -n "$VERSION" ]]; then
            extra_args_json="\"VERSION\":\"$VERSION\""
        fi
        for extra_arg in $(echo "$EXTRA_ARGS" | sed 's/#/ /g'); do
            extra_arg_key=${extra_arg%=*}
            extra_arg_value=${extra_arg#*=}
            if [[ -n "$extra_args_json" ]]; then
                extra_args_json="$extra_args_json,\"$extra_arg_key\":\"$extra_arg_value\""
            else
                extra_args_json="\"$extra_arg_key\":\"$extra_arg_value\""
            fi
        done
        if [[ -n "$BRANCH_NAME" ]]; then
            data='{"ref":"'$BRANCH_NAME'","inputs":{'$extra_args_json'}}'
        else
            data='{"ref":"main","inputs":{'$extra_args_json'}}'
        fi
    elif [[ -n "$VERSION" ]]; then
        if [[ -n "$BRANCH_NAME" ]]; then
            data='{"ref":"'$BRANCH_NAME'","inputs":{"VERSION":"'$VERSION'"}}'
        else
            data='{"ref":"main","inputs":{"VERSION":"'$VERSION'"}}'
        fi
    fi
    echo "data:"$data
    for workflowId in $(echo "${WORKFLOW_ID}" | sed 's/|/ /g'); do
        gh_curl -X POST \
            $GITHUB_API/repos/$GITHUB_REPO/actions/workflows/${workflowId}/dispatches \
            -d $data
    done
}

parse_command_line() {
    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
            ;;
            -gr|--github-repo)
                if [[ -n "${2:-}" ]]; then
                    GITHUB_REPO="$2"
                    shift
                fi
            ;;
            -gt|--github-token)
                if [[ -n "${2:-}" ]]; then
                    GITHUB_TOKEN="$2"
                    shift
                fi
            ;;
            -bn|--branch-name)
                if [[ -n "${2:-}" ]]; then
                    BRANCH_NAME="$2"
                    shift
                fi
            ;;
            -wi|--workflow-id)
                if [[ -n "${2:-}" ]]; then
                    WORKFLOW_ID="$2"
                    shift
                fi
            ;;
            -v|--version)
                if [[ -n "${2:-}" ]]; then
                    VERSION="$2"
                    shift
                fi
            ;;
            -ea|--extra-args)
                EXTRA_ARGS="$2"
                shift
            ;;
            *)
                break
            ;;
        esac

        shift
    done
}

main() {
    local GITHUB_REPO="$DEFAULT_GITHUB_REPO"
    local GITHUB_TOKEN=""
    local BRANCH_NAME="main"
    local WORKFLOW_ID=""
    local VERSION=""
    local DELETE_FORCE=$DEFAULT_DELETE_FORCE
    local EXTRA_ARGS=""
    local UNAME="$(uname -s)"

    parse_command_line "$@"

    trigger_repo_workflow
}

main "$@"
