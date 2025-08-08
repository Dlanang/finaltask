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

# --- Step 4: Build Docker Compose services ---
echo "[+] Building Docker Compose services..."
docker-compose build

# --- Step 5: Run Docker Compose services ---
echo "[+] Starting Docker Compose services..."
docker-compose up -d

# --- Step 6: Final access instructions ---
echo "[+] Done!"
if [ "$USE_HTTPS_DOMAIN" = "true" ]; then
    echo "Access Streamlit at: https://${DOMAIN}"
else
    echo "Access Streamlit at: https://localhost (accept self-signed certificate warning)"
fi