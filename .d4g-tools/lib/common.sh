#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
# shellcheck disable=SC2034

set -Eeuo pipefail

# IMPORTANT AND NECESSARY: Load dependencies
source "$LIB_DIR"/depends.sh

# cleanup on exit
cleanup() {
    trap - SIGINT SIGTERM SIGQUIT EXIT
    # script cleanup here
    exit 0
}

# Handle error on signal ERR
err() {
    error "Error occurred in $0: line $1"
    error "$(awk 'NR>L-1 && NR<L+1 { printf "%-5d%3s%s\n",NR,(NR==L?">>> ":""),$0 }' L="$1" "$0")"
}

# Trap cleanup and err functions, signals
trap 'err "${LINENO}"' ERR
trap cleanup SIGINT SIGTERM SIGQUIT EXIT

# Function to check if a command is available
command_exists() {
    command -v "$1" &>/dev/null
}

setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOCOLOR='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOCOLOR='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}
# Actually set colors
setup_colors

info() {
    echo -e "${GREEN}[INFO] $*${NOCOLOR}"
}

warning() {
    echo -e "${YELLOW}[WARN] $*${NOCOLOR}"
}

error() {
    echo -e "${RED}[ERROR] $*${NOCOLOR}" >&2
}

debug() {
    if [ "$DEBUG" == 'true' ]; then
        echo -e "${BLUE}[DEBUG] $*${NOCOLOR}"
    fi
}

# TODO: should we use gum (see depends.sh)
# info() {
#     gum style --foreground=4 "$(date +"%Y-%m-%dT%H:%M:%S%:z") $*"
# }

# warning() {
#     gum style --foreground=3 "$(date +"%Y-%m-%dT%H:%M:%S%:z") $*"
# }

# success() {
#     gum style --bold --foreground=2 "$(date +"%Y-%m-%dT%H:%M:%S%:z") $*"
# }

# error() {
#     gum style --bold --foreground=1 "$(date +"%Y-%m-%dT%H:%M:%S%:z") $*"
# }

# debug() {
#     if [ "$DEBUG" == 'true' ]; then
#         gum style --faint "$(date +"%Y-%m-%dT%H:%M:%S%:z") $*"
#     fi
# }

declare case_sensitive_sections=true
declare case_sensitive_keys=true
declare show_config_warnings=false
declare show_config_errors=true

source "$LIB_DIR"/ini_parser.sh
source "$LIB_DIR"/utils.sh

# Function to read ini file located in $PROJECT_DIR
read_ini() {
    debug "Reading INI file: $1"
    process_ini_file "$1"
    export_config_to_env "default"
    display_config_by_section "default"
    export_config_to_env "dev"
    display_config_by_section "dev"
}

if [ -z "${INI_FILE}" ]; then
    error "INI file 'd4g.ini' not found"
    exit 1
fi

if [ -z "$D4G" ]; then

    read_ini "$INI_FILE"

    export D4G="true"
fi
