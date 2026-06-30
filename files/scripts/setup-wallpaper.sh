#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR=/usr/share/backgrounds/anubis-os
mkdir -p "$WALLPAPER_DIR"

# ── Remove GNOME / Fedora stock wallpapers ────────────────────────────────
rm -rf /usr/share/backgrounds/gnome
rm -rf /usr/share/backgrounds/f[0-9]*   # Fedora versioned dirs e.g. f44
# Remove stray .xml files for stock content in the system backgrounds dir
find /usr/share/backgrounds -maxdepth 1 -name "*.xml" \
    ! -name "anubis-*.xml" -delete 2>/dev/null || true

# ── GDM wallpaper (uses first wallpaper as static login background) ───────
GDM_DCONF_DIR=/etc/dconf/db/gdm.d
mkdir -p "$GDM_DCONF_DIR"

cat > "$GDM_DCONF_DIR/01-anubis-wallpaper" << 'GDMWALL'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/anubis-os/anubis-04-jonesy-lake.png'
picture-uri-dark='file:///usr/share/backgrounds/anubis-os/anubis-04-jonesy-lake.png'
picture-options='zoom'
GDMWALL

# ── GDM dconf profile ────────────────────────────────────────────────────
GDM_PROFILE=/etc/dconf/profile/gdm
if [[ ! -f "$GDM_PROFILE" ]]; then
    cat > "$GDM_PROFILE" << 'GDMPROFILE'
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
GDMPROFILE
fi

dconf update
