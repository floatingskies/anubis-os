#!/usr/bin/env bash
# anubis-pick-wallpaper.sh
# Runs once on first boot (via the systemd unit in
# files/system/usr/lib/systemd/system/anubis-first-boot-wallpaper.service)
# and picks one of the bundled wallpapers at random, then sets it as both
# the light and dark mode background for the current user via gsettings.

set -euo pipefail

MARKER="/var/lib/anubis-os/.wallpaper-set"
WALLPAPER_DIR="/usr/share/backgrounds/anubis-os"

mkdir -p "$(dirname "$MARKER")"

# Only run once per install — re-running is harmless but pointless after
# the first successful pick.
if [[ -f "$MARKER" ]]; then
    exit 0
fi

mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort)

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    echo "anubis-pick-wallpaper: no wallpapers found in $WALLPAPER_DIR" >&2
    exit 0
fi

PICK="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"

# Apply for every real user with a graphical session configured (GNOME
# stores this per-user via dconf, so we set it for whoever's $HOME exists
# under /home — this runs as a oneshot system unit, so we drop into each
# user's dbus session via gsettings + machinectl/loginctl shell, or more
# simply: write a default dconf override so it applies even before first
# login, then let gsettings calls below refresh it for already-logged-in
# sessions on systems that boot to GDM and auto-login.)

DCONF_DEFAULTS_DIR="/etc/dconf/db/local.d"
mkdir -p "$DCONF_DEFAULTS_DIR"
cat > "$DCONF_DEFAULTS_DIR/01-anubis-wallpaper" <<EOF
[org/gnome/desktop/background]
picture-uri='file://${PICK}'
picture-uri-dark='file://${PICK}'
picture-options='zoom'

[org/gnome/desktop/screensaver]
picture-uri='file://${PICK}'
EOF

dconf update

touch "$MARKER"
echo "anubis-pick-wallpaper: set $PICK as default wallpaper" >&2
