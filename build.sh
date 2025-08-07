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

# --- Step 1: Ensure Certbot directories exist on host 
# (Moved this section up to ensure directories exist before potential container removal)
mkdir -p certbot/conf/live/${DOMAIN}
mkdir -p certbot/conf/accounts
mkdir -p certbot/www

# --- Step 2: Stop and remove old container if exists ---
if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
    echo "[+] Stopping and removing existing container..."
    docker stop ${CONTAINER_NAME}
    docker rm ${CONTAINER_NAME}
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
        -v "$(pwd)/certbot/conf/nginx_certbot_temp.conf:/etc/nginx/conf.d/default.conf" \
        nginx:latest

    sleep 5 # Give Nginx time to start

    docker run --rm \
        -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
        -v "$(pwd)/certbot/www:/var/www/certbot" \
        certbot/certbot \
        certonly --webroot -w /var/www/certbot -d ${DOMAIN} --email ${CERTBOT_EMAIL} --rsa-key-size 4096 --agree-tos --noninteractive --force-renewal

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

# --- Step 4: Build Docker image ---
echo "[+] Building all-in-one monitoring image..."
docker build -t monitoring_app -f Dockerfile .

# --- Step 5: Run main container with network mode fallback ---
NETWORK_MODE="host"
RUN_COMMAND="docker run -d --name ${CONTAINER_NAME} --network=\"${NETWORK_MODE}\" --privileged -v \"$(pwd)/docker/php:/var/www/html\" -v \"$(pwd)/docker/nginx/default.conf:/etc/nginx/conf.d/default.conf\" -v \"$(pwd)/docker/streamlit:/opt/app\" -v \"$(pwd)/db:/db\" -v \"$(pwd)/suricata_logs:/var/log/suricata\" -v \"$(pwd)/certbot/conf:/etc/letsencrypt\" -v \"$(pwd)/certbot/www:/var/www/certbot\" monitoring_app"

echo "[+] Attempting to run container with ${NETWORK_MODE} networking..."
if ! eval ${RUN_COMMAND}; then
    echo "[!] ${NETWORK_MODE} networking failed. Falling back to bridge networking."
    NETWORK_MODE="bridge"
    RUN_COMMAND="docker run -d --name ${CONTAINER_NAME} -p 80:80 -p 443:443 -p 8502:8502 --privileged -v \"$(pwd)/docker/php:/var/www/html\" -v \"$(pwd)/docker/nginx/default.conf:/etc/nginx/conf.d/default.conf\" -v \"$(pwd)/docker/streamlit:/opt/app\" -v \"$(pwd)/db:/db\" -v \"$(pwd)/suricata_logs:/var/log/suricata\" -v \"$(pwd)/certbot/conf:/etc/letsencrypt\" -v \"$(pwd)/certbot/www:/var/www/certbot\" monitoring_app"
    eval ${RUN_COMMAND}
fi

# --- Step 6: Wait for Nginx and reload ---
echo "[+] Waiting for Nginx to start..."
sleep 10

echo "[+] Reloading Nginx to apply SSL certificate..."
docker exec ${CONTAINER_NAME} nginx -s reload

# --- Step 7: Final access instructions ---
echo "[+] Done!"
if [ "$NETWORK_MODE" = "host" ]; then
    if [ "$USE_HTTPS_DOMAIN" = "true" ]; then
        echo "Access Nginx/PHP at: http://${DOMAIN}:80 (will redirect to HTTPS)"
        echo "Access Streamlit at: https://${DOMAIN}"
    else
        echo "Access Nginx/PHP at: http://${DOMAIN}:80 (will redirect to HTTPS, self-signed cert)"
        echo "Access Streamlit at: https://${DOMAIN} (accept self-signed certificate warning)"
    fi
else
    echo "Access Nginx/PHP at: http://localhost:80 (will redirect to HTTPS)"
    echo "Access Streamlit at: https://localhost:443 (accept self-signed certificate warning)"
fi
