#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[setup-logo] FAILED at line $LINENO" >&2' ERR

if [[ ! -f /usr/share/pixmaps/anubis-logo.png ]]; then
    echo "ERROR: /usr/share/pixmaps/anubis-logo.png not found. Did the files module run?" >&2
    exit 1
fi

install -Dm644 /usr/share/pixmaps/anubis-logo.png \
    /usr/share/pixmaps/fedora_logo_med.png
install -Dm644 /usr/share/pixmaps/anubis-logo.png \
    /usr/share/pixmaps/fedora_whitelogo_med.png

LOGO_MENU_DIR=$(find /usr/share/gnome-shell/extensions -maxdepth 2 \
    -name "logomenu*" -type d 2>/dev/null | head -1)

if [[ -n "$LOGO_MENU_DIR" ]]; then
    install -Dm644 /usr/share/pixmaps/anubis-logo.png \
        "${LOGO_MENU_DIR}/media/logo.png"
    cat > "${LOGO_MENU_DIR}/media/logo.svg" << 'LOGOSVG'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     width="64" height="64" viewBox="0 0 64 64">
  <image xlink:href="/usr/share/pixmaps/anubis-logo.png"
         x="0" y="0" width="64" height="64"/>
</svg>
LOGOSVG
    echo "[setup-logo] Logo Menu extension patched."
else
    echo "[setup-logo] Warning: logomenu extension not found — skipping extension logo." >&2
fi

echo "[setup-logo] Done."
