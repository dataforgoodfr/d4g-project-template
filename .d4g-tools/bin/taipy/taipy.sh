#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC1090

RUN_DIR="$(dirname "${BASH_SOURCE[0]}")"
# IMPORTANT AND NECESSARY: Load common functions
source "$LIB_DIR"/common.sh

parse_params() {
    if [ $# -gt 3 ]; then
        echo "Too many parameters provided"
        usage
    fi

    PROD="false"
    PORT="false"

    while :; do
        case "${1-}" in
        --prod=*)
            PROD="${1#*=}"
            ;;
        --port=*)
            PORT="${1#*=}"
            echo "Running on port $PORT"
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

# Check if the virtual environment exists in the project directory
if [ ! -d "$VENV_DIR" ]; then
    echo "Virtual environment not found in project directory!"
    exit 1
fi

# Update the package lists for upgrades and new package installations
sudo apt update -y &>/dev/null
# Ensure necessary dependencies are installed
sudo apt install build-essential python3-dev libssl-dev &>/dev/null

# Activate the virtual environment
source "$VENV_DIR"/bin/activate
# Install uwsgi and gevent using pip
pip install uwsgi gevent >/dev/null 2>&1
# not recommended: asyncio greenlet
# Deactivate the virtual environment
deactivate

#--http-socket :$APP_PORT
UWSGI_SERVICE="$PROJECT_NAME.$STAGE.uwsgi.service"
# Generate a Systemd file for uWSGI
echo """
[Unit]
Description=$PROJECT_NAME UWSGI Server
After=syslog.target

[Service]
ExecStart=$VENV_DIR/bin/uwsgi --ini .d4g-tools/bin/taipy/uwsgi.ini:$STAGE --socket /tmp/$PROJECT_NAME.$STAGE.uwsgi.sock --module $PROJECT_NAME.main:web_app
# ExecStart=$VENV_DIR/bin/uwsgi --ini .d4g-tools/bin/taipy/uwsgi.ini:$STAGE --http-socket :$APP_PORT
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

# if [ "$PROD" == "true" ]; then

# Move the Systemd file to the correct directory
sudo cp "$GENERATED/$UWSGI_SERVICE" "/etc/systemd/system/$UWSGI_SERVICE"
sudo systemctl daemon-reload

# Start the uWSGI service
sudo systemctl restart "$UWSGI_SERVICE"

# Enable the uWSGI service to start on boot
# sudo systemctl enable "$UWSGI_SERVICE"

# Check if nginx is installed, if not then install it
if ! command -v nginx &>/dev/null; then
    sudo apt install -y nginx
fi
# Create a self-signed SSL certificate
# sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/certs/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -sha256 -days 3650 -nodes -subj "/CN=localhost"
# Update the Nginx configuration to expose the application

NGINX_CONF="$PROJECT_NAME.$STAGE.nginx.conf"

if [ "$PROD" == "false" ]; then
    echo """
    server {
        listen $HTTP_PORT;
        #listen 443 ssl;

        server_name localhost;

        # SECURITY HEADERS
        add_header 'X-Frame-Options' 'SAMEORIGIN';
        add_header 'X-XSS-Protection' '1; mode=block';
        add_header 'X-Content-Type-Options' 'nosniff';
        add_header 'Referrer-Policy' 'same-origin';
        add_header 'Strict-Transport-Security' 'max-age=63072000';

        #ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
        #ssl_certificate_key /etc/ssl/certs/nginx-selfsigned.key;

        # location / {
        #     include proxy_params;
        #     proxy_set_header Upgrade \$http_upgrade;
        #     proxy_set_header Connection 'upgrade';
        #     proxy_set_header Host \$host;
        #     proxy_set_header X-Forwarded-Host \$host;
        #     proxy_pass http://localhost:$APP_PORT;
        # }

        location / {
            include uwsgi_params
            uwsgi_pass unix:/tmp/$PROJECT_NAME.$STAGE.uwsgi.sock;
        }

    }""" | sudo tee "$GENERATED/$NGINX_CONF"

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

fi

cleanup
