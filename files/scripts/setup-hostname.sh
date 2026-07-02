#!/usr/bin/env bash
# =============================================================================
#  setup-hostname.sh — DE-agnostic. Sets hostname + machine-info.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-hostname] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-hostname] %s\n' "$*"; }

LOG "Setting hostname to 'anubis' ..."
echo "anubis" > /etc/hostname

LOG "Writing /etc/machine-info ..."
rm -rf /etc/machine-info
cat > /etc/machine-info <<'MACHINEINFO'
PRETTY_HOSTNAME="Anubis OS"
ICON_NAME=computer
CHASSIS=desktop
DEPLOYMENT=anubis
MACHINEINFO

LOG "Done."
