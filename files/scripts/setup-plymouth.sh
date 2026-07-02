#!/usr/bin/env bash
# =============================================================================
#  setup-plymouth.sh
# -----------------------------------------------------------------------------
#  Installs the Anubis Plymouth boot splash theme, forces it as default, pins
#  it into the dracut initramfs, and rebuilds every installed kernel's
#  initramfs so the theme is *baked in* (critical for encrypted-disk password
#  prompts).
#
#  Plymouth is DE-agnostic — works identically under SDDM/KDE and GDM/GNOME.
#
#  Idempotent. Runs at BUILD TIME.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-plymouth] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-plymouth] %s\n' "$*"; }

LOGO_SRC=/usr/share/pixmaps/anubis-logo.png
if [[ ! -f "$LOGO_SRC" ]]; then
    echo "[setup-plymouth] ERROR: $LOGO_SRC not found — did the files module run first?" >&2
    exit 1
fi

if ! command -v plymouth-set-default-theme &>/dev/null; then
    echo "[setup-plymouth] ERROR: plymouth-set-default-theme not found — is 'plymouth' installed?" >&2
    exit 1
fi

# --- 1. Theme files ---------------------------------------------------------
THEME_DIR=/usr/share/plymouth/themes/anubis
LOG "Installing theme into $THEME_DIR ..."
mkdir -p "$THEME_DIR"
install -Dm644 "$LOGO_SRC" "$THEME_DIR/anubis-logo.png"

cat > "$THEME_DIR/anubis.plymouth" <<'PLYMOUTH'
[Plymouth Theme]
Name=Anubis OS
Description=Anubis OS boot splash — dark gradient + centered logo with fade-in
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/anubis
ScriptFile=/usr/share/plymouth/themes/anubis/anubis.script
PLYMOUTH

cat > "$THEME_DIR/anubis.script" <<'SCRIPT'
# --- background gradient -----------------------------------------------
Window.SetBackgroundTopColor(0.07, 0.07, 0.09);
Window.SetBackgroundBottomColor(0.03, 0.03, 0.04);

screen_width  = Window.GetWidth();
screen_height = Window.GetHeight();

# --- logo, scaled to ~28% of the shorter screen dimension -------------
logo_image = Image("anubis-logo.png");
scale      = Math.Min(screen_width, screen_height) * 0.28 / logo_image.GetWidth();
logo_scaled = logo_image.Scale(logo_image.GetWidth() * scale,
                               logo_image.GetHeight() * scale);

logo_sprite = Sprite(logo_scaled);
logo_sprite.SetX(screen_width  / 2 - logo_scaled.GetWidth()  / 2);
logo_sprite.SetY(screen_height / 2 - logo_scaled.GetHeight() / 2);
logo_sprite.SetZ(10);
logo_sprite.SetOpacity(0);

# --- animation: fade the logo in over the first ~30 frames (~1s @30fps) ----
global.t = 0;
fun refresh_callback() {
    global.t++;
    if (global.t < 30) {
        logo_sprite.SetOpacity(global.t / 30);
    } else {
        logo_sprite.SetOpacity(1);
    }
}
Plymouth.SetRefreshFunction(refresh_callback);

# --- keep logo visible through password prompts (encrypted disks) -----------
fun display_password_callback(prompt, bullets) {
    logo_sprite.SetOpacity(1);
}
Plymouth.SetDisplayPasswordFunction(display_password_callback);

# --- boot progress (optional, very subtle) ----------------------------------
fun boot_progress_callback(progress) {
    logo_sprite.SetOpacity(1);
}
Plymouth.SetBootProgressFunction(boot_progress_callback);
SCRIPT

# --- 2. Force the daemon config --------------------------------------------
LOG "Writing /etc/plymouth/plymouthd.conf ..."
mkdir -p /etc/plymouth
cat > /etc/plymouth/plymouthd.conf <<'EOF'
[Daemon]
Theme=anubis
ShowDelay=0
DeviceTimeout=8
EOF

# --- 3. Set the default theme ----------------------------------------------
LOG "Setting default plymouth theme to 'anubis' ..."
plymouth-set-default-theme anubis

# --- 4. Pin plymouth dracut module -----------------------------------------
LOG "Pinning plymouth dracut module ..."
mkdir -p /etc/dracut.conf.d
cat > /etc/dracut.conf.d/10-anubis-plymouth.conf <<'EOF'
add_dracutmodules+=" plymouth "
install_optional_items+=" /usr/share/plymouth/themes/anubis/anubis.plymouth /usr/share/plymouth/themes/anubis/anubis.script /usr/share/plymouth/themes/anubis/anubis-logo.png "
EOF

# --- 5. Rebuild the initramfs for every installed kernel -------------------
if command -v dracut &>/dev/null; then
    LOG "Rebuilding initramfs for all installed kernels ..."
    mapfile -t KERNEL_VERSIONS < <(ls /usr/lib/modules 2>/dev/null || true)

    if (( ${#KERNEL_VERSIONS[@]} > 0 )); then
        for kv in "${KERNEL_VERSIONS[@]}"; do
            LOG "  → kernel: $kv"
            dracut -f --kver "$kv"
        done
    else
        LOG "  no kernel in /usr/lib/modules — falling back to --regenerate-all"
        dracut -f --regenerate-all
    fi
else
    LOG "WARNING: dracut not available — relying on dracut module pin only." >&2
fi

LOG "Done."
