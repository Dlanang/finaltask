#!/bin/bash

# Detect the primary network interface
# This script has been modified to use a hardcoded interface as auto-detection failed.
INTERFACE="wlan0"

if [ -z "$INTERFACE" ]; then
    echo "Error: Network interface is not specified." >&2
    exit 1
fi

echo "Using specified network interface: $INTERFACE"

# Start Suricata
exec /usr/bin/suricata -c /etc/suricata/suricata.yaml -i "$INTERFACE" --user suricata --group suricata --pidfile /run/suricata.pid