#!/usr/bin/env bash
# =============================================================================
#  setup-brew.sh
# -----------------------------------------------------------------------------
#  Ships the default Anubis OS Brewfile into /usr/share/anubis-os/Brewfile.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-brew] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-brew] %s\n' "$*"; }

ANUBIS_DIR=/usr/share/anubis-os
mkdir -p "$ANUBIS_DIR"

LOG "Verifying default Brewfile ..."
if [[ ! -f "$ANUBIS_DIR/Brewfile" ]]; then
    echo "[setup-brew] ERROR: $ANUBIS_DIR/Brewfile not found — did the files module run?" >&2
    exit 1
fi
chmod 0644 "$ANUBIS_DIR/Brewfile"

LOG "Default Brewfile shipped. Users customise via:"
LOG "  cp /usr/share/anubis-os/Brewfile ~/.config/anubis-os/Brewfile"
LOG "  (then edit and run: ujust setup-brew)"
LOG "Done."
