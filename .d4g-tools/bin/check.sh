#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
set -Eeuo pipefail

# Folder containing this script
RUN_DIR="$(dirname "${BASH_SOURCE[0]}")"
SELF_PATH="$(basename "${BASH_SOURCE[0]}")"
echo "RUN_DIR: $RUN_DIR"
echo "SELF_PATH: $SELF_PATH"
# IMPORTANT AND NECESSARY: Load common functions
source "$LIB_DIR"/common.sh

source "$VENV_DIR"/bin/activate

# Array of services to check
services=("nginx" "apache2" "uwsgi")

# Loop through the services
for service in "${services[@]}"; do
    # Check if the service is installed
    if dpkg -l | grep -q "$service"; then
        echo "$service is installed."

        # Print the service's binary location
        bin_location=$(which "$service")
        info "Binary location for $service: $bin_location"

        # Print the port the service uses
        if [ "$service" == "nginx" ] || [ "$service" == "apache2" ]; then
            port=$(sudo lsof -i -P -n | grep "$service" | awk '{print $9}' | cut -d: -f2)
            echo "Port for $service: $port"
        elif [ "$service" == "uwsgi" ]; then
            echo "uwsgi does not listen on a port. It is a protocol implemented over TCP."
        fi
    else
        echo "$service is not installed."
    fi
done
deactivate
cleanup
