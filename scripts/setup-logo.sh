#!/usr/bin/env bash
# =============================================================================
#  setup-logo.sh  (KDE / Kinoite edition)
# -----------------------------------------------------------------------------
#  Stamps the Anubis logo onto every surface KDE might display a distro logo:
#
#    * /usr/share/pixmaps/anubis-logo.png                 (canonical source)
#    * /usr/share/pixmaps/fedora_logo_med.png             (KDE vendor aliases)
#    * /usr/share/pixmaps/fedora_whitelogo_med.png
#    * /usr/share/pixmaps/fedora_logo.png
#    * /usr/share/pixmaps/fedora_whitelogo.png
#    * SDDM breeze theme:  /usr/share/sddm/themes/breeze/anubis-logo.png
#    * SDDM anubis theme:  /usr/share/sddm/themes/anubis/logo.png
#    * Plasma lockscreen / wallpaper overlay (handled by setup-wallpaper.sh)
#    * KInfoCenter "About this System" page (reads LOGO= from /etc/os-release,
#      which we already set in setup-os-release.sh)
#    * KRunner's "Search" logo (no override; picks up the icon theme)
#
#  Prereqs:
#    * /usr/share/pixmaps/anubis-logo.png (shipped by `files`)
#    * KDE Plasma + SDDM installed (recipe stage G)
#
#  Idempotent. Runs at BUILD TIME.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-logo] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-logo] %s\n' "$*"; }

LOGO_SRC=/usr/share/pixmaps/anubis-logo.png
if [[ ! -f "$LOGO_SRC" ]]; then
    echo "[setup-logo] ERROR: $LOGO_SRC not found — did the files module run first?" >&2
    exit 1
fi

# --- 1. Fedora pixmaps aliases (KDE vendor logo, "About" page) --------------
LOG "Stamping Fedora pixmaps aliases ..."
for f in fedora_logo_med.png fedora_whitelogo_med.png fedora_logo.png fedora_whitelogo.png; do
    install -Dm644 "$LOGO_SRC" "/usr/share/pixmaps/$f"
done

# --- 2. SDDM breeze theme — replace the default Plasma logo with Anubis ----
# The breeze SDDM theme ships a logo at /usr/share/sddm/themes/breeze/
# There is no fixed logo filename; the theme's theme.conf references one. We
# patch every logo.png we find under the breeze theme directory.
LOG "Patching SDDM breeze theme logo ..."
BREEZE_DIR=/usr/share/sddm/themes/breeze
if [[ -d "$BREEZE_DIR" ]]; then
    # Replace every logo*.png and background.png we can find.
    find "$BREEZE_DIR" -maxdepth 2 -type f \( -name 'logo*.png' -o -name 'background.png' \) | while read -r target; do
        install -Dm644 "$LOGO_SRC" "$target"
        LOG "  patched: $target"
    done

    # Also drop an anubis-logo.png alongside so theme.conf can reference it
    # if the user later customises the theme.
    install -Dm644 "$LOGO_SRC" "$BREEZE_DIR/anubis-logo.png"

    # Patch theme.conf to use the Anubis logo if it currently references a
    # different one. Be conservative: only update the logo= line if present.
    if [[ -f "$BREEZE_DIR/theme.conf" ]]; then
        if grep -q '^[# ]*logo=' "$BREEZE_DIR/theme.conf"; then
            sed -i "s|^[# ]*logo=.*|logo=anubis-logo.png|" "$BREEZE_DIR/theme.conf"
            LOG "  patched: theme.conf logo="
        fi
    fi
else
    LOG "WARNING: SDDM breeze theme not found at $BREEZE_DIR — skipping." >&2
fi

# --- 3. SDDM anubis theme (custom) -----------------------------------------
# We ship a custom SDDM theme under /usr/share/sddm/themes/anubis/ via the
# `files` module. Just drop the logo in.
ANUBIS_THEME_DIR=/usr/share/sddm/themes/anubis
if [[ -d "$ANUBIS_THEME_DIR" ]]; then
    install -Dm644 "$LOGO_SRC" "$ANUBIS_THEME_DIR/logo.png"
    LOG "Patched SDDM anubis theme logo."
fi

# --- 4. KInfoCenter "About this System" page -------------------------------
# KInfoCenter reads LOGO= from /etc/os-release (set by setup-os-release.sh)
# and looks up the icon via the XDG icon theme. Make sure anubis-logo is
# discoverable as an icon name.
LOG "Installing anubis-logo as a discoverable icon ..."
for size in 16 22 32 48 64 96 128 256; do
    install -Dm644 "$LOGO_SRC" "/usr/share/icons/hicolor/${size}x${size}/apps/anubis-logo.png"
done
# Scalable SVG alias (use the PNG wrapped in SVG so legacy SVG-only lookups
# still resolve).
cat > /usr/share/icons/hicolor/scalable/apps/anubis-logo.svg <<'SVG'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     width="256" height="256" viewBox="0 0 256 256">
  <image xlink:href="/usr/share/pixmaps/anubis-logo.png"
         x="0" y="0" width="256" height="256"/>
</svg>
SVG

# Refresh the icon cache if gtk-update-icon-cache is available.
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
fi

LOG "Done."
