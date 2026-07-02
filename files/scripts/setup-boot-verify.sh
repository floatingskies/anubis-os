#!/usr/bin/env bash
# =============================================================================
#  setup-boot-verify.sh
# -----------------------------------------------------------------------------
#  Generates the `anubis-boot-verify.service` systemd unit + a verification
#  script that runs on EVERY boot (not just first boot) to:
#
#    1. Verify the Plymouth theme is set to "anubis" — if not, force-set it
#       and rebuild the initramfs.
#    2. Verify the default wallpaper file exists at /usr/share/wallpapers/
#       anubis-os/anubis-wallpaper.png — if not, log a warning.
#    3. Verify the SDDM background is set to the Anubis wallpaper — if not,
#       re-copy it from the wallpaper directory.
#    4. Verify the anubis-logo.png exists in /usr/share/pixmaps/ — if not,
#       log a warning.
#    5. Re-apply tuned profile (defence in depth against other services
#       resetting it).
#    6. Ensure scx_modscheduler is running (if enabled).
#
#  This is the BULLETPROOFING layer: even if a kernel upgrade, dracut
#  rebuild, or package update clobbers our Plymouth theme or wallpaper,
#  the next boot restores it. No manual `ujust setup-performance` needed.
#
#  Idempotent. Runs at BUILD TIME.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-boot-verify] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-boot-verify] %s\n' "$*"; }

UNIT_DIR=/usr/lib/systemd/system
SCRIPT_DIR=/usr/share/anubis-os/scripts
mkdir -p "$UNIT_DIR" "$SCRIPT_DIR"

# =============================================================================
#  1. anubis-boot-verify.service — runs on every boot
# =============================================================================
LOG "Generating anubis-boot-verify.service ..."
cat > "$UNIT_DIR/anubis-boot-verify.service" <<'UNIT'
[Unit]
Description=Anubis OS — boot verification + Plymouth/wallpaper/tuned enforcement
Wants=network-online.target
After=network-online.target systemd-user-sessions.service plymouth-start.service
ConditionPathExists=/usr/share/anubis-os/scripts/boot-verify.sh

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/share/anubis-os/scripts/boot-verify.sh
# Don't fail boot if verification fails — just log it.
SuccessExitStatus=0 1 2

[Install]
WantedBy=multi-user.target
UNIT

# =============================================================================
#  2. boot-verify.sh — the verification script (runs on every boot)
# =============================================================================
LOG "Generating boot-verify.sh ..."
cat > "$SCRIPT_DIR/boot-verify.sh" <<'BVS'
#!/usr/bin/env bash
# Anubis OS — boot verification. Runs on EVERY boot.
# Re-applies Plymouth theme, verifies wallpapers, restarts tuned + scx.
set -uo pipefail

LOG()  { printf '[anubis-boot-verify] %s\n' "$*"; }
WARN() { printf '[anubis-boot-verify] WARNING: %s\n' "$*" >&2; }

# --- 1. Plymouth theme verification ----------------------------------------
if command -v plymouth-set-default-theme &>/dev/null; then
    CURRENT_THEME=$(plymouth-set-default-theme 2>/dev/null || echo "")
    if [[ "$CURRENT_THEME" != "anubis" ]]; then
        LOG "Plymouth theme is '$CURRENT_THEME', expected 'anubis' — fixing ..."
        plymouth-set-default-theme anubis 2>/dev/null || \
            WARN "could not set plymouth theme"
        # Rebuild initramfs in the background so we don't slow down boot.
        # Only rebuild if dracut is available and there's a kernel to rebuild for.
        if command -v dracut &>/dev/null; then
            mapfile -t KERNEL_VERSIONS < <(ls /usr/lib/modules 2>/dev/null || true)
            for kv in "${KERNEL_VERSIONS[@]}"; do
                LOG "Rebuilding initramfs for kernel $kv in background ..."
                nohup dracut -f --kver "$kv" >/var/log/anubis-dracut-rebuild.log 2>&1 &
            done
        fi
    else
        LOG "Plymouth theme: OK (anubis)"
    fi
else
    WARN "plymouth-set-default-theme not found"
fi

# --- 2. Wallpaper verification ---------------------------------------------
WALLPAPER_DIR=/usr/share/wallpapers/anubis-os
DEFAULT_WALLPAPER="$WALLPAPER_DIR/anubis-wallpaper.png"
if [[ ! -f "$DEFAULT_WALLPAPER" ]]; then
    WARN "default wallpaper missing: $DEFAULT_WALLPAPER"
else
    LOG "Default wallpaper: OK"
fi

WALLPAPER_COUNT=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | wc -l)
LOG "$WALLPAPER_COUNT wallpaper(s) present in $WALLPAPER_DIR"

# --- 3. SDDM background verification ---------------------------------------
BREEZE_DIR=/usr/share/sddm/themes/breeze
if [[ -d "$BREEZE_DIR" ]] && [[ -f "$DEFAULT_WALLPAPER" ]]; then
    BREEZE_BG="$BREEZE_DIR/background.png"
    if [[ ! -f "$BREEZE_BG" ]] || ! cmp -s "$BREEZE_BG" "$DEFAULT_WALLPAPER"; then
        LOG "SDDM background missing or stale — re-copying ..."
        install -Dm644 "$DEFAULT_WALLPAPER" "$BREEZE_BG"
    else
        LOG "SDDM background: OK"
    fi
fi

# --- 4. Logo verification --------------------------------------------------
LOGO=/usr/share/pixmaps/anubis-logo.png
if [[ ! -f "$LOGO" ]]; then
    WARN "anubis logo missing: $LOGO"
else
    LOG "Anubis logo: OK"
fi

# --- 5. tuned profile re-application ---------------------------------------
if command -v tuned-adm &>/dev/null; then
    ACTIVE_PROFILE=$(tuned-adm active 2>/dev/null | head -1 | awk -F': ' '{print $2}' || echo "")
    if [[ "$ACTIVE_PROFILE" != "anubis-network-latency" ]]; then
        LOG "tuned profile is '$ACTIVE_PROFILE', expected 'anubis-network-latency' — fixing ..."
        tuned-adm profile anubis-network-latency 2>/dev/null || \
            WARN "could not set tuned profile"
    else
        LOG "tuned profile: OK ($ACTIVE_PROFILE)"
    fi
fi

# --- 6. scx_modscheduler verification --------------------------------------
if [[ -f /etc/default/scx ]]; then
    . /etc/default/scx
    if [[ -n "${SCX_SCHEDULER:-}" ]]; then
        if systemctl is-enabled scx_modscheduler.service &>/dev/null; then
            if ! systemctl is-active scx_modscheduler.service &>/dev/null; then
                LOG "scx_modscheduler enabled but not active — starting ..."
                systemctl start scx_modscheduler.service 2>/dev/null || \
                    WARN "could not start scx_modscheduler"
            else
                LOG "scx_modscheduler: OK ($SCX_SCHEDULER)"
            fi
        fi
    fi
fi

# --- 7. Baloo re-disable (defence in depth) --------------------------------
if command -v balooctl6 &>/dev/null; then
    balooctl6 suspend 2>/dev/null || true
elif command -v balooctl &>/dev/null; then
    balooctl suspend 2>/dev/null || true
fi

LOG "Boot verification complete."
BVS
chmod 0755 "$SCRIPT_DIR/boot-verify.sh"

# =============================================================================
#  3. Enable the unit so it fires on every boot
# =============================================================================
LOG "Enabling anubis-boot-verify.service ..."
systemctl enable anubis-boot-verify.service 2>&1 | sed 's/^/[setup-boot-verify]   /' || true

LOG "Done. Boot verification unit + script installed."
LOG "  - $UNIT_DIR/anubis-boot-verify.service"
LOG "  - $SCRIPT_DIR/boot-verify.sh"
