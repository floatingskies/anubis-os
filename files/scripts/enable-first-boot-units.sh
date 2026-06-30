#!/usr/bin/env bash
set -euo pipefail

# These unit files must already exist in /usr/lib/systemd/system/
# (shipped via the files module) before this script runs.
systemctl enable anubis-first-boot-wallpaper.service
systemctl enable anubis-setup-user.service
