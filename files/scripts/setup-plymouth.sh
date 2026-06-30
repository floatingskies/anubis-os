#!/usr/bin/env bash
set -euo pipefail
trap 'echo "[setup-plymouth] FAILED at line $LINENO" >&2' ERR

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

cat > "$THEME_DIR/anubis.script" << 'SCRIPT'
bg_image = Image.Text(" ", 1, 1, 0.1, 0.05, 0.18, 1);
bg_scaled = bg_image.Scale(Window.GetWidth(), Window.GetHeight());
bg_sprite = Sprite(bg_scaled);
bg_sprite.SetX(0);
bg_sprite.SetY(0);
bg_sprite.SetZ(-1);

logo_image = Image("anubis-logo.png");
screen_width  = Window.GetWidth();
screen_height = Window.GetHeight();

scale = Math.Min(
    screen_width  / logo_image.GetWidth(),
    screen_height / logo_image.GetHeight()
) * 0.4;

logo_scaled = logo_image.Scale(
    logo_image.GetWidth()  * scale,
    logo_image.GetHeight() * scale
);

logo_sprite = Sprite(logo_scaled);
logo_sprite.SetX(screen_width  / 2 - logo_scaled.GetWidth()  / 2);
logo_sprite.SetY(screen_height / 2 - logo_scaled.GetHeight() / 2);
logo_sprite.SetZ(0);
SCRIPT

if command -v plymouth-set-default-theme &>/dev/null; then
    plymouth-set-default-theme anubis 2>/dev/null || true
else
    ln -sf "$THEME_DIR/anubis.plymouth" \
        /usr/share/plymouth/themes/default.plymouth 2>/dev/null || true
fi

echo "[setup-plymouth] Done."
