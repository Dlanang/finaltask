#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Stop and remove old container if exists
if [ "$(docker ps -aq -f name=monitoring_allinone)" ]; then
    echo "[+] Stopping and removing existing container..."
    docker stop monitoring_allinone
    docker rm monitoring_allinone
fi

echo "[+] Building all-in-one monitoring image..."
docker build -t monitoring_app -f Dockerfile .

echo "[+] Running container with host networking..."
docker run -d \
  --name monitoring_allinone \
  --network="host" \
  --privileged \
  -v "$(pwd)/docker/php:/var/www/html" \
  -v "$(pwd)/docker/nginx/default.conf:/etc/nginx/conf.d/default.conf" \
  -v "$(pwd)/docker/streamlit:/opt/app" \
  -v "$(pwd)/db:/db" \
  -v "$(pwd)/suricata_logs:/var/log/suricata" \
  -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
  -v "$(pwd)/certbot/www:/var/www/certbot" \
  monitoring_app

# Wait for Nginx to be ready
echo "[+] Waiting for Nginx to start..."
sleep 10

# Run Certbot to obtain SSL certificate
echo "[+] Running Certbot to obtain SSL certificate..."
docker exec monitoring_allinone certbot certonly --webroot -w /var/www/certbot -d ${DOMAIN} --email ${CERTBOT_EMAIL} --rsa-key-size 4096 --agree-tos --noninteractive --force-renewal

# Reload Nginx to apply SSL certificate
echo "[+] Reloading Nginx to apply SSL certificate..."
docker exec monitoring_allinone nginx -s reload

echo "[+] Done!"
echo "Access Nginx/PHP at: http://${DOMAIN}:80 (will redirect to HTTPS)"
echo "Access Streamlit at: https://${DOMAIN}"
