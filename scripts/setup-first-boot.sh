#!/usr/bin/env bash
# =============================================================================
#  setup-first-boot.sh
# -----------------------------------------------------------------------------
#  Generates the systemd units that drive Anubis OS's first-boot + in-place
#  upgrade story:
#
#    anubis-first-boot.service          (system, runs ONCE on first boot)
#       └─ applies the tuned profile
#       └─ enables + starts scx_modscheduler
#       └─ triggers anubis-setup-user.service
#
#    anubis-setup-user.service          (system, runs as the just-created user)
#       └─ runs /usr/share/anubis-os/scripts/user-shell-setup.sh
#       └─ runs `plasma-apply-wallpaperplugin` to set the KDE wallpaper
#       └─ runs `kwriteconfig6` to lock in dark mode
#       └─ runs `brew bundle` if Homebrew is present
#
#  THE UPGRADE CONTRACT
#  --------------------
#  Every user-side step lives in a re-runnable script (not baked into the
#  image at a fixed point in time). Users can upgrade their HOME environment
#  at any time without reinstalling:
#
#     ujust upgrade-user
#
#  Image upgrades (rpm-ostree upgrade) NEVER touch the user's home directory
#  or their ~/.config/anubis-os/ overrides.
#
#  Idempotent. Runs at BUILD TIME.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-first-boot] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-first-boot] %s\n' "$*"; }

UNIT_DIR=/usr/lib/systemd/system
mkdir -p "$UNIT_DIR"

# =============================================================================
#  1. anubis-first-boot.service
# =============================================================================
LOG "Generating anubis-first-boot.service ..."
cat > "$UNIT_DIR/anubis-first-boot.service" <<'UNIT'
[Unit]
Description=Anubis OS — first-boot system setup (tuned + sched_ext + user setup)
Wants=network-online.target
After=network-online.target systemd-user-sessions.service
ConditionPathExists=!/var/lib/anubis-os/first-boot-complete
ConditionPathExists=/etc/anubis-os/version

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/bin/mkdir -p /var/lib/anubis-os
ExecStart=/usr/share/anubis-os/scripts/first-boot-setup.sh
ExecStartPost=/bin/sh -c 'echo done > /var/lib/anubis-os/first-boot-complete'

[Install]
WantedBy=multi-user.target
UNIT

# =============================================================================
#  2. anubis-setup-user.service
# =============================================================================
LOG "Generating anubis-setup-user.service ..."
cat > "$UNIT_DIR/anubis-setup-user.service" <<'UNIT'
[Unit]
Description=Anubis OS — per-user shell + wallpaper + brew setup
Wants=network-online.target
After=network-online.target anubis-first-boot.service systemd-user-sessions.service
ConditionPathExists=/usr/share/anubis-os/scripts/user-shell-setup.sh

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/share/anubis-os/scripts/run-as-first-user.sh /usr/share/anubis-os/scripts/user-shell-setup.sh

[Install]
WantedBy=multi-user.target
UNIT

# =============================================================================
#  3. first-boot-setup.sh — the script anubis-first-boot.service runs
# =============================================================================
LOG "Generating first-boot-setup.sh ..."
mkdir -p /usr/share/anubis-os/scripts
cat > /usr/share/anubis-os/scripts/first-boot-setup.sh <<'FBS'
#!/usr/bin/env bash
# Anubis OS — first-boot system setup. Idempotent.
set -euo pipefail
LOG() { printf '[anubis-first-boot] %s\n' "$*"; }

# --- Apply tuned profile ----------------------------------------------------
if command -v tuned-adm &>/dev/null; then
    LOG "Activating tuned profile: anubis-network-latency ..."
    tuned-adm profile anubis-network-latency || \
        LOG "WARNING: tuned-adm failed — profile not applied."
else
    LOG "WARNING: tuned-adm not available — skipping tuned profile."
fi

# --- Start scx_modscheduler (sched_ext BPF scheduler) -----------------------
if [[ -f /etc/default/scx ]] && systemctl list-unit-files | grep -q scx_modscheduler.service; then
    LOG "Enabling + starting scx_modscheduler ..."
    systemctl enable --now scx_modscheduler.service 2>/dev/null || \
        LOG "WARNING: scx_modscheduler failed to start — falling back to EEVDF."
fi

# --- Trigger user setup -----------------------------------------------------
LOG "Triggering anubis-setup-user.service ..."
systemctl start anubis-setup-user.service || \
    LOG "WARNING: anubis-setup-user.service failed — user can run 'ujust setup-shell' manually."

# --- Stamp the version file -------------------------------------------------
mkdir -p /etc/anubis-os
cat /usr/lib/os-release | grep VERSION_ID | cut -d= -f2 > /etc/anubis-os/version

LOG "First-boot system setup complete."
FBS
chmod 0755 /usr/share/anubis-os/scripts/first-boot-setup.sh

# =============================================================================
#  4. run-as-first-user.sh — helper: run a command as the first UID >= 1000
# =============================================================================
LOG "Generating run-as-first-user.sh ..."
cat > /usr/share/anubis-os/scripts/run-as-first-user.sh <<'RAFU'
#!/usr/bin/env bash
# Run a command as the first non-system user (UID >= 1000). Used by
# anubis-setup-user.service so the user-side setup runs in the user's home
# directory with the user's UID (so permissions land correctly and KDE
# config files are owned by the user).
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <command...>" >&2
    exit 64
fi

USER_NAME=$(awk -F: '$3 >= 1000 && $3 < 65534 && $7 ~ /(bash|zsh|fish|sh)$/ {print $1; exit}' /etc/passwd || true)

if [[ -z "$USER_NAME" ]]; then
    echo "[run-as-first-user] No login user with UID >= 1000 found yet." >&2
    echo "[run-as-first-user] Skipping — will retry on next boot." >&2
    exit 0
fi

USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
USER_UID=$(getent passwd "$USER_NAME" | cut -d: -3)

echo "[run-as-first-user] Running as $USER_NAME (uid=$USER_UID, home=$USER_HOME) ..."

# Use systemd-run so we get a clean PAM session (XDG_RUNTIME_DIR set,
# dbus session bus available, etc.). Critical for `plasma-apply-wallpaperplugin`
# and `kwriteconfig6` to find the running Plasma shell.
exec systemd-run --uid="$USER_UID" --gid="$USER_UID" \
    --setenv=HOME="$USER_HOME" \
    --setenv=USER="$USER_NAME" \
    --setenv=LOGNAME="$USER_NAME" \
    --setenv=XDG_RUNTIME_DIR="/run/user/$USER_UID" \
    --setenv=DISPLAY="${DISPLAY:-:0}" \
    --setenv=WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}" \
    --setenv=XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-KDE}" \
    --setenv=XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}" \
    --setenv=KDE_FULL_SESSION="${KDE_FULL_SESSION:-true}" \
    --setenv=PATH="/home/linuxbrew/.linuxbrew/bin:$USER_HOME/.local/bin:$USER_HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    --quiet --pipe -- "$@"
RAFU
chmod 0755 /usr/share/anubis-os/scripts/run-as-first-user.sh

# =============================================================================
#  5. user-shell-setup.sh — the script anubis-setup-user.service runs
#     (extends the shell-setup.sh with KDE-specific first-login steps)
# =============================================================================
LOG "Patching user-shell-setup.sh with KDE first-login steps ..."

# We need to APPEND KDE-specific steps to the user-shell-setup.sh that was
# written by setup-ohmybash.sh. Do this by inserting a KDE section before the
# final "Done." line.
if [[ -f /usr/share/anubis-os/scripts/user-shell-setup.sh ]]; then
    # Append KDE-specific steps by inserting before the final "Done." log line.
    sed -i '/^LOG "Done. Open a new shell/i\
# === KDE Plasma first-login steps ============================================\
# Apply the Anubis wallpaper via the official Plasma tool. This is the\
# reliable way to set the wallpaper even if /etc/skel/.config/\
# plasma-org.kde.plasma.desktop-appletsrc was ignored.\
if command -v plasma-apply-wallpaperplugin &>/dev/null; then\
    LOG "Applying Anubis wallpaper via plasma-apply-wallpaperplugin ...";\
    plasma-apply-wallpaperplugin org.kde.image file:///usr/share/wallpapers/anubis-os/anubis-wallpaper.png 2>/dev/null || true\
fi\
\
# Lock the dark color scheme + Anubis color scheme\
if command -v plasma-apply-colorscheme &>/dev/null; then\
    LOG "Applying Breeze Dark color scheme ...";\
    plasma-apply-colorscheme BreezeDark 2>/dev/null || true\
fi\
\
# Apply the cursor theme\
if command -v plasma-apply-cursortheme &>/dev/null; then\
    plasma-apply-cursortheme breeze-dark 2>/dev/null || true\
fi\
\
# Make sure Baloo stays disabled even if Plasma tried to re-enable it\
if command -v balooctl6 &>/dev/null; then\
    balooctl6 suspend 2>/dev/null || true\
    balooctl6 disable 2>/dev/null || true\
elif command -v balooctl &>/dev/null; then\
    balooctl suspend 2>/dev/null || true\
    balooctl disable 2>/dev/null || true\
fi\
' /usr/share/anubis-os/scripts/user-shell-setup.sh
    LOG "user-shell-setup.sh patched with KDE steps."
else
    LOG "WARNING: user-shell-setup.sh not found — setup-ohmybash.sh must run first." >&2
fi

# =============================================================================
#  6. /etc/anubis-os/version — written at build time so ConditionPathExists
#     works on the very first boot.
# =============================================================================
LOG "Stamping /etc/anubis-os/version ..."
mkdir -p /etc/anubis-os
if [[ -f /usr/lib/os-release ]]; then
    grep '^VERSION_ID=' /usr/lib/os-release | cut -d= -f2 | tr -d '"' > /etc/anubis-os/version
else
    echo "0" > /etc/anubis-os/version
fi

LOG "Done. First-boot units + scripts generated."
