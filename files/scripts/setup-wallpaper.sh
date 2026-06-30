#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[setup-wallpaper] FAILED at line $LINENO" >&2' ERR

WALLPAPER_DIR=/usr/share/backgrounds/anubis-os
mkdir -p "$WALLPAPER_DIR"

# Remove GNOME / Fedora stock wallpapers
rm -rf /usr/share/backgrounds/gnome
# Fedora versioned dirs (f40, f41, f44, etc.)
find /usr/share/backgrounds -maxdepth 1 -type d -name 'f[0-9]*' -exec rm -rf {} + 2>/dev/null || true

# GDM dconf — static login background
GDM_DCONF_DIR=/etc/dconf/db/gdm.d
mkdir -p "$GDM_DCONF_DIR"

cat > "$GDM_DCONF_DIR/01-anubis-wallpaper" << 'GDMWALL'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/anubis-os/anubis-04-jonesy-lake.png'
picture-uri-dark='file:///usr/share/backgrounds/anubis-os/anubis-04-jonesy-lake.png'
picture-options='zoom'
GDMWALL

# GDM dconf profile
GDM_PROFILE=/etc/dconf/profile/gdm
if [[ ! -f "$GDM_PROFILE" ]]; then
    cat > "$GDM_PROFILE" << 'GDMPROFILE'
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
GDMPROFILE
fi

# Compile dconf — non-fatal if dconf not present at build time
dconf update 2>/dev/null || true
