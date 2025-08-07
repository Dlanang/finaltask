#!/bin/bash

# Hentikan dan hapus kontainer lama jika ada
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
  monitoring_app

echo "[+] Done!"
echo "Access Nginx/PHP at: http://<your-ip>:80"
echo "Access Streamlit at: http://<your-ip>:8502"