# =============================================================================
#  Anubis OS — ujust recipes  (KDE / Kinoite edition, expanded)
# -----------------------------------------------------------------------------
#  Sourced automatically by `ujust` on the live system. Every recipe below is
#  idempotent and safe to re-run — that is the Anubis OS upgrade contract:
#  "you never need to reinstall to refresh or fix something; `ujust
#  upgrade-user` re-runs every user-side step."
#
#  Inspired by Bluefin / Aurora / Bazzite ujust tooling.
# =============================================================================

# -----------------------------------------------------------------------------
#  Internals
# -----------------------------------------------------------------------------
anubis_dir := "/usr/share/anubis-os"
anubis_bin := anubis_dir + "/scripts"

[private]
_default := "help"

# Show every Anubis recipe.
[group('anubis')]
help:
    @echo "Anubis OS — ujust recipes (KDE / Kinoite)"
    @echo ""
    @echo "SETUP ==================================================="
    @echo "  ujust setup-shell                 (re)install oh-my-bash + starship"
    @echo "  ujust setup-brew                  install / refresh Homebrew bundle"
    @echo "  ujust setup-gaming                apply gaming tweaks"
    @echo "  ujust setup-performance           re-apply performance layer"
    @echo "  ujust setup-kde                   re-apply KDE Plasma defaults"
    @echo "  ujust setup-boot-verify           re-run boot verification now"
    @echo "  ujust software-store              launch Bazaar (default app store)"
    @echo "  ujust app-store                   alias for software-store"
    @echo ""
    @echo "LOOK & FEEL ============================================="
    @echo "  ujust wallpaper <name>            switch desktop wallpaper"
    @echo "  ujust wallpaper-list              list available wallpapers"
    @echo "  ujust colorscheme <name>          switch Plasma color scheme"
    @echo "  ujust theme-dark                  apply Breeze Dark theme"
    @echo "  ujust theme-light                 apply Breeze Light theme"
    @echo "  ujust cursor <name>               switch cursor theme"
    @echo "  ujust fonts-rebuild               rebuild font cache"
    @echo ""
    @echo "PERFORMANCE ============================================="
    @echo "  ujust scheduler <name>            switch sched_ext scheduler"
    @echo "  ujust tuned <profile>             switch tuned profile"
    @echo "  ujust cpu-governor <name>         set CPU governor"
    @echo "  ujust zram-status                 show zram swap status"
    @echo "  ujust io-scheduler <device> <s>   set IO scheduler for a device"
    @echo ""
    @echo "SYSTEM MAINTENANCE ======================================"
    @echo "  ujust upgrade-user                re-run every user-side step"
    @echo "  ujust upgrade-brew                brew update && upgrade && cleanup"
    @echo "  ujust upgrade-system              full upgrade (rpm-ostree+flatpak+brew)"
    @echo "  ujust cleanup                     prune caches, journals, ostree"
    @echo "  ujust fs-trim                     run fstrim on all SSDs"
    @echo "  ujust snapshot                    create ostree snapshot tag"
    @echo "  ujust rollback                    rollback to previous deployment"
    @echo "  ujust deployments                 list ostree deployments"
    @echo "  ujust rebase-latest               rebase to latest image tag"
    @echo "  ujust pin-current                 pin current deployment (won't auto-cleanup)"
    @echo "  ujust unpin-current               unpin current deployment"
    @echo ""
    @echo "DIAGNOSTICS ============================================="
    @echo "  ujust info                        show system info (fastfetch)"
    @echo "  ujust health-check                full system health check"
    @echo "  ujust gpu-info                    GPU info + driver status"
    @echo "  ujust cpu-info                    CPU info + topology"
    @echo "  ujust memory-map                  memory map per process"
    @echo "  ujust disk-usage                  analyze disk usage"
    @echo "  ujust thermal                     thermal sensors + throttling"
    @echo "  ujust battery                     battery health + cycles"
    @echo "  ujust logs [unit]                 browse journals (or specific unit)"
    @echo "  ujust boot-messages               show this-boot kernel messages"
    @echo "  ujust dmesg                       kernel ring buffer"
    @echo "  ujust list-installed              list layered RPMs"
    @echo "  ujust list-flatpaks               list installed Flatpaks"
    @echo "  ujust list-services               list enabled/disabled systemd services"
    @echo "  ujust list-masked                 list masked systemd services"
    @echo ""
    @echo "FIXES ==================================================="
    @echo "  ujust audio-fix                   restart pipewire + wireplumber"
    @echo "  ujust bluetooth-reset             reset bluetooth adapter"
    @echo "  ujust network-restart             restart NetworkManager"
    @echo "  ujust wayland-restart             restart KWin (Wayland session)"
    @echo "  ujust plasma-restart              restart plasmashell"
    @echo "  ujust rebuild-initramfs           rebuild initramfs for all kernels"
    @echo "  ujust plymouth-rebuild            force-rebuild Plymouth theme into initramfs"
    @echo "  ujust fix-keyring                 fix broken KDE Wallet / keyring"
    @echo "  ujust fix-dbus                    restart user dbus session"
    @echo "  ujust fix-permissions             fix ~/.config + ~/.local permissions"
    @echo ""
    @echo "DEV TOOLS ==============================================="
    @echo "  ujust distrobox-create [name]     spin up a dev container"
    @echo "  ujust distrobox-list              list distrobox containers"
    @echo "  ujust distrobox-prune             remove stopped distroboxes"
    @echo "  ujust install-rpm <pkg>           rpm-ostree install wrapper"
    @echo "  ujust uninstall-rpm <pkg>         rpm-ostree uninstall wrapper"
    @echo "  ujust install-flatpak <id>        flatpak install wrapper"
    @echo "  ujust brew-search <term>          search Homebrew"
    @echo ""
    @echo "SECURITY ================================================"
    @echo "  ujust usbguard-policy             generate usbguard policy"
    @echo "  ujust clamav-scan [path]          scan with clamav"
    @echo "  ujust rkhunter-check              run rkhunter integrity check"
    @echo "  ujust firewall-list               list firewalld zones + rules"
    @echo "  ujust firewall-open <port>        open a TCP port in firewalld"
    @echo "  ujust firewall-close <port>       close a TCP port in firewalld"
    @echo ""
    @echo "  See: https://github.com/floatingskies/anubis-os"

# =============================================================================
#  SETUP RECIPES
# =============================================================================

# (Re)install Oh My Bash + Starship + Fastfetch for the current user.
[group('anubis')]
setup-shell:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: setting up user shell ..."
    exec bash "{{anubis_bin}}/user-shell-setup.sh"

# Install Homebrew (if missing) + run `brew bundle` against the user Brewfile.
[group('anubis')]
setup-brew:
    #!/usr/bin/env bash
    set -euo pipefail
    BREW="${BREW_PATH:-/home/linuxbrew/.linuxbrew/bin/brew}"
    if ! command -v brew &>/dev/null && [[ ! -x "$BREW" ]]; then
        echo "==> Anubis: Homebrew not found — installing ..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    eval "$("$BREW" shellenv)"
    echo "==> Anubis: running brew bundle ..."
    BREWFILE="${BREWFILE:-$HOME/.config/anubis-os/Brewfile}"
    if [[ ! -f "$BREWFILE" ]]; then
        mkdir -p "$(dirname "$BREWFILE")"
        cp /usr/share/anubis-os/Brewfile "$BREWFILE"
    fi
    brew update
    brew bundle --file="$BREWFILE" --verbose
    echo "==> Anubis: brew bundle complete. Edit $BREWFILE to customise."

# Enable gamemode + verify Vulkan/Steam/Lutris are installed.
[group('anubis')]
setup-gaming:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: enabling gaming stack ..."
    systemctl enable --now gamemoded.service 2>/dev/null || true
    echo "    gamemode:  enabled"
    if command -v vulkaninfo &>/dev/null; then
        echo "    Vulkan:    present"
    else
        echo "    Vulkan:    vulkaninfo not installed (rpm-ostree install vulkan-tools)"
    fi
    if flatpak list 2>/dev/null | grep -q com.valvesoftware.Steam; then
        echo "    Steam:     installed (Flatpak)"
    else
        echo "    Steam:     installing (Flatpak) ..."
        flatpak install -y flathub com.valvesoftware.Steam
    fi
    if flatpak list 2>/dev/null | grep -q net.lutris.Lutris; then
        echo "    Lutris:    installed (Flatpak)"
    else
        echo "    Lutris:    installing (Flatpak) ..."
        flatpak install -y flathub net.lutris.Lutris
    fi
    echo "==> Anubis: gaming stack ready."

# Re-apply sysctl + tuned profile + sched_ext scheduler (no reboot needed).
[group('anubis')]
setup-performance:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: re-applying performance layer ..."
    sudo sysctl --system 2>&1 | tail -5 || true
    sudo tuned-adm profile anubis-network-latency 2>/dev/null || \
        echo "    WARNING: tuned not running — enable with 'sudo systemctl enable --now tuned'"
    if [[ -f /etc/default/scx ]]; then
        . /etc/default/scx
        if [[ -n "${SCX_SCHEDULER:-}" ]] && systemctl is-enabled scx_modscheduler.service &>/dev/null; then
            sudo systemctl restart scx_modscheduler.service && \
                echo "    sched_ext: ${SCX_SCHEDULER}"
        fi
    fi
    echo "==> Anubis: performance layer applied."

# Re-apply KDE Plasma defaults (dark theme, wallpaper, fonts, no Baloo).
[group('anubis')]
setup-kde:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: re-applying KDE Plasma defaults ..."
    if command -v plasma-apply-colorscheme &>/dev/null; then
        plasma-apply-colorscheme BreezeDark 2>/dev/null || true
        echo "    colorscheme: BreezeDark"
    fi
    if command -v plasma-apply-wallpaperplugin &>/dev/null; then
        plasma-apply-wallpaperplugin org.kde.image \
            file:///usr/share/wallpapers/anubis-os/anubis-wallpaper.png 2>/dev/null || true
        echo "    wallpaper:   anubis-wallpaper.png"
    fi
    if command -v plasma-apply-cursortheme &>/dev/null; then
        plasma-apply-cursortheme breeze-dark 2>/dev/null || true
        echo "    cursor:      breeze-dark"
    fi
    if command -v balooctl6 &>/dev/null; then
        balooctl6 suspend 2>/dev/null || true
        balooctl6 disable 2>/dev/null || true
        echo "    baloo:       disabled"
    elif command -v balooctl &>/dev/null; then
        balooctl suspend 2>/dev/null || true
        balooctl disable 2>/dev/null || true
        echo "    baloo:       disabled"
    fi
    echo "==> Anubis: KDE Plasma defaults applied."

# Re-run boot verification (Plymouth + wallpaper + tuned + scx) right now.
[group('anubis')]
setup-boot-verify:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: running boot verification ..."
    sudo bash "{{anubis_bin}}/boot-verify.sh"

# Launch Bazaar (the default Anubis OS software store / Flatpak manager).
[group('anubis')]
software-store:
    #!/usr/bin/env bash
    set -euo pipefail
    if flatpak list 2>/dev/null | grep -q io.github.kolunmi.Bazaar; then
        exec flatpak run io.github.kolunmi.Bazaar
    else
        echo "Bazaar not installed. Installing from Flathub ..."
        flatpak install -y flathub io.github.kolunmi.Bazaar
        exec flatpak run io.github.kolunmi.Bazaar
    fi

# Alias: `ujust app-store` does the same thing.
[group('anubis')]
app-store:
    #!/usr/bin/env bash
    set -euo pipefail
    exec ujust software-store

# =============================================================================
#  LOOK & FEEL
# =============================================================================

# List available wallpapers.
[group('anubis')]
wallpaper-list:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Available Anubis OS wallpapers:"
    echo ""
    ls -1 /usr/share/wallpapers/anubis-os/ | grep -iE '\.(png|jpg|jpeg)$' | \
        awk '{printf "  %s\n", $0}'
    echo ""
    echo "Switch with: ujust wallpaper <filename>"

# Switch desktop wallpaper (e.g. `ujust wallpaper anubis-04-jonesy-lake.png`).
[group('anubis')]
wallpaper name='anubis-wallpaper.png':
    #!/usr/bin/env bash
    set -euo pipefail
    NAME="{{name}}"
    WALL="/usr/share/wallpapers/anubis-os/$NAME"
    if [[ ! -f "$WALL" ]]; then
        echo "Available wallpapers:"
        ls /usr/share/wallpapers/anubis-os/
        exit 1
    fi
    if command -v plasma-apply-wallpaperplugin &>/dev/null; then
        plasma-apply-wallpaperplugin org.kde.image "file://$WALL"
        echo "==> Anubis: wallpaper = $NAME"
    else
        echo "ERROR: plasma-apply-wallpaperplugin not available"
        exit 1
    fi

# Switch Plasma color scheme (e.g. `ujust colorscheme BreezeDark`).
[group('anubis')]
colorscheme name='BreezeDark':
    #!/usr/bin/env bash
    set -euo pipefail
    NAME="{{name}}"
    if command -v plasma-apply-colorscheme &>/dev/null; then
        plasma-apply-colorscheme "$NAME"
        echo "==> Anubis: colorscheme = $NAME"
    else
        echo "ERROR: plasma-apply-colorscheme not available"
        exit 1
    fi

# Apply Breeze Dark theme.
[group('anubis')]
theme-dark:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v plasma-apply-colorscheme &>/dev/null; then
        plasma-apply-colorscheme BreezeDark
        echo "==> Anubis: theme = Breeze Dark"
    fi
    if command -v plasma-apply-cursortheme &>/dev/null; then
        plasma-apply-cursortheme breeze-dark
    fi

# Apply Breeze Light theme.
[group('anubis')]
theme-light:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v plasma-apply-colorscheme &>/dev/null; then
        plasma-apply-colorscheme BreezeLight
        echo "==> Anubis: theme = Breeze Light"
    fi
    if command -v plasma-apply-cursortheme &>/dev/null; then
        plasma-apply-cursortheme breeze
    fi

# Switch cursor theme (e.g. `ujust cursor breeze-dark`).
[group('anubis')]
cursor name='breeze-dark':
    #!/usr/bin/env bash
    set -euo pipefail
    NAME="{{name}}"
    if command -v plasma-apply-cursortheme &>/dev/null; then
        plasma-apply-cursortheme "$NAME"
        echo "==> Anubis: cursor = $NAME"
    else
        echo "ERROR: plasma-apply-cursortheme not available"
        exit 1
    fi

# Rebuild the font cache (after installing new fonts).
[group('anubis')]
fonts-rebuild:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: rebuilding font cache ..."
    sudo fc-cache -fv 2>&1 | tail -3
    if command -v gtk-update-icon-cache &>/dev/null; then
        sudo gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
    fi
    echo "==> Anubis: font cache rebuilt."

# =============================================================================
#  PERFORMANCE
# =============================================================================

# Switch the sched_ext scheduler at runtime. Names: lavd, rustland, bpfland, flash, pair, qmap, eevdf.
[group('anubis')]
scheduler name='rustland':
    #!/usr/bin/env bash
    set -euo pipefail
    NAME="{{name}}"
    case "$NAME" in
        lavd|rustland|bpfland|flash|pair|qmap|eevdf) ;;
        *)
            echo "Usage: ujust scheduler <lavd|rustland|bpfland|flash|pair|qmap|eevdf>"
            exit 1
            ;;
    esac
    if [[ "$NAME" == "eevdf" ]]; then
        sudo systemctl disable --now scx_modscheduler.service 2>/dev/null || true
        echo "==> Anubis: sched_ext disabled, using stock EEVDF."
        exit 0
    fi
    if ! command -v "$NAME" &>/dev/null; then
        echo "ERROR: $NAME not installed. (rpm-ostree install scx-scheds)"
        exit 1
    fi
    sudo sed -i "s/^SCX_SCHEDULER=.*/SCX_SCHEDULER=$NAME/" /etc/default/scx
    sudo systemctl restart scx_modscheduler.service 2>/dev/null || \
        sudo systemctl enable --now scx_modscheduler.service
    echo "==> Anubis: sched_ext scheduler = $NAME"

# Switch the active tuned profile.
[group('anubis')]
tuned profile='anubis-network-latency':
    #!/usr/bin/env bash
    set -euo pipefail
    PROFILE="{{profile}}"
    if ! tuned-adm list 2>/dev/null | grep -q "^$PROFILE "; then
        echo "ERROR: tuned profile '$PROFILE' not found."
        echo "Available:"
        tuned-adm list
        exit 1
    fi
    sudo tuned-adm profile "$PROFILE"
    echo "==> Anubis: tuned profile = $PROFILE"

# Set CPU governor (performance, powersave, ondemand, schedutil).
[group('anubis')]
cpu-governor name='performance':
    #!/usr/bin/env bash
    set -euo pipefail
    NAME="{{name}}"
    case "$NAME" in
        performance|powersave|ondemand|schedutil|conservative) ;;
        *)
            echo "Usage: ujust cpu-governor <performance|powersave|ondemand|schedutil|conservative>"
            exit 1
            ;;
    esac
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [[ -f "$cpu" ]] && echo "$NAME" | sudo tee "$cpu" >/dev/null
    done
    echo "==> Anubis: CPU governor = $NAME"

# Show zram swap status.
[group('anubis')]
zram-status:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== zram devices ==="
    sudo zramctl
    echo ""
    echo "=== swap ==="
    swapon --show

# Set IO scheduler for a block device (e.g. `ujust io-scheduler sda mq-deadline`).
[group('anubis')]
io-scheduler device sched='none':
    #!/usr/bin/env bash
    set -euo pipefail
    DEV="{{device}}"
    SCHED="{{sched}}"
    FILE="/sys/block/$DEV/queue/scheduler"
    if [[ ! -f "$FILE" ]]; then
        echo "ERROR: device $DEV not found"
        echo "Available devices:"
        ls /sys/block/
        exit 1
    fi
    AVAILABLE=$(cat "$FILE")
    if ! echo "$AVAILABLE" | grep -q "$SCHED"; then
        echo "ERROR: scheduler $SCHED not available for $DEV"
        echo "Available: $AVAILABLE"
        exit 1
    fi
    echo "$SCHED" | sudo tee "$FILE" >/dev/null
    echo "==> Anubis: $DEV IO scheduler = $SCHED"

# =============================================================================
#  SYSTEM MAINTENANCE
# =============================================================================

# Re-run every user-side setup step (shell + KDE + brew bundle). The Anubis upgrade contract.
[group('anubis')]
upgrade-user:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: upgrading user-side setup (no reinstall needed) ..."
    bash "{{anubis_bin}}/user-shell-setup.sh" || echo "    shell setup:    FAIL (non-fatal)"
    if command -v brew &>/dev/null; then
        BREWFILE="${BREWFILE:-$HOME/.config/anubis-os/Brewfile}"
        [[ -f "$BREWFILE" ]] || cp /usr/share/anubis-os/Brewfile "$BREWFILE"
        brew bundle --file="$BREWFILE" || echo "    brew bundle:     FAIL (non-fatal)"
    fi
    echo "==> Anubis: user upgrade complete."

# Run `brew update && brew upgrade && brew cleanup`.
[group('anubis')]
upgrade-brew:
    #!/usr/bin/env bash
    set -euo pipefail
    eval "$(brew shellenv)" 2>/dev/null || { echo "brew not found"; exit 1; }
    brew update
    brew upgrade
    brew cleanup

# Full system upgrade: rpm-ostree + flatpak + brew + user-side refresh. Reboot to apply rpm-ostree.
[group('anubis')]
upgrade-system:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: rpm-ostree upgrade ..."
    rpm-ostree upgrade
    echo "==> Anubis: flatpak update ..."
    flatpak update -y
    flatpak uninstall --unused -y || true
    echo "==> Anubis: brew upgrade ..."
    if command -v brew &>/dev/null; then
        eval "$(brew shellenv)"
        brew update && brew upgrade && brew cleanup
    fi
    echo "==> Anubis: user-side refresh ..."
    ujust upgrade-user || true
    echo "==> Anubis: full system upgrade complete. Reboot to apply rpm-ostree changes."

# Prune journals, ostree deployments, flatpak unused, brew cache, ~/.cache.
[group('anubis')]
cleanup:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: cleaning journals (keep 7 days) ..."
    sudo journalctl --vacuum-time=7d 2>/dev/null || true
    echo "==> Anubis: cleaning dnf cache ..."
    sudo dnf clean all 2>/dev/null || true
    echo "==> Anubis: cleaning ostree (keep 2 deployments) ..."
    sudo rpm-ostree cleanup -p 2>/dev/null || true
    echo "==> Anubis: cleaning flatpak unused ..."
    flatpak uninstall --unused -y 2>/dev/null || true
    echo "==> Anubis: cleaning brew cache ..."
    if command -v brew &>/dev/null; then
        eval "$(brew shellenv)"
        brew cleanup -s 2>/dev/null || true
    fi
    echo "==> Anubis: clearing ~/.cache ..."
    rm -rf ~/.cache/* 2>/dev/null || true
    echo "==> Anubis: cleanup done."

# Run fstrim on all mounted SSDs (improves write performance + SSD lifespan).
[group('anubis')]
fs-trim:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: running fstrim on all SSDs ..."
    sudo fstrim -av
    echo "==> Anubis: fstrim done."

# Create an ostree snapshot tag for the current deployment.
[group('anubis')]
snapshot:
    #!/usr/bin/env bash
    set -euo pipefail
    TAG="anubis-snapshot-$(date +%Y%m%d-%H%M%S)"
    echo "==> Anubis: creating snapshot tag '$TAG' ..."
    sudo ostree admin pin >/dev/null 2>&1 || true
    sudo ostree refs --create "$TAG" "$(rpm-ostree status --json 2>/dev/null | jq -r '.deployments[0].checksum')" 2>/dev/null || \
        echo "    Note: snapshot tag requires ostree rev — current deployment is pinned instead."
    echo "==> Anubis: snapshot '$TAG' created. Rollback with: ujust rollback"

# Rollback to the previous ostree deployment (reboot to apply).
[group('anubis')]
rollback:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: rolling back to previous deployment ..."
    sudo rpm-ostree rollback
    echo "==> Anubis: rollback queued. Reboot to apply."

# List all ostree deployments.
[group('anubis')]
deployments:
    #!/usr/bin/env bash
    set -euo pipefail
    rpm-ostree status

# Rebase to the latest image tag (e.g. `ujust rebase-latest stable`).
[group('anubis')]
rebase-latest tag='latest':
    #!/usr/bin/env bash
    set -euo pipefail
    TAG="{{tag}}"
    IMAGE="ghcr.io/${ANUBIS_REPO:-floatingskies}/anubis-os:${TAG}"
    echo "==> Anubis: rebasing to $IMAGE ..."
    sudo rpm-ostree rebase ostree-image-signed:docker://"$IMAGE"
    echo "==> Anubis: rebase queued. Reboot to apply."

# Pin current deployment so it survives auto-cleanup.
[group('anubis')]
pin-current:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo ostree admin pin
    echo "==> Anubis: current deployment pinned."

# Unpin current deployment.
[group('anubis')]
unpin-current:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo ostree admin pin --unpin
    echo "==> Anubis: current deployment unpinned."

# =============================================================================
#  DIAGNOSTICS
# =============================================================================

# Show system info (fastfetch + tuned + sched_ext + ostree status).
[group('anubis')]
info:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v fastfetch &>/dev/null; then
        fastfetch
    else
        cat /etc/os-release
        uname -a
    fi
    echo ""
    echo "Tuned profile: $(tuned-adm active 2>/dev/null || echo 'n/a')"
    if [[ -f /etc/default/scx ]]; then
        . /etc/default/scx
        echo "sched_ext:     ${SCX_SCHEDULER:-none}"
    fi
    echo "DE:            ${XDG_CURRENT_DESKTOP:-unknown}"
    echo "ostree:        $(rpm-ostree status 2>/dev/null | grep -E '^\*|^  ostree' | head -2 | xargs)"

# Full system health check.
[group('anubis')]
health-check:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Anubis OS Health Check ==="
    echo ""
    echo "--- OS ---"
    cat /etc/os-release | grep -E '^(NAME|VERSION)='
    echo ""
    echo "--- Kernel ---"
    uname -r
    echo ""
    echo "--- Uptime ---"
    uptime
    echo ""
    echo "--- Memory ---"
    free -h
    echo ""
    echo "--- Disk usage ---"
    df -h / /home /var 2>/dev/null | sort -u
    echo ""
    echo "--- CPU load ---"
    cat /proc/loadavg
    echo ""
    echo "--- tuned ---"
    tuned-adm active 2>/dev/null || echo "  not running"
    echo ""
    echo "--- sched_ext ---"
    if [[ -f /etc/default/scx ]]; then
        . /etc/default/scx
        echo "  configured: ${SCX_SCHEDULER:-none}"
        systemctl is-active scx_modscheduler.service 2>/dev/null | sed 's/^/  service: /'
    fi
    echo ""
    echo "--- zram ---"
    sudo zramctl 2>/dev/null || echo "  not configured"
    echo ""
    echo "--- Plymouth ---"
    plymouth-set-default-theme 2>/dev/null | sed 's/^/  theme: /'
    echo ""
    echo "--- failed systemd units ---"
    systemctl --failed --no-legend 2>/dev/null | head -10 || echo "  none"
    echo ""
    echo "--- Baloo status ---"
    if command -v balooctl6 &>/dev/null; then
        balooctl6 status 2>/dev/null | head -3
    elif command -v balooctl &>/dev/null; then
        balooctl status 2>/dev/null | head -3
    fi
    echo ""
    echo "=== Health check complete ==="

# GPU info + driver status.
[group('anubis')]
gpu-info:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== GPU Info ==="
    lspci | grep -iE 'vga|3d|display' || echo "  no GPU detected via lspci"
    echo ""
    echo "=== Loaded GPU drivers ==="
    lsmod | grep -iE 'nvidia|amdgpu|i915|xe|radeon|nouveau' || echo "  none loaded"
    echo ""
    if command -v vulkaninfo &>/dev/null; then
        echo "=== Vulkan devices ==="
        vulkaninfo --summary 2>/dev/null | grep -A2 'GPU id' || true
    fi
    if command -v glxinfo &>/dev/null; then
        echo "=== OpenGL renderer ==="
        glxinfo 2>/dev/null | grep -E 'OpenGL renderer|OpenGL version' || true
    fi
    echo ""
    echo "=== GPU PCI devices ==="
    lspci -nn | grep -iE 'vga|3d|display' | while read -r line; do
        addr=$(echo "$line" | awk '{print $1}')
        echo "  $line"
        echo "    runtime PM: $(cat /sys/bus/pci/devices/0000:${addr}/power/control 2>/dev/null || echo 'n/a')"
    done

# CPU info + topology.
[group('anubis')]
cpu-info:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== CPU Info ==="
    lscpu | grep -E '^(Architecture|CPU\(s\)|Thread|Core|Socket|Model name|CPU max|CPU min|Virtualization|L1|L2|L3)' || true
    echo ""
    echo "=== Governors ==="
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [[ -f "$cpu" ]] && echo "  $(basename $(dirname $(dirname $cpu))): $(cat $cpu)"
    done | sort -u
    echo ""
    echo "=== Frequencies ==="
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
        [[ -f "$cpu" ]] && echo "  $(basename $(dirname $(dirname $cpu))): $(($(cat $cpu)/1000)) MHz"
    done | sort -u | head -4
    echo ""
    echo "=== Topology ==="
    numactl --hardware 2>/dev/null || lscpu -e=CPU,NODE,SOCKET,CORE

# Memory map per process (top 15 by RSS).
[group('anubis')]
memory-map:
    #!/usr/bin/env bash
    set -euo pipefail
    ps -eo pid,rss,vsz,comm --sort=-rss | head -16

# Analyze disk usage (top 15 directories under /).
[group('anubis')]
disk-usage:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Mounted filesystems ==="
    df -h | grep -vE 'tmpfs|devtmpfs|efivarfs' | sort -u
    echo ""
    echo "=== Top 15 directories under / by size ==="
    sudo du -hx --max-depth=2 / 2>/dev/null | sort -rh | head -15

# Thermal sensors + throttling status.
[group('anubis')]
thermal:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Thermal zones ==="
    for zone in /sys/class/thermal/thermal_zone*; do
        [[ -f "$zone/type" ]] && [[ -f "$zone/temp" ]] || continue
        type=$(cat "$zone/type")
        temp=$(cat "$zone/temp")
        echo "  $(basename $zone): $type = $((temp/1000))C"
    done
    echo ""
    if command -v sensors &>/dev/null; then
        echo "=== lm_sensors ==="
        sensors 2>/dev/null
    else
        echo "  Install lm_sensors for detailed readings: rpm-ostree install lm_sensors"
    fi

# Battery health + cycle count.
[group('anubis')]
battery:
    #!/usr/bin/env bash
    set -euo pipefail
    for bat in /sys/class/power_supply/BAT*; do
        [[ -d "$bat" ]] || continue
        echo "=== $(basename $bat) ==="
        echo "  status:    $(cat $bat/status 2>/dev/null || echo '?')"
        echo "  capacity:  $(cat $bat/capacity 2>/dev/null || echo '?')%"
        echo "  charge:    $(cat $bat/charge_now 2>/dev/null || echo '?') / $(cat $bat/charge_full 2>/dev/null || echo '?')"
        echo "  energy:    $(cat $bat/energy_now 2>/dev/null || echo '?') / $(cat $bat/energy_full 2>/dev/null || echo '?')"
        echo "  cycles:    $(cat $bat/cycle_count 2>/dev/null || echo '?')"
        echo "  health:    $(cat $bat/health 2>/dev/null || echo '?')"
        echo "  model:     $(cat $bat/model_name 2>/dev/null || echo '?')"
    done
    upower -d 2>/dev/null | head -30 || true

# Browse journals (or specific unit: `ujust logs systemd-logind`).
[group('anubis')]
logs unit='':
    #!/usr/bin/env bash
    set -euo pipefail
    UNIT="{{unit}}"
    if [[ -z "$UNIT" ]]; then
        journalctl -p err -b --no-pager | less
    else
        journalctl -u "$UNIT" -b --no-pager | less
    fi

# Show this-boot kernel messages.
[group('anubis')]
boot-messages:
    #!/usr/bin/env bash
    set -euo pipefail
    journalctl -k -b --no-pager | less

# Show kernel ring buffer.
[group('anubis')]
dmesg:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo dmesg --level=err,warn | less

# List layered RPMs (rpm-ostree).
[group('anubis')]
list-installed:
    #!/usr/bin/env bash
    set -euo pipefail
    rpm-ostree status --json 2>/dev/null | \
        jq -r '.deployments[0]["requested-packages"][]' 2>/dev/null || \
        rpm-ostree status

# List installed Flatpaks.
[group('anubis')]
list-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail
    flatpak list --columns=application,name,version,installation,size

# List enabled/disabled systemd services.
[group('anubis')]
list-services:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Enabled services ==="
    systemctl list-unit-files --state=enabled --type=service --no-legend | head -30
    echo ""
    echo "=== Disabled services (top 10) ==="
    systemctl list-unit-files --state=disabled --type=service --no-legend | head -10

# List masked systemd services.
[group('anubis')]
list-masked:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Masked services ==="
    systemctl list-unit-files --state=masked --type=service --no-legend
    echo ""
    echo "=== Masked user services ==="
    systemctl --user list-unit-files --state=masked --type=service --no-legend 2>/dev/null || true

# =============================================================================
#  FIXES
# =============================================================================

# Restart pipewire + wireplumber (fixes audio dropouts).
[group('anubis')]
audio-fix:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: restarting audio stack ..."
    systemctl --user restart pipewire.service
    systemctl --user restart pipewire-pulse.service
    systemctl --user restart wireplumber.service
    echo "==> Anubis: audio stack restarted."

# Reset bluetooth adapter (fixes pairing issues).
[group('anubis')]
bluetooth-reset:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: resetting bluetooth ..."
    sudo systemctl restart bluetooth.service
    sleep 2
    bluetoothctl power off 2>/dev/null || true
    sleep 1
    bluetoothctl power on 2>/dev/null || true
    echo "==> Anubis: bluetooth reset."

# Restart NetworkManager.
[group('anubis')]
network-restart:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: restarting NetworkManager ..."
    sudo systemctl restart NetworkManager.service
    echo "==> Anubis: NetworkManager restarted."

# Restart KWin (Wayland session) without logging out.
[group('anubis')]
wayland-restart:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: restarting KWin (Wayland) ..."
    systemctl --user restart plasma-kwin_wayland.service 2>/dev/null || \
        kwin_wayland --replace &
    echo "==> Anubis: KWin restarted."

# Restart plasmashell (KDE panel + desktop).
[group('anubis')]
plasma-restart:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: restarting plasmashell ..."
    systemctl --user restart plasma-plasmashell.service 2>/dev/null || \
        kquitapp6 plasmashell && kstart plasmashell
    echo "==> Anubis: plasmashell restarted."

# Rebuild initramfs for all installed kernels.
[group('anubis')]
rebuild-initramfs:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: rebuilding initramfs for all kernels ..."
    mapfile -t KERNEL_VERSIONS < <(ls /usr/lib/modules 2>/dev/null || true)
    if (( ${#KERNEL_VERSIONS[@]} == 0 )); then
        echo "  no kernels found in /usr/lib/modules"
        exit 1
    fi
    for kv in "${KERNEL_VERSIONS[@]}"; do
        echo "  -> $kv"
        sudo dracut -f --kver "$kv"
    done
    echo "==> Anubis: initramfs rebuilt. Reboot to apply."

# Force-rebuild Plymouth theme into initramfs.
[group('anubis')]
plymouth-rebuild:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: force-rebuilding Plymouth theme ..."
    sudo plymouth-set-default-theme anubis
    ujust rebuild-initramfs
    echo "==> Anubis: Plymouth rebuilt into initramfs. Reboot to apply."

# Fix broken KDE Wallet / keyring.
[group('anubis')]
fix-keyring:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: fixing KDE Wallet ..."
    systemctl --user restart plasma-kwalletd5.service 2>/dev/null || true
    systemctl --user restart plasma-kwalletd6.service 2>/dev/null || true
    echo "==> Anubis: KDE Wallet restarted. If still broken, run 'kwalletmanager5' or 'kwalletmanager6'."

# Restart user dbus session (fixes weird KDE bugs).
[group('anubis')]
fix-dbus:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: restarting user dbus ..."
    systemctl --user restart dbus.service
    echo "==> Anubis: user dbus restarted."

# Fix ~/.config + ~/.local permissions (in case something got owned by root).
[group('anubis')]
fix-permissions:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: fixing home directory permissions ..."
    USER_NAME=$(whoami)
    USER_UID=$(id -u)
    sudo chown -R "$USER_NAME:$USER_NAME" "$HOME/.config" "$HOME/.local" "$HOME/.cache" 2>/dev/null || true
    chmod 700 "$HOME/.config" "$HOME/.local" 2>/dev/null || true
    echo "==> Anubis: permissions fixed."

# =============================================================================
#  DEV TOOLS
# =============================================================================

# Create a Fedora 41 distrobox dev container (default name: dev).
[group('anubis')]
distrobox-create name='dev':
    #!/usr/bin/env bash
    set -euo pipefail
    NAME="{{name}}"
    echo "==> Anubis: creating distrobox '$NAME' (Fedora 41) ..."
    distrobox create --name "$NAME" --image registry.fedoraproject.org/fedora:41 \
        --pre-init-hooks "sudo dnf install -y neovim git fish zsh" \
        --yes
    echo "==> Anubis: enter with 'distrobox enter $NAME'"

# List distrobox containers.
[group('anubis')]
distrobox-list:
    #!/usr/bin/env bash
    set -euo pipefail
    distrobox list

# Remove stopped distrobox containers.
[group('anubis')]
distrobox-prune:
    #!/usr/bin/env bash
    set -euo pipefail
    distrobox list | tail -n +2 | awk '{print $2}' | while read -r name; do
        echo "  removing: $name"
        distrobox rm --force "$name"
    done
    echo "==> Anubis: stopped distroboxes removed."

# Install an RPM package (rpm-ostree install wrapper; requires reboot).
[group('anubis')]
install-rpm pkg:
    #!/usr/bin/env bash
    set -euo pipefail
    PKG="{{pkg}}"
    echo "==> Anubis: installing $PKG (rpm-ostree) ..."
    sudo rpm-ostree install "$PKG"
    echo "==> Anubis: $PKG installed. Reboot to apply."

# Uninstall an RPM package (rpm-ostree uninstall wrapper).
[group('anubis')]
uninstall-rpm pkg:
    #!/usr/bin/env bash
    set -euo pipefail
    PKG="{{pkg}}"
    echo "==> Anubis: uninstalling $PKG (rpm-ostree) ..."
    sudo rpm-ostree uninstall "$PKG"
    echo "==> Anubis: $PKG uninstalled. Reboot to apply."

# Install a Flatpak from flathub.
[group('anubis')]
install-flatpak id:
    #!/usr/bin/env bash
    set -euo pipefail
    ID="{{id}}"
    echo "==> Anubis: installing $ID (flathub) ..."
    flatpak install -y flathub "$ID"
    echo "==> Anubis: $ID installed."

# Search Homebrew for a formula or cask.
[group('anubis')]
brew-search term:
    #!/usr/bin/env bash
    set -euo pipefail
    TERM="{{term}}"
    eval "$(brew shellenv 2>/dev/null)" || { echo "brew not found"; exit 1; }
    brew search "$TERM"

# =============================================================================
#  SECURITY
# =============================================================================

# Generate usbguard policy based on currently-connected USB devices.
[group('anubis')]
usbguard-policy:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: generating usbguard policy from connected devices ..."
    sudo usbguard generate-policy > /tmp/usbguard-policy.conf
    echo "  Policy written to /tmp/usbguard-policy.conf"
    echo "  Review it, then install with:"
    echo "    sudo install -m 600 /tmp/usbguard-policy.conf /etc/usbguard/rules.conf"
    echo "    sudo systemctl restart usbguard"

# Scan a path with clamav (default: home directory).
[group('anubis')]
clamav-scan path='./':
    #!/usr/bin/env bash
    set -euo pipefail
    PATH_TO_SCAN="{{path}}"
    echo "==> Anubis: scanning $PATH_TO_SCAN with clamav ..."
    sudo freshclam 2>/dev/null || true
    clamscan -r --infected "$PATH_TO_SCAN" || true
    echo "==> Anubis: scan complete."

# Run rkhunter integrity check.
[group('anubis')]
rkhunter-check:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Anubis: running rkhunter ..."
    sudo rkhunter --update
    sudo rkhunter --check --sk
    echo "==> Anubis: rkhunter check complete."

# List firewalld zones + active rules.
[group('anubis')]
firewall-list:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Active zones ==="
    sudo firewall-cmd --get-active-zones
    echo ""
    echo "=== All zones + services ==="
    sudo firewall-cmd --list-all-zones | grep -E '^(zone|  services|  ports|  target)' | head -40

# Open a TCP port in firewalld.
[group('anubis')]
firewall-open port:
    #!/usr/bin/env bash
    set -euo pipefail
    PORT="{{port}}"
    sudo firewall-cmd --add-port="$PORT/tcp" --permanent
    sudo firewall-cmd --add-port="$PORT/tcp"
    echo "==> Anubis: TCP port $PORT opened."

# Close a TCP port in firewalld.
[group('anubis')]
firewall-close port:
    #!/usr/bin/env bash
    set -euo pipefail
    PORT="{{port}}"
    sudo firewall-cmd --remove-port="$PORT/tcp" --permanent
    sudo firewall-cmd --remove-port="$PORT/tcp"
    echo "==> Anubis: TCP port $PORT closed."
