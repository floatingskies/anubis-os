#!/usr/bin/env bash
set -euo pipefail

# Ensure custom .just files are readable in the ujust menu
chmod 644 /usr/share/ublue-os/just/60-anubis.just

# Sysctl hardening drop-in ships disabled-by-default (commented), readable by all
chmod 644 /etc/sysctl.d/80-anubis-hardening.conf

# Wallpaper picker script + unit
chmod 755 /usr/share/anubis-os/scripts/anubis-pick-wallpaper.sh
chmod 644 /usr/lib/systemd/system/anubis-first-boot-wallpaper.service
chmod 644 /usr/share/backgrounds/anubis-os/*

# GNOME extensions default-enable dconf override
chmod 644 /etc/dconf/db/local.d/00-anubis-extensions
