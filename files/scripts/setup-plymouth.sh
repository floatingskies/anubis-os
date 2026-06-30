#!/usr/bin/env bash
set -euo pipefail

# Instala tema Plymouth simples baseado na logo Anubis
THEME_DIR=/usr/share/plymouth/themes/anubis
mkdir -p "$THEME_DIR"

# Copia a logo como splash do Plymouth
install -Dm644 /usr/share/pixmaps/anubis-logo.png \
    "$THEME_DIR/anubis-logo.png"

# Tema Plymouth script
cat > "$THEME_DIR/anubis.plymouth" << 'PLYMOUTH'
[Plymouth Theme]
Name=Anubis OS
Description=Anubis OS boot splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/anubis
ScriptFile=/usr/share/plymouth/themes/anubis/anubis.script
PLYMOUTH

# Plymouth Script API notes:
#   - There is no Rectangle() constructor; use a solid-color PNG or
#     a 1×1 Image trick for the background, or rely on the global bg color.
#   - Sprites must be created with Sprite() (no args) then SetImage() OR
#     Sprite(image). SetZ() controls stacking order (lower = behind).
#   - bg_sprite must be created BEFORE logo_sprite so that logo renders on top
#     (SetZ is the reliable way — we set bg to Z -1 and logo to Z 0).
cat > "$THEME_DIR/anubis.script" << 'SCRIPT'
# ── Background ──────────────────────────────────────────────────────────────
# Plymouth Script has no Rectangle(); create a 1×1 solid image scaled to fill.
bg_image = Image.Text(" ", 1, 1, 0.1, 0.05, 0.18, 1);
bg_scaled = bg_image.Scale(Window.GetWidth(), Window.GetHeight());
bg_sprite = Sprite(bg_scaled);
bg_sprite.SetX(0);
bg_sprite.SetY(0);
bg_sprite.SetZ(-1);

# ── Logo ─────────────────────────────────────────────────────────────────────
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

# Registrar e ativar o tema
plymouth-set-default-theme anubis 2>/dev/null || \
    ln -sf "$THEME_DIR/anubis.plymouth" \
        /usr/share/plymouth/themes/default.plymouth || true
