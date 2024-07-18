#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090

set -Eeuo pipefail

RUN_DIR="$(dirname "${BASH_SOURCE[0]}")"
# IMPORTANT AND NECESSARY: Load common functions
source "$LIB_DIR"/common.sh

# Create a self-signed SSL certificate
# sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/certs/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -sha256 -days 3650 -nodes -subj "/CN=localhost"
# Update the Nginx configuration to expose the application

NGINX_CONF="$PROJECT_NAME.$STAGE.nginx.conf"

if [ ! -f "$GENERATED/$NGINX_CONF" ]; then
    error "Missing $GENERATED/$NGINX_CONF"
    exit 1
fi

# Check if nginx is installed, if not then install it
if ! command -v nginx &>/dev/null; then
    info "Installing nginx..."
    # TODO use brew?
    sudo apt install -y nginx
fi

sudo systemctl stop nginx

# Format the date as YYYYMMDDHHMM
date=$(date +"%Y%m%d")

nginx_sites_available="/etc/nginx/sites-available"
nginx_sites_enabled="/etc/nginx/sites-enabled"

if [ -f "$nginx_sites_available/$PROJECT_NAME" ]; then
    sudo mv "$nginx_sites_available/$PROJECT_NAME" "$nginx_sites_available/$PROJECT_NAME.$date.bak"
fi
sudo cp "$GENERATED/$NGINX_CONF" "$nginx_sites_available/$PROJECT_NAME"

default_link="$nginx_sites_enabled/default"
if [ -L "${default_link}" ]; then
    rm "$default_link"
fi

sudo ln -fs "$nginx_sites_available/$PROJECT_NAME" "$nginx_sites_enabled/$PROJECT_NAME"

# Restart Nginx to apply the changes
sudo systemctl start nginx

echo "GOOD JOB, YOU ARE NOW RUNNING THE APP IN DEV MODE that mimics production."
echo "Running services:"

echo "VISIT http://$DOMAIN:$HTTP_PORT via installed nginx proxy "
# echo "   or http://$DOMAIN:$APP_PORT, directly via installed uwsgi server"

cleanup
