#!/bin/bash

echo "[+] Building all-in-one monitoring image..."
docker build -t monitoring_app -f docker/Dockerfile .

echo "[+] Running container..."
docker run -d \
  --name monitoring_container \
  -p 80:80 \
  -p 8501:8501 \
  -v "$(pwd)/db:/app/db" \
  -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
  -v "$(pwd)/certbot/www:/var/www/certbot" \
  monitoring_app
