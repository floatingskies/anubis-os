#!/usr/bin/env bash
# =============================================================================
#  enable-first-boot-units.sh
# -----------------------------------------------------------------------------
#  Enables the systemd units that drive the user-side first-boot setup.
#  Must run after setup-first-boot.sh.
# =============================================================================
set -euo pipefail
trap 'echo "[enable-first-boot-units] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[enable-first-boot-units] %s\n' "$*"; }

UNITS=(
    anubis-first-boot.service
    anubis-setup-user.service
)

for svc in "${UNITS[@]}"; do
    unit=/usr/lib/systemd/system/$svc
    if [[ ! -f "$unit" ]]; then
        echo "[enable-first-boot-units] ERROR: $unit not found — did setup-first-boot.sh run?" >&2
        exit 1
    fi
    systemctl enable "$svc" 2>&1 | sed 's/^/[enable-first-boot-units]   /' || true
    LOG "Enabled $svc"
done

LOG "Done."
