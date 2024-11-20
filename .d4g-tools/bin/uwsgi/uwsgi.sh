#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090

set -Eeuo pipefail

RUN_DIR="$(dirname "${BASH_SOURCE[0]}")"
# IMPORTANT AND NECESSARY: Load common functions
source "$LIB_DIR"/common.sh

# Check if the virtual environment exists in the project directory
if [ ! -d "$VENV_DIR" ]; then
    echo "Virtual environment not found in project directory!"
    exit 1
fi

# Update the package lists for upgrades and new package installations
sudo apt update -y >/dev/null 2>&1
# Ensure necessary dependencies are installed
sudo apt install build-essential python3-dev libssl-dev >/dev/null 2>&1

# Activate the virtual environment
source "$VENV_DIR"/bin/activate
# Install uwsgi and gevent using pip
pip install uwsgi gevent >/dev/null 2>&1
# not recommended: asyncio greenlet
# Deactivate the virtual environment
deactivate

#--http-socket :$APP_PORT
UWSGI_SERVICE="$PROJECT_NAME.$STAGE.uwsgi.service"
# Stop the uWSGI service
sudo systemctl stop "$UWSGI_SERVICE" &>/dev/null

# Generate a Systemd file for uWSGI
echo """
[Unit]
Description=$PROJECT_NAME UWSGI Server
After=syslog.target

[Service]
ExecStart=$VENV_DIR/bin/uwsgi --ini $BIN_DIR/uwsgi/uwsgi.ini:$STAGE --socket /tmp/$PROJECT_NAME.$STAGE.uwsgi.sock --module $PROJECT_NAME.main:web_app
WorkingDirectory=$PROJECT_DIR
Restart=always
KillSignal=SIGINT
Type=notify
StandardError=syslog
NotifyAccess=all
User=$(whoami)

[Install]
WantedBy=multi-user.target
""" >"$GENERATED/$UWSGI_SERVICE"

# Move the Systemd file to the correct directory
sudo cp "$GENERATED/$UWSGI_SERVICE" "/etc/systemd/system/$UWSGI_SERVICE"
sudo systemctl daemon-reload

# Start the uWSGI service
sudo systemctl start "$UWSGI_SERVICE"

# Enable the uWSGI service to start on boot
# sudo systemctl enable "$UWSGI_SERVICE"

# Create a self-signed SSL certificate
# sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/certs/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -sha256 -days 3650 -nodes -subj "/CN=localhost"
# Update the Nginx configuration to expose the application

NGINX_CONF="$PROJECT_NAME.$STAGE.nginx.conf"

if [ "$PROD" == "false" ]; then
    echo """
    server {
        listen $HTTP_PORT;
        server_name $DOMAIN;

        location / {
            include uwsgi_params
            uwsgi_pass unix:/tmp/$PROJECT_NAME.$STAGE.uwsgi.sock;
        }

    }""" | sudo tee "$GENERATED/$NGINX_CONF"

    "$BIN_DIR"/nginx/nginx.sh
fi

cleanup
