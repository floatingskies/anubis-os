#!/usr/bin/env bash
# =============================================================================
#  set-permissions.sh
# -----------------------------------------------------------------------------
#  Sets correct file modes, capabilities, and SELinux contexts on every file
#  the recipe ships. Runs LAST in the build-time script chain.
# =============================================================================
set -euo pipefail
trap 'echo "[set-permissions] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[set-permissions] %s\n' "$*"; }

# --- 1. Anubis OS shipped scripts -------------------------------------------
LOG "Setting modes for /usr/share/anubis-os/scripts/* ..."
find /usr/share/anubis-os/scripts -type f -name '*.sh' -exec chmod 0755 {} +
find /usr/share/ublue-os/just -type f -name '*.just' -exec chmod 0644 {} + 2>/dev/null || true

# --- 2. Systemd units -------------------------------------------------------
LOG "Setting modes for /usr/lib/systemd/system/anubis-* ..."
find /usr/lib/systemd/system -maxdepth 1 -type f -name 'anubis-*' -exec chmod 0644 {} +

# --- 2b. Anubis scripts (including boot-verify.sh) --------------------------
LOG "Setting modes for /usr/share/anubis-os/scripts/* ..."
find /usr/share/anubis-os/scripts -type f -name '*.sh' -exec chmod 0755 {} + 2>/dev/null || true

# --- 3. Logos + wallpapers --------------------------------------------------
LOG "Setting modes for pixmaps + wallpapers ..."
find /usr/share/pixmaps -maxdepth 1 -type f -name 'anubis-*' -exec chmod 0644 {} + 2>/dev/null || true
find /usr/share/wallpapers/anubis-os -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -exec chmod 0644 {} + 2>/dev/null || true
find /usr/share/icons/hicolor -name 'anubis-logo.*' -exec chmod 0644 {} + 2>/dev/null || true

# --- 4. dconf locks (legacy GNOME path — harmless if unused) ----------------
find /etc/dconf/db/local.d/locks -type f -exec chmod 0644 {} + 2>/dev/null || true

# --- 5. sysctl / modprobe / udev / tuned / dracut ---------------------------
LOG "Setting modes for /etc configs ..."
find /etc/sysctl.d          -maxdepth 1 -type f -name '*anubis*' -exec chmod 0644 {} + 2>/dev/null || true
find /etc/modprobe.d        -maxdepth 1 -type f -name '*anubis*' -exec chmod 0644 {} + 2>/dev/null || true
find /etc/udev/rules.d      -maxdepth 1 -type f -name '*anubis*' -exec chmod 0644 {} + 2>/dev/null || true
find /etc/security/limits.d -maxdepth 1 -type f -name '*anubis*' -exec chmod 0644 {} + 2>/dev/null || true
find /etc/dracut.conf.d     -maxdepth 1 -type f -name '*anubis*' -exec chmod 0644 {} + 2>/dev/null || true
find /etc/tuned/profiles -type f -name 'tuned.conf' -exec chmod 0644 {} + 2>/dev/null || true
[[ -f /etc/default/scx ]] && chmod 0644 /etc/default/scx

# --- 6. Plymouth theme ------------------------------------------------------
LOG "Setting modes for plymouth theme ..."
find /usr/share/plymouth/themes/anubis -type f -exec chmod 0644 {} + 2>/dev/null || true
[[ -f /etc/plymouth/plymouthd.conf ]] && chmod 0644 /etc/plymouth/plymouthd.conf

# --- 7. Brewfile ------------------------------------------------------------
LOG "Setting modes for Brewfile ..."
[[ -f /usr/share/anubis-os/Brewfile ]] && chmod 0644 /usr/share/anubis-os/Brewfile

# --- 8. SDDM config ---------------------------------------------------------
LOG "Setting modes for SDDM + KDE configs ..."
find /etc/sddm.conf.d -type f -exec chmod 0644 {} + 2>/dev/null || true
find /etc/xdg -maxdepth 1 -type f -exec chmod 0644 {} + 2>/dev/null || true

# --- 9. Capabilities --------------------------------------------------------
if command -v gamemoded &>/dev/null; then
    setcap 'cap_sys_nice=eip' "$(command -v gamemoded)" 2>/dev/null || \
        LOG "WARNING: could not setcap on gamemoded (non-fatal in build container)."
fi

# --- 10. SELinux restorecon -------------------------------------------------
if command -v restorecon &>/dev/null; then
    LOG "Restoring SELinux contexts ..."
    restorecon -Rv /usr/share/anubis-os /usr/share/pixmaps/anubis-* \
        /usr/share/wallpapers/anubis-os /usr/lib/systemd/system/anubis-* \
        /etc/sysctl.d /etc/modprobe.d /etc/udev/rules.d /etc/tuned/profiles \
        /etc/dracut.conf.d /etc/sddm.conf.d /etc/xdg \
        2>/dev/null || true
fi

LOG "Done."
