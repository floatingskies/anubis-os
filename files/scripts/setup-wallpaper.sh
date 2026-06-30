#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR=/usr/share/backgrounds/anubis-os
mkdir -p "$WALLPAPER_DIR"

# O wallpaper já deve estar em files/system/usr/share/backgrounds/anubis-os/
# Este script garante permissões e configura como padrão do GDM também

# Wallpaper global para GDM (tela de login / seleção de idioma)
GDM_DCONF_DIR=/etc/dconf/db/gdm.d
mkdir -p "$GDM_DCONF_DIR"

# NOTE: nome do arquivo deve corresponder ao que existe em
# files/system/usr/share/backgrounds/anubis-os/ — use anubis-wallpaper.png
# como nome canônico para manter consistência com o dconf de extensões.
cat > "$GDM_DCONF_DIR/01-anubis-wallpaper" << 'GDMWALL'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/anubis-os/anubis-wallpaper.png'
picture-uri-dark='file:///usr/share/backgrounds/anubis-os/anubis-wallpaper.png'
picture-options='zoom'
GDMWALL

# Profile do GDM para ler o db gdm
GDM_PROFILE=/etc/dconf/profile/gdm
if [[ ! -f "$GDM_PROFILE" ]]; then
    cat > "$GDM_PROFILE" << 'GDMPROFILE'
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
GDMPROFILE
fi

dconf update
