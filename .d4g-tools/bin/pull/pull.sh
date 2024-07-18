#!/usr/bin/env bash
set -Eeuo pipefail

trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
  cat <<EOF
USAGE ${0} [-v] [-h]

Deploy the legislatives-2024-circos application.
This script merely pulls the repository updates, builds the Docker image and starts the application.
This script is meant to be invoked by bin/deploy_cron

Supported parameters :
-h, --help : display this message
-v, --verbose : enable enhanced logging
EOF
  exit 1
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
  exit 0
}

info() {
  gum style --foreground=4 "$@"
}

warning() {
  gum style --foreground=3 "$@"
}

success() {
  gum style --bold --foreground=2 "$@"
}

error() {
  gum style --bold --foreground=1 "$@"
}

debug() {
  if [ "$DEBUG" == 'true' ]; then
    gum style --faint "$@"
  fi
}

parse_params() {
  # Sane defaults
  DEBUG="false"
  RUN_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
  SOURCE=$(dirname "$RUN_DIR")

  while :; do
    case "${1-}" in
    -h | --help)
      usage
      ;;
    -v | --verbose | --debug)
      DEBUG="true"
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

sudo /bin/systemctl stop taxplorer-dev.uwsgi.service
cd "$SOURCE" && git pull
sudo /bin/systemctl start taxplorer-dev.uwsgi.service

exit 0
