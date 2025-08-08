#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Default values
DOMAIN=${DOMAIN:-suricata.dhimaslanangnugroho.my.id}
CERTBOT_EMAIL=${CERTBOT_EMAIL:-your-email@example.com}
ENABLE_CERTBOT=${ENABLE_CERTBOT:-false}

CONTAINER_NAME="monitoring_allinone"

# --- Step 1: Ensure Certbot directories exist on host ---
mkdir -p certbot/conf/live/${DOMAIN}
mkdir -p certbot/conf/accounts
mkdir -p certbot/www

# --- Step 2: Stop and remove existing Docker Compose services ---
if docker-compose ps -q app &>/dev/null; then
    echo "[+] Stopping and removing existing Docker Compose services..."
    docker-compose down --remove-orphans
fi

# --- Step 3: Prepare SSL certificates (Certbot or self-signed) ---
SSL_CERT_PATH="certbot/conf/live/${DOMAIN}/fullchain.pem"
SSL_KEY_PATH="certbot/conf/live/${DOMAIN}/privkey.pem"

if [ "$ENABLE_CERTBOT" = "true" ]; then
    echo "[+] Attempting to obtain SSL certificate with Certbot..."
    # Temporarily start Nginx with webroot for Certbot challenge
    docker run -d \
        --name ${CONTAINER_NAME}_temp_nginx \
        -p 80:80 \
        -v "$(pwd)/certbot/www:/var/www/certbot" \
        -v "$(pwd)/docker/nginx/nginx_certbot_temp.conf:/etc/nginx/conf.d/default.conf" \
        nginx:latest

    sleep 5 # Give Nginx time to start

    CERTBOT_OUTPUT=$(docker run --rm \
        -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
        -v "$(pwd)/certbot/www:/var/www/certbot" \
        certbot/certbot \
        certonly --webroot -w /var/www/certbot -d ${DOMAIN} --email ${CERTBOT_EMAIL} --rsa-key-size 4096 --agree-tos --noninteractive --force-renewal 2>&1)
    echo "${CERTBOT_OUTPUT}"

    docker stop ${CONTAINER_NAME}_temp_nginx
    docker rm ${CONTAINER_NAME}_temp_nginx

    if [ -f "${SSL_CERT_PATH}" ]; then
        echo "[+] Certbot certificate obtained successfully."
        USE_HTTPS_DOMAIN=true
    else
        echo "[!] Certbot failed. Falling back to self-signed certificate."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${SSL_KEY_PATH} -out ${SSL_CERT_PATH} -subj "/CN=${DOMAIN}"
        USE_HTTPS_DOMAIN=false
    fi
else
    echo "[+] Generating self-signed SSL certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${SSL_KEY_PATH} -out ${SSL_CERT_PATH} -subj "/CN=${DOMAIN}"
    USE_HTTPS_DOMAIN=false
fi

# --- Step 4: Prepare Suricata Host System Setup Scripts ---
echo "[+] Preparing Suricata host system setup scripts..."

# Create start_suricata.sh
cat << EOF > start_suricata.sh
#!/bin/bash

# Detect the primary network interface
INTERFACE=$(ip route get 1.1.1.1 | awk '{print $5}' | head -n 1)

if [ -z "$INTERFACE" ]; then
    echo "Error: Could not detect network interface. Please specify it manually." >&2
    exit 1
fi

echo "Detected network interface: $INTERFACE"

exec /usr/bin/suricata -c /etc/suricata/suricata.yaml -i "$INTERFACE" --user suricata --group suricata --pidfile /run/suricata.pid
EOF
chmod +x start_suricata.sh

# Create suricata.service
cat << EOF > suricata.service
[Unit]
Description=Suricata Intrusion Detection System
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/start_suricata.sh
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/run/suricata.pid
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Create setup_suricata_host.sh
cat << EOF > setup_suricata_host.sh
#!/bin/bash

# This script automates the setup of Suricata on the host system.
# It should be run with sudo privileges.

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo: sudo ./setup_suricata_host.sh"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[+] Starting Suricata host setup automation..."

# 1. Copy and make executable the Suricata start script
echo "[+] Copying start_suricata.sh to /usr/local/bin/"
cp "$PROJECT_DIR/start_suricata.sh" /usr/local/bin/
chmod +x /usr/local/bin/start_suricata.sh

# 2. Copy the Suricata systemd service file
echo "[+] Copying suricata.service to /etc/systemd/system/"
cp "$PROJECT_DIR/suricata.service" /etc/systemd/system/

# 3. Reload systemd, enable, and start Suricata
echo "[+] Reloading systemd daemon..."
systemctl daemon-reload

echo "[+] Enabling Suricata service..."
systemctl enable suricata

echo "[+] Starting Suricata service..."
systemctl start suricata

echo "[+] Checking Suricata service status..."
systemctl status suricata

echo "[+] Suricata host setup automation complete. Please verify the status above."
EOF
chmod +x setup_suricata_host.sh

echo "[!] IMPORTANT: To complete Suricata setup on your host system, please run the following command:"
echo "   sudo ./setup_suricata_host.sh"
echo "After running the above, ensure Suricata is running and generating logs in 'suricata_logs/'"

# --- Step 5: Build Docker Compose services ---
echo "[+] Building Docker Compose services..."
docker-compose build

# --- Step 6: Run Docker Compose services ---
echo "[+] Starting Docker Compose services..."
docker-compose up -d

# --- Step 7: Final access instructions ---
echo "[+] Done!"
if [ "$USE_HTTPS_DOMAIN" = "true" ]; then
    echo "Access Streamlit at: https://${DOMAIN}"
else
    echo "Access Streamlit at: https://localhost (accept self-signed certificate warning)"
fi