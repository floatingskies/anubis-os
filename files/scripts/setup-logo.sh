#!/usr/bin/env bash
set -euo pipefail

# Replace Fedora logos with Anubis OS logo
install -Dm644 /usr/share/pixmaps/anubis-logo.png \
    /usr/share/pixmaps/fedora_logo_med.png

install -Dm644 /usr/share/pixmaps/anubis-logo.png \
    /usr/share/pixmaps/fedora_whitelogo_med.png

# Logo Menu extension — replace default SVG/PNG with Anubis logo.
# Use find so the UUID path doesn't have to be hardcoded.
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
else
    echo "Warning: logomenu extension directory not found — skipping logo replacement." >&2
fi
