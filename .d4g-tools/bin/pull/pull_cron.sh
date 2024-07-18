#!/usr/bin/env bash
set -Eeuo pipefail

trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
    cat <<EOF
USAGE ${0} --github-token=XXXX-XXX --repository-name=dataforgoodfr/python_template [--branch=main] [--deploy-script=.d4g-tools/deploy/pull/pull.sh] [--lock-location=/tmp/lock] [-v] [-h]

This script will check a repository's status.
If a newer commit exists on the given branch, it will start the deployment script.
This script will report a status on the Github commit, and prevent multiple concurrent deployments.
The only assumption this script makes is that the deploy script will update the local git repository
to the branch HEAD commit.

WARNING : This script does NOT handle traffic stopping, airgap deployments, or any other strategy.
That part is on you to implement in the deploy script.

Supported parameters :
-h, --help : display this message
-v, --verbose : enable enhanced logging
--github-token : Github token to use for API calls. [Required]
--repository-name: : Github repository name. [Required]
--branch : Branch to check for new commits. [Default : main]
--deploy-script : Script to run when a new commit is found. [Default : bin/deploy]
--lock-location : Location of the lock file. [Default : /tmp/deploy_\${repository_name}.lock]
EOF
    exit 1
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    # script cleanup here
    exit 0
}

report_github_status() {
    COMMIT_SHA=$1
    STATUS=$2
    DESCRIPTION=$3
    debug "COMMIT_SHA: $COMMIT_SHA"
    debug "STATUS: $STATUS"
    debug "DESCRIPTION: $DESCRIPTION"
    curl -s -X POST \
        -d "{\"state\": \"${STATUS}\", \"description\": \"$DESCRIPTION\", \"context\": \"deploy\"}" \
        "https://api.github.com/repos/${REPOSITORY_NAME}/statuses/${COMMIT_SHA}" >/dev/null
}

deploy_lock() {
    ACTION=$1
    SHA=$2
    debug "ACTION: $ACTION"
    debug "SHA: $SHA"
    if [ "${ACTION}" == "acquire" ]; then
        if [ -f "$LOCK_LOCATION" ]; then
            error "Deploy lock already exists at $LOCK_LOCATION. Exiting."
            error "$(cat "$LOCK_LOCATION")"
            exit 1
        else
            # Create lock with timestamp and sha as content
            echo "$(date +"%Y-%m-%dT%H:%M:%S%:z") - $SHA" >"$LOCK_LOCATION"
        fi
    elif [ "${ACTION}" == "release" ]; then
        if [ -f "$LOCK_LOCATION" ]; then
            rm "$LOCK_LOCATION"
        else
            error "Deploy lock does not exist. Exiting."
            exit 1
        fi
    else
        error "Invalid action. Exiting."
        exit 1
    fi
}

info() {
    gum style --foreground=4 "$(date +"%Y-%m-%dT%H:%M:%S%:z") $*"
}

warning() {
    gum style --foreground=3 "$(date +"%Y-%m-%dT%H:%M:%S%:z") $*"
}

success() {
    gum style --bold --foreground=2 "$(date +"%Y-%m-%dT%H:%M:%S%:z") $*"
}

error() {
    gum style --bold --foreground=1 "$(date +"%Y-%m-%dT%H:%M:%S%:z") $*"
}

debug() {
    if [ "$DEBUG" == 'true' ]; then
        gum style --faint "$(date +"%Y-%m-%dT%H:%M:%S%:z") $*"
    fi
}

parse_params() {
    # Sane defaults
    DEBUG="false"
    RUN_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
    SOURCE=$(dirname "$RUN_DIR")
    REPOSITORY_NAME=""
    BRANCH="main"
    DEPLOY_SCRIPT="${SOURCE}/pull/pull.sh"

    while :; do
        case "${1-}" in
        -h | --help)
            usage
            ;;
        -v | --verbose)
            DEBUG="true"
            ;;
        --repository-name=*)
            REPOSITORY_NAME="${1#*=}"
            REPO_CANONICAL_NAME=$(echo "$REPOSITORY_NAME" | tr '/' '_')
            LOCK_LOCATION="/tmp/deploy_${REPO_CANONICAL_NAME}.lock"
            ;;
        --branch=*)
            BRANCH="${1#*=}"
            ;;
        --deploy-script=*)
            DEPLOY_SCRIPT="${1#*=}"
            ;;
        --lock-location=*)
            LOCK_LOCATION="${1#*=}"
            ;;
        -?*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            break
            ;;
        esac
        shift
    done

    debug "DEBUG: $DEBUG"
    debug "RUN_DIR: $RUN_DIR"
    debug "REPOSITORY_NAME: $REPOSITORY_NAME"
    debug "BRANCH: $BRANCH"
    debug "DEPLOY_SCRIPT: $DEPLOY_SCRIPT"
    debug "LOCK_LOCATION: $LOCK_LOCATION"

    if [ -z "${REPOSITORY_NAME}" ]; then
        error "Repository name is required."
        usage
    fi

    return 0
}

parse_params "$@"

# Check if a new commit exists
HEAD_COMMIT=$(curl -s "https://api.github.com/repos/${REPOSITORY_NAME}/commits/${BRANCH}" | jq -r '.sha')
LOCAL_COMMIT=$(cd "$SOURCE" && git rev-parse HEAD)

debug "HEAD_COMMIT: $HEAD_COMMIT"
debug "LOCAL_COMMIT: $LOCAL_COMMIT"

if [ "${HEAD_COMMIT}" != "${LOCAL_COMMIT}" ]; then
    info "New commit found. Running deploy script."
    # Acquire deploy lock
    deploy_lock acquire "$HEAD_COMMIT"
    report_github_status "$HEAD_COMMIT" "pending" "Deployment in progress."
    # Measure time taken to deploy
    START_TIME=$(date +%s)
    ${DEPLOY_SCRIPT}
    END_TIME=$(date +%s)
    DEPLOY_TIME=$((END_TIME - START_TIME))
    # get deploy script exit code
    DEPLOY_EXIT_CODE=$?
    if [ $DEPLOY_EXIT_CODE -eq 0 ]; then
        report_github_status "$HEAD_COMMIT" "success" "Deployment successful."
        deploy_lock release "$HEAD_COMMIT"
        success "Deployment successful, took ${DEPLOY_TIME}s 🚀."
    else
        report_github_status "$HEAD_COMMIT" "failure"
        deploy_lock release "$HEAD_COMMIT" "Deployment failed."
        error "An error occurred while deploying. Exiting."
        exit 1
    fi
else
    success "No new commit found. Exiting."
fi

cleanup
