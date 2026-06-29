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

cat > "$THEME_DIR/anubis.script" << 'SCRIPT'
wallpaper_image = Image("anubis-logo.png");
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();
scale = Math.Min(screen_width / wallpaper_image.GetWidth(),
                 screen_height / wallpaper_image.GetHeight());
scaled = wallpaper_image.Scale(
    wallpaper_image.GetWidth() * scale * 0.4,
    wallpaper_image.GetHeight() * scale * 0.4);
sprite = Sprite(scaled);
sprite.SetX(screen_width  / 2 - scaled.GetWidth()  / 2);
sprite.SetY(screen_height / 2 - scaled.GetHeight() / 2);

# Fundo preto
bg = Rectangle();
bg.SetColor(0.1, 0.05, 0.18, 1);  # roxo escuro
bg.SetWidth(screen_width);
bg.SetHeight(screen_height);
bg_sprite = Sprite(bg);
bg_sprite.SetZ(-100);
SCRIPT

# Registrar e ativar o tema
plymouth-set-default-theme anubis 2>/dev/null || \
    ln -sf "$THEME_DIR/anubis.plymouth" \
        /usr/share/plymouth/themes/default.plymouth || true
