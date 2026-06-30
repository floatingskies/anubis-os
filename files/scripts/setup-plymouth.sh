#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[setup-plymouth] FAILED at line $LINENO" >&2' ERR

if [[ ! -f /usr/share/pixmaps/anubis-logo.png ]]; then
    echo "ERROR: /usr/share/pixmaps/anubis-logo.png not found. Did the files module run?" >&2
    exit 1
fi

THEME_DIR=/usr/share/plymouth/themes/anubis
mkdir -p "$THEME_DIR"

install -Dm644 /usr/share/pixmaps/anubis-logo.png \
    "$THEME_DIR/anubis-logo.png"

cat > "$THEME_DIR/anubis.plymouth" << 'PLYMOUTH'
[Plymouth Theme]
Name=Anubis OS
Description=Anubis OS boot splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/anubis
ScriptFile=/usr/share/plymouth/themes/anubis/anubis.script
PLYMOUTH

# Solid dark background, centered logo with a smooth fade-in.
# Clean and modern look with 100% stability on all graphic drivers.
cat > "$THEME_DIR/anubis.script" << 'SCRIPT'
# --- background -------------------------------------------------------
Window.SetBackgroundTopColor(0.07, 0.07, 0.09);
Window.SetBackgroundBottomColor(0.03, 0.03, 0.04);

screen_width  = Window.GetWidth();
screen_height = Window.GetHeight();

# --- logo, scaled to ~28% of the shorter screen dimension -------------
logo_image = Image("anubis-logo.png");
scale = Math.Min(screen_width, screen_height) * 0.28 / logo_image.GetWidth();
logo_scaled = logo_image.Scale(
    logo_image.GetWidth()  * scale,
    logo_image.GetHeight() * scale
);

logo_sprite = Sprite(logo_scaled);
logo_sprite.SetX(screen_width  / 2 - logo_scaled.GetWidth()  / 2);
logo_sprite.SetY(screen_height / 2 - logo_scaled.GetHeight() / 2);
logo_sprite.SetZ(10);
logo_sprite.SetOpacity(0);

# --- animation: fade the logo in smoothly -----------------------------
global.t = 0;
fun refresh_callback() {
    global.t++;
    # Logo fade-in over the first ~30 frames (~1s at 30fps)
    if (global.t < 30) {
        logo_sprite.SetOpacity(global.t / 30);
    } else {
        logo_sprite.SetOpacity(1);
    }
}
Plymouth.SetRefreshFunction(refresh_callback);

# --- keep logo visible through password prompts on encrypted disks -----
fun display_password_callback(prompt, bullets) {
    logo_sprite.SetOpacity(1);
}
Plymouth.SetDisplayPasswordFunction(display_password_callback);
SCRIPT

# --- Configuração Forçada do Plymouth (Garantia contra o logo do Fedora) -
echo "[setup-plymouth] Forcing plymouthd.conf to use anubis..."
mkdir -p /etc/plymouth
cat > /etc/plymouth/plymouthd.conf << 'EOF'
[Daemon]
Theme=anubis
ShowDelay=0
DeviceTimeout=8
EOF

# --- Apply the theme ----------------------------------------------------
if ! command -v plymouth-set-default-theme &>/dev/null; then
    echo "ERROR: plymouth-set-default-theme not found — is the 'plymouth' package installed?" >&2
    exit 1
fi

echo "[setup-plymouth] Setting default theme to anubis..."
plymouth-set-default-theme anubis

# --- Garante que o módulo plymouth sempre entre no initramfs ------------
# Sem isso, se algum outro script/módulo rodar dracut depois deste e não
# incluir o plymouth explicitamente, o initramfs final pode sair sem o
# tema e o boot cai de volta no logo padrão do Fedora.
echo "[setup-plymouth] Pinning plymouth dracut module via /etc/dracut.conf.d..."
mkdir -p /etc/dracut.conf.d
cat > /etc/dracut.conf.d/10-anubis-plymouth.conf << 'EOF'
add_dracutmodules+=" plymouth "
EOF

# --- COMPILAÇÃO DO INITRAMFS PARA SISTEMAS ATÔMICOS (Ublue/BlueBuild) ---
if command -v dracut &>/dev/null; then
    echo "[setup-plymouth] Building Plymouth theme directly into initramfs via dracut..."

    # Em containers OCI/Containerfiles, o dracut precisa saber exatamente qual
    # versão do kernel alvo usar (o BlueBuild deixa em /usr/lib/modules).
    # --kver e --regenerate-all são mutuamente exclusivos, então quando temos
    # uma versão detectada usamos só --kver — e iteramos sobre TODAS as
    # versões presentes, já que pode haver mais de um kernel instalado.
    mapfile -t KERNEL_VERSIONS < <(ls /usr/lib/modules 2>/dev/null || true)

    if [ "${#KERNEL_VERSIONS[@]}" -gt 0 ]; then
        for KERNEL_VERSION in "${KERNEL_VERSIONS[@]}"; do
            echo "[setup-plymouth] Target kernel detected: $KERNEL_VERSION"
            dracut -f --kver "$KERNEL_VERSION"
        done
    else
        echo "[setup-plymouth] No kernel folder found in /usr/lib/modules, running generic dracut..."
        dracut -f --regenerate-all
    fi
else
    # Fallback para sistemas tradicionais se aplicável fora de containers
    if command -v plymouth-set-default-theme &>/dev/null; then
        plymouth-set-default-theme -R anubis
    fi
fi

echo "[setup-plymouth] Done."
