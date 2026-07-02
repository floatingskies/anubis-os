#!/usr/bin/env bash
# =============================================================================
#  setup-bazaar-default.sh
# -----------------------------------------------------------------------------
#  Makes Bazaar (io.github.kolunmi.Bazaar) the default "app store" on the
#  KDE Plasma system, replacing Discover's slot in:
#
#    * Kickoff/Application menu — adds an "Install Software" entry pointing
#      at Bazaar instead of Discover
#    * KRunner — `discover` and `software` keywords launch Bazaar
#    * Default URL handler for appstream:// and apt:// URLs (so "Install"
#      buttons in Firefox/other browsers open Bazaar)
#    * KDE System Settings → "Software Sources" shortcut (Discover-owned)
#      is hidden so users don't get a broken launcher
#
#  Bazaar itself is shipped as a pre-baked Flatpak (recipe stage J), so this
#  is fully offline-capable. No Discover RPM is needed.
#
#  Idempotent. Runs at BUILD TIME.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-bazaar-default] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-bazaar-default] %s\n' "$*"; }

SKEL_CONFIG=/etc/skel/.config
SKEL_APPS=/etc/skel/.local/share/applications
SYSTEM_APPS=/usr/share/applications
mkdir -p "$SKEL_CONFIG" "$SKEL_APPS" "$SYSTEM_APPS"

# =============================================================================
#  1. Hide the Discover .desktop file (if it ships from kdeplasma-addons or
#     any leftover package). We don't ship plasma-discover, but be defensive
#     in case it sneaks back via a layered RPM.
# =============================================================================
LOG "Hiding Discover .desktop entries ..."
for f in \
    org.kde.discover.desktop \
    org.kde.discover-notifier.desktop \
    plasma-discover.desktop
do
    if [[ -f "$SYSTEM_APPS/$f" ]]; then
        # Append NoDisplay=true (don't delete — keep it reversible).
        if ! grep -q '^NoDisplay=' "$SYSTEM_APPS/$f"; then
            echo "NoDisplay=true" >> "$SYSTEM_APPS/$f"
        fi
        if ! grep -q '^Hidden=' "$SYSTEM_APPS/$f"; then
            echo "Hidden=true" >> "$SYSTEM_APPS/$f"
        fi
        LOG "  hidden: $f"
    fi
done

# =============================================================================
#  2. Register Bazaar as the default app store via MIME handlers.
# =============================================================================
# appstream:// URLs are what KDE "Get more [stuff]" buttons use. Point them
# at Bazaar.
LOG "Registering Bazaar as appstream:// URL handler ..."

# Make sure xdg-mime knows about Bazaar. The Flatpak desktop file is at
# /var/lib/flatpak/exports/share/applications/io.github.kolunmi.Bazaar.desktop
# at runtime; at build time we just install the MIME handler config.
mkdir -p /usr/share/applications
cat > /usr/share/applications/io.github.kolunmi.Bazaar.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Bazaar
GenericName=Software Store
Comment=Browse and install Flatpak applications
Exec=flatpak run io.github.kolunmi.Bazaar %U
Icon=io.github.kolunmi.Bazaar
Terminal=false
Categories=System;PackageManager;Settings;
Keywords=software;store;install;flatpak;app;application;bazaar;
StartupNotify=true
StartupWMClass=io.github.kolunmi.Bazaar
MimeType=x-scheme-handler/appstream;x-scheme-handler/apt;
DESKTOP
chmod 0644 /usr/share/applications/io.github.kolunmi.Bazaar.desktop

# Update the MIME cache so appstream:// URLs route to Bazaar.
mkdir -p /usr/share/mime/packages
cat > /usr/share/mime/packages/anubis-bazaar.xml <<'MIME'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="x-scheme-handler/appstream">
    <comment>AppStream URL (handled by Bazaar)</comment>
  </mime-type>
  <mime-type type="x-scheme-handler/apt">
    <comment>APT URL (handled by Bazaar)</comment>
  </mime-type>
</mime-info>
MIME

# Register the MIME defaults.
mkdir -p /etc/xdg
cat > /etc/xdg/mimeapps.list <<'MIMEAPPS'
[Default Applications]
x-scheme-handler/appstream=io.github.kolunmi.Bazaar.desktop
x-scheme-handler/apt=io.github.kolunmi.Bazaar.desktop

[Added Associations]
x-scheme-handler/appstream=io.github.kolunmi.Bazaar.desktop
x-scheme-handler/apt=io.github.kolunmi.Bazaar.desktop
MIMEAPPS
chmod 0644 /etc/xdg/mimeapps.list

# =============================================================================
#  3. Add a Kickoff / Application Menu entry for Bazaar under "System"
# =============================================================================
LOG "Adding Bazaar to Application Menu ..."
cat > "$SYSTEM_APPS/anubis-install-software.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Install Software
GenericName=App Store
Comment=Install and manage Flatpak applications via Bazaar
Exec=flatpak run io.github.kolunmi.Bazaar
Icon=io.github.kolunmi.Bazaar
Terminal=false
Categories=System;PackageManager;
Keywords=install;software;store;app;bazaar;flatpak;
StartupNotify=true
StartupWMClass=io.github.kolunmi.Bazaar
DESKTOP
chmod 0644 "$SYSTEM_APPS/anubis-install-software.desktop"

# =============================================================================
#  4. KDE System Settings: hide the "Software Sources" KCM (Discover-owned)
# =============================================================================
# The kcm_sofware_sources.desktop KCM is shipped by Discover. If it's present
# it shows a broken icon in System Settings. Hide it.
for f in kcm_sofware_sources.desktop kcm_software_sources.desktop; do
    if [[ -f "$SYSTEM_APPS/$f" ]]; then
        if ! grep -q '^NoDisplay=' "$SYSTEM_APPS/$f"; then
            echo "NoDisplay=true" >> "$SYSTEM_APPS/$f"
        fi
        LOG "  hidden KCM: $f"
    fi
done

# =============================================================================
#  5. KRunner keyword redirection (optional but nice)
# =============================================================================
# KRunner matches .desktop Name + Keywords. We already set Keywords= on the
# Bazaar desktop file, so typing "software", "install", "app store", etc.
# in KRunner surfaces Bazaar. No further work needed.

# =============================================================================
#  6. Update the icon cache so the Bazaar icon is discoverable
# =============================================================================
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
fi
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$SYSTEM_APPS" 2>/dev/null || true
fi

LOG "Done. Bazaar is the default app store."
LOG "  - /usr/share/applications/io.github.kolunmi.Bazaar.desktop"
LOG "  - /usr/share/applications/anubis-install-software.desktop"
LOG "  - /etc/xdg/mimeapps.list (appstream:// → Bazaar)"
