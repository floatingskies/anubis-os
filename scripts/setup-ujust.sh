#!/usr/bin/env bash
# =============================================================================
#  setup-ujust.sh
# -----------------------------------------------------------------------------
#  Installs Anubis OS's custom `ujust` recipes so the user can run:
#    ujust setup-shell / setup-brew / setup-gaming / setup-performance
#    ujust scheduler <name> / tuned <profile>
#    ujust distrobox-create / upgrade-user / upgrade-brew / upgrade-system
#    ujust cleanup / info
#
#  Idempotent. Runs at BUILD TIME.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-ujust] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-ujust] %s\n' "$*"; }

JUST_DIR=/usr/share/ublue-os/just
mkdir -p "$JUST_DIR"

ANUBIS_JUST=$JUST_DIR/anubis.just
if [[ ! -f "$ANUBIS_JUST" ]]; then
    echo "[setup-ujust] ERROR: $ANUBIS_JUST not found — did the files module run?" >&2
    exit 1
fi
chmod 0644 "$ANUBIS_JUST"

# Symlink the user-customisable justfile into /etc.
mkdir -p /etc/just
if [[ ! -e /etc/just/anubis.just ]]; then
    ln -sf "$ANUBIS_JUST" /etc/just/anubis.just
fi

if ! command -v just &>/dev/null; then
    LOG "WARNING: 'just' not found in PATH — ujust will not work." >&2
fi

LOG "Custom ujust recipes installed at: $ANUBIS_JUST"
LOG "Run 'ujust --list' on a live system to see every available recipe."
LOG "Done."
