#!/bin/bash

# This script automates the setup of Suricata on the host system.
# It should be run with sudo privileges.

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