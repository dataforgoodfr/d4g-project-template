#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
# shellcheck disable=SC2034

set -Eeuo pipefail

# IMPORTANT AND NECESSARY: Load dependencies
source "$LIB_DIR"/common.sh

usage() {
    cat <<EOF
USAGE ${0} [-v] [-h]

This is a description of the script.
Honestly, write whatever you want.

Supported parameters :
-h, --help : display this message
-v, --verbose : enable enhanced logging
EOF
    exit 1
}

parse_params() {
    if [ $# -gt 2 ]; then
        echo "Too many parameters provided"
        usage
    fi

    # Sane defaults
    DEBUG="false"
    RUN_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

    while :; do
        case "${1-}" in
        -h | --help)
            usage
            ;;
        -v | --verbose)
            DEBUG="true"
            ;;
        --dummy-flag*)
            DUMMY_FLAG="true"
            ;;
        --dummy-param=*)
            DUMMY_PARAM="${1#*=}"
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

    return 0
}

parse_params "$@"

if ! command_exists "docker"; then
    brew install docker
fi

echo -n "Ready to rumble."
