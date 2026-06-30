#!/usr/bin/env bash
set -euo pipefail

mkdir -p /etc

echo "anubis" > /etc/hostname

# Remove whatever /etc/machine-info is (file or stale directory) before recreating
rm -rf /etc/machine-info

cat > /etc/machine-info << 'MACHINEINFO'
PRETTY_HOSTNAME="anubis-os"
ICON_NAME="computer"
MACHINEINFO
