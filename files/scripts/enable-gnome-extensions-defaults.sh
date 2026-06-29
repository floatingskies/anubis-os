#!/usr/bin/env bash
set -euo pipefail

PROFILE=/etc/dconf/profile/user

# ublue-os/Fedora Silverblue's base image typically already ships a
# /etc/dconf/profile/user with "system-db:local" present. Add it only if
# missing, rather than overwriting whatever's already there.
mkdir -p /etc/dconf/profile
if [[ ! -f "$PROFILE" ]]; then
    printf 'user-db:user\nsystem-db:local\n' > "$PROFILE"
elif ! grep -q '^system-db:local$' "$PROFILE"; then
    echo 'system-db:local' >> "$PROFILE"
fi

dconf update
