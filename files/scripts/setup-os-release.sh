#!/usr/bin/env bash
# =============================================================================
#  setup-os-release.sh
# -----------------------------------------------------------------------------
#  Replaces /usr/lib/os-release with Anubis OS branding.
#  Idempotent. Runs at BUILD TIME.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-os-release] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-os-release] %s\n' "$*"; }

LOG "Writing /usr/lib/os-release ..."

cat > /usr/lib/os-release <<'OSRELEASE'
NAME="Anubis OS"
PRETTY_NAME="Anubis OS 44 (KDE Plasma)"
ID=anubis-os
ID_LIKE=fedora
VERSION_ID=44
VERSION="44 (CachyOS-flavoured Fedora, KDE Plasma)"
VERSION_CODENAME=""
PLATFORM_ID="platform:f44"
HOME_URL="https://github.com/floatingskies/anubis-os"
SUPPORT_URL="https://github.com/floatingskies/anubis-os/issues"
BUG_REPORT_URL="https://github.com/floatingskies/anubis-os/issues"
DOCUMENTATION_URL="https://github.com/floatingskies/anubis-os/wiki"
LOGO=anubis-logo
ANSI_COLOR="0;38;2;139;92;246"
CPE_NAME="cpe:/o:floatingskies:anubis-os:44"
SUPPORT_END="2026-05-01"
OSRELEASE

# /etc/os-release is normally a symlink to /usr/lib/os-release.
rm -f /etc/os-release
ln -sf ../usr/lib/os-release /etc/os-release

LOG "Done."
