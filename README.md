# Anubis OS — KDE Kinoite edition

> The **CachyOS of Fedora** — a security-minded, gaming-ready, immutable
> Universal Blue image with a DIY **KDE Plasma 6** desktop, modern CLI
> toolbelt, Homebrew layer, and `ujust` management. Targets **≤ 1.5 GB RAM
> at idle** on a fresh boot.

```
                  ▒▓█▓▒
               ▒▓█      █▓▒
            ▒▓█   Anubis   █▓▒
               ▓█   OS   █▓
                  ██████
        ─────────────────────────
        CachyOS-grade perf, stock kernel
        KDE Plasma 6 · Breeze Dark
        RPM-only base · Brew userland
        Ujust-managed · No reinstall ever
```

---

## What this is

Anubis OS is a [Universal Blue](https://universal-blue.org/) / [BlueBuild](https://blue-build.org/)
image layered on top of `ghcr.io/ublue-os/kinoite-main` (KDE Plasma 6 ostree
base). It is **not** a separate distribution — it is an opinionated, atomic,
transactionally-updated overlay on Fedora Kinoite.

| Pillar              | How |
|---------------------|-----|
| **Performance**     | tuned + sched_ext (`scx_rustland`), aggressive sysctl (BBR, fq, low-latency CFS), zram 50%, mq-deadline/none IO schedulers, earlyoom + nohang + ananicy-cpp. |
| **Lean idle**       | Baloo disabled, Akonadi masked, KWin effects trimmed, KDE Connect autostart off, PackageKit auto-refresh masked. **Target: 1.3–1.5 GB RAM at idle.** |
| **DIY / minimal**   | KDE Plasma 6 core app set only (Dolphin, Konsole, Kate, Okular, Gwenview, Spectacle, KCalc, KRDC, KInfoCenter). Every extra app is an opt-in `ujust` command or a Flatpak. |
| **CLI-first**       | eza, bat, fd, ripgrep, fzf, zoxide, delta, btop, fastfetch, starship, oh-my-bash, tmux. |
| **Brew layer**      | Homebrew for userland CLI/GUI apps. Upgradeable in-place, no reinstall needed. |
| **Ujust-managed**   | Every post-install action is a `ujust <recipe>`. Re-run any time. |
| **KDE defaults**    | No GNOME extensions. Stock Plasma 6 with a curated look (Breeze Dark, JetBrains Mono, Anubis wallpaper on desktop + SDDM + lockscreen, Anubis logo on SDDM + KInfoCenter). |
| **RPM-only base**   | Broad x86_64 hardware support (1st-gen Intel Core → current, all AMD64). Stock Fedora kernel — rides Fedora's regular cadence. |
| **Security**        | firewalld, firejail, usbguard, clamav, rkhunter, aide. |

---

## Project layout (BlueBuild convention)

```
anubis-os/
├── recipe.yml                              # BlueBuild recipe — the spine
├── .github/workflows/
│   ├── build.yml                           # CI: image build + smoke test
│   └── iso.yml                             # CI: ISO generation
├── scripts/                                # Build-time scripts (run inside the container)
│   ├── setup-os-release.sh                 # Branding: /usr/lib/os-release
│   ├── setup-hostname.sh                   # Hostname + machine-info
│   ├── setup-logo.sh                       # SDDM + KInfoCenter + icon theme logo
│   ├── setup-plymouth.sh                   # Boot splash theme + initramfs rebuild
│   ├── setup-wallpaper.sh                  # KDE wallpapers + Plasma defaults
│   ├── setup-kde-defaults.sh               # ⚡ Plasma 6 config (dark theme, no Baloo, no Akonadi)
│   ├── setup-performance.sh                # ⚡ CachyOS-grade tuning + KDE RAM savings
│   ├── setup-ohmybash.sh                   # Shell stack in /etc/skel
│   ├── setup-ujust.sh                      # Install ujust recipes
│   ├── setup-brew.sh                       # Ship default Brewfile
│   ├── setup-first-boot.sh                 # Generate systemd units + first-boot scripts
│   ├── enable-first-boot-units.sh          # Enable the units
│   └── set-permissions.sh                  # File modes + SELinux contexts
├── files/                                  # Static files → shipped to / by `files` module
│   └── usr/
│       └── share/
│           ├── wallpapers/anubis-os/       # 7 Anubis wallpapers (KDE path)
│           │   ├── anubis-01-fire-forest.jpg
│           │   ├── anubis-02-firewatch-tower.jpg
│           │   ├── anubis-03-firewatch-wallpaper.jpeg
│           │   ├── anubis-04-jonesy-lake.png
│           │   ├── anubis-05-ol-shoshone.jpg
│           │   ├── anubis-06-tower-of-firewatch.jpeg
│           │   └── anubis-wallpaper.png
│           ├── pixmaps/anubis-logo.png
│           ├── anubis-os/Brewfile
│           ├── ublue-os/just/anubis.just   # 14 ujust recipes
│           └── sddm/themes/anubis/         # Custom SDDM theme dir (populated by setup-logo.sh)
└── README.md
```

---

## Build the image

### Local build

```bash
# 1. Install the BlueBuild CLI
curl -fsSL https://raw.githubusercontent.com/blue-build/cli/main/install.sh | bash

# 2. Build and load into podman
bluebuild build recipe.yml

# 3. (Optional) Push to GHCR
echo "$GITHUB_TOKEN" | skopeo login ghcr.io -u "$USER" --password-stdin
bluebuild build --push recipe.yml
```

### CI build

The included `.github/workflows/build.yml`:
1. Frees ~5 GB of disk space on the runner (kills dotnet, Android SDK, haskell).
2. Builds the image via `blue-build/github-action@v1`.
3. Pushes to `ghcr.io/<owner>/anubis-os:latest`.
4. Signs with cosign (if `COSIGN_PRIVATE_KEY` secret is present).
5. Smoke-tests: pulls the image and verifies `/usr/lib/os-release` has `ID=anubis-os`.

Triggers:
- Push to `main` (only on changes to `recipe.yml`, `scripts/`, `files/`, or the workflow itself)
- Weekly schedule (Mon 06:00 UTC)
- Manual dispatch

Required secrets:

| Secret                | Used for |
|-----------------------|----------|
| `COSIGN_PRIVATE_KEY`  | Image signing (optional) |
| `COSIGN_PASSWORD`     | Image signing (optional) |

---

## Build the ISO

The ISO workflow is **manual-trigger only** (image builds are expensive; ISOs
even more so):

1. Go to **Actions → Build anubis-os ISOs → Run workflow**.
2. Wait ~10 minutes.
3. Download the `iso-anubis-os` artifact (valid 14 days).

The ISO is a live Fedora Kinoite ISO that rebases onto the Anubis OS image on
first boot. All Flatpaks are pre-baked into the image, so the ISO is fully
offline-capable.

---

## Install

### From the ISO
1. Boot the ISO.
2. Click "Install Anubis OS" on the live desktop.
3. Walk through the Fedora installer (Anaconda) — partitioning, timezone, user creation.
4. Reboot. The first-boot systemd units fire automatically.

### By rebasing an existing Kinoite installation

```bash
sudo ostree remote add anubis https://ghcr.io/floatingskies/anubis-os
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/floatingskies/anubis-os:latest
sudo systemctl reboot
```

---

## First boot — what happens

On first boot after install/rebase, two systemd units fire in sequence:

### 1. `anubis-first-boot.service` (system)
- Activates the tuned profile `anubis-network-latency` (CachyOS-style).
- Enables + starts `scx_modscheduler.service` (loads `scx_rustland` BPF scheduler).
- Stamps `/etc/anubis-os/version`.
- Writes `/var/lib/anubis-os/first-boot-complete` (prevents re-running on every boot).
- Triggers `anubis-setup-user.service`.

### 2. `anubis-setup-user.service` (runs as the just-created user)
- Clones Oh My Bash into `~/.oh-my-bash`.
- Installs Starship into `~/.local/bin/starship`.
- Seeds `~/.bashrc`, `~/.zshrc`, `~/.config/starship.toml`, `~/.config/fastfetch/config.jsonc`, `~/.tmux.conf` (only if not already customised).
- Runs `plasma-apply-wallpaperplugin` to set the Anubis wallpaper.
- Runs `plasma-apply-colorscheme BreezeDark`.
- Runs `plasma-apply-cursortheme breeze-dark`.
- Re-disables Baloo (in case Plasma tried to re-enable it).
- Runs `brew bundle` against `~/.config/anubis-os/Brewfile` (copies the default from `/usr/share/anubis-os/Brewfile` on first run).

After ~30 seconds you'll see fastfetch output on your first interactive shell,
with the Anubis logo and a purple Starship prompt.

---

## In-place upgrade — never reinstall

> **You never need to reinstall to upgrade your user environment.** Every
> user-side step is re-runnable via `ujust upgrade-user`. Image upgrades
> (rpm-ostree upgrade) NEVER touch your home directory.

### Three upgrade tiers

| Tier              | Command                  | What it upgrades |
|-------------------|--------------------------|------------------|
| Image (system)    | `rpm-ostree upgrade`     | Base image + layered RPMs. Requires reboot. |
| Flatpaks          | `flatpak update`         | All Flatpak apps. No reboot. |
| User (shell+KDE+brew) | `ujust upgrade-user` | Oh My Bash, Starship, Plasma defaults, Brewfile bundle. No reboot. |

Or do all three at once:

```bash
ujust upgrade-system
```

---

## `ujust` API reference (14 recipes)

```bash
ujust --list                            # discover every recipe
ujust help                              # Anubis-specific help
```

### Setup recipes

| Recipe                  | Description |
|-------------------------|-------------|
| `ujust setup-shell`     | (Re)install Oh My Bash + Starship + Fastfetch. |
| `ujust setup-brew`      | Install Homebrew (if missing) + run `brew bundle`. |
| `ujust setup-gaming`    | Enable gamemode + verify Vulkan/Steam/Lutris. |
| `ujust setup-performance` | Re-apply sysctl + tuned + sched_ext. |
| `ujust setup-kde`       | Re-apply Plasma defaults (dark theme, wallpaper, no Baloo). |
| `ujust wallpaper <name>` | Switch desktop wallpaper (e.g. `anubis-04-jonesy-lake.png`). |

### Switching schedulers

```bash
ujust scheduler rustland   # default — best desktop interactivity
ujust scheduler lavd       # CachyOS default — gaming-focused
ujust scheduler bpfland    # alternative — SMT-friendly
ujust scheduler eevdf      # disable sched_ext, use stock kernel CFS
```

### Switching tuned profiles

```bash
ujust tuned anubis-network-latency   # default
ujust tuned throughput-performance   # for builds/compiles
ujust tuned powersave                # battery
```

### Upgrades

| Recipe                | Description |
|-----------------------|-------------|
| `ujust upgrade-user`  | Re-run shell + KDE + brew setup (no reinstall). |
| `ujust upgrade-brew`  | `brew update && brew upgrade && brew cleanup`. |
| `ujust upgrade-system`| `rpm-ostree upgrade` + `flatpak update` + brew + user. |

### Utilities

| Recipe                  | Description |
|-------------------------|-------------|
| `ujust distrobox-create [name]` | Spin up a Fedora 41 dev container. |
| `ujust cleanup`        | Prune journals, ostree, flatpak unused, brew cache, ~/.cache. |
| `ujust info`           | fastfetch + tuned + sched_ext + DE + ostree status. |

---

## Performance tuning — the CachyOS layer

`scripts/setup-performance.sh` installs:

### sysctl (`/etc/sysctl.d/99-anubis-performance.conf`)
- **VM**: `swappiness=10`, `vfs_cache_pressure=50`, `dirty_ratio=10`, `page-cluster=1` (zram-friendly).
- **Scheduler**: `sched_migration_cost_ns=500000` (better multi-CCX), `sched_autogroup_enabled=1`, low-latency CFS granularity.
- **Network**: `tcp_congestion_control=bbr`, `default_qdisc=fq`, `tcp_ecn=1`, `tcp_fastopen=3`, `tcp_notsent_lowat=131072`.
- **fs**: `inotify.max_user_watches=524288`, `file-max=2097152`, `aio-max-nr=1048576`.

### udev (`/etc/udev/rules.d/60-anubis-*.rules`)
- **NVMe** → `none` scheduler (device has its own queue).
- **SATA SSD** → `mq-deadline`.
- **HDD / eMMC** → `bfq`.
- **CPU governor** → `powersave` (tuned overrides at runtime).
- **GPU runtime PM** → `auto` for AMD/NVIDIA/Intel iGPUs.

### tuned profile (`anubis-network-latency`)
- CPU governor = `performance`
- EPP = `performance`
- THP = `always`
- sched_ext = `scx_rustland`

### zram
50% of RAM, `zstd`-compressed, swap-priority 100. No disk swap.

### sched_ext
`sched_ext` is the Linux kernel's eBPF-based extensible scheduler framework.
Fedora ships it enabled by default (kernel ≥ 6.12). Anubis OS defaults to
`scx_rustland`. Switch at runtime with `ujust scheduler <name>` — no reboot.

### earlyoom + nohang + ananicy-cpp
- `earlyoom` kills misbehaving apps before the kernel OOM killer fires.
- `nohang` warns before memory runs out.
- `ananicy-cpp` auto-renices known background apps so foreground stays snappy.

---

## KDE Plasma — the RAM savings

To hit **≤ 1.5 GB RAM at idle** on a fresh boot, the following are disabled
or masked:

| Component | Action | Savings |
|-----------|--------|---------|
| **plasma-discover** | Not installed — **Bazaar** is the default app store (Flatpak) | ~150 MB |
| **Baloo** (file indexer) | Disabled via `baloofilerc` + service masked | ~50–100 MB |
| **Akonadi** (PIM framework) | Service masked; we don't ship KDE PIM apps | ~30–50 MB |
| **KDE Connect** | Autostart disabled (user can launch manually) | ~20 MB |
| **KWallet** | Autostart disabled (user can launch manually) | ~15 MB |
| **PackageKit auto-refresh** | Service masked | ~30 MB + CPU spikes |
| **plasma-discover-notifier** | Masked (defence-in-depth) | ~20 MB |
| **plocate-updatedb / updatedb.timer** | Masked (we have `fd` and `rg`) | periodic CPU spikes |
| **KWin effects** | Trimmed (no wobbly windows, no magic lamp, no fallapart) | GPU + CPU at idle |
| **Session restore** | Disabled (loginMode=emptySession) | cold-start RAM |

### Where the idle RAM goes (typical 8 GB system)

| Component | RAM |
|-----------|-----|
| Kernel + initramfs | ~150 MB |
| systemd + dbus + journald | ~50 MB |
| NetworkManager + wpa_supplicant / iwd | ~30 MB |
| pipewire + wireplumber | ~30 MB |
| udev + udisks + upower + fwupd | ~40 MB |
| firewalld | ~30 MB |
| tuned + irqbalance + earlyoom + nohang | ~30 MB |
| scx_modscheduler (BPF) | ~10 MB |
| **Plasma shell (plasmashell)** | ~250 MB |
| **KWin** | ~100 MB |
| **SDDM (if logged out)** | ~50 MB |
| **Total** | **~800 MB** |

Plus your user session (Konsole, browser, etc.) — typically 300–500 MB more.
That puts you at **~1.1–1.3 GB at idle**, well under the 1.5 GB target.

### Verify your idle RAM

```bash
ujust info
# Look for the "Mem" line in fastfetch — should show < 1.5 GB used.

free -h
# The "used" column should be under 1.5 GB on a fresh boot.

systemd-cgtop -m -n 1
# Per-cgroup memory breakdown — find what's eating RAM if you're over.
```

---

## App store — Bazaar

Anubis OS ships **[Bazaar](https://github.com/kolunmi/Bazaar)** as the default
software store (a modern Flatpak-only GUI for Flathub). Discover is **not
installed** — Bazaar replaces it entirely.

### Why Bazaar over Discover?

| | Discover | Bazaar |
|---|----------|--------|
| Backend | PackageKit (RPM + Flatpak, slow on ostree) | Flatpak-only (fast, no ostree layering) |
| RAM at idle | ~150 MB | ~50 MB |
| Updates | Tries to update layered RPMs (causes `rpm-ostree upgrade` loops) | Flatpak-only updates (clean, no reboot) |
| UI | Cluttered (5 backends mixed) | Focused (just Flathub, the largest Flatpak repo) |

### Launching Bazaar

- **From the menu**: Applications → System → "Install Software"
- **From the terminal**: `ujust software-store` (or `ujust app-store`)
- **From a browser**: Clicking an `appstream://` link opens Bazaar automatically

### Updating apps

```bash
flatpak update -y                              # all Flatpaks
flatpak uninstall --unused -y                  # remove unused runtimes
# Or via the ujust shortcut:
ujust upgrade-system                           # rpm-ostree + flatpak + brew + user
```

---

## Homebrew layer

Why Homebrew on Fedora/Anubis?
- **Faster updates than Fedora** for fast-moving tools (`k9s`, `helm`, `kubectl`, `gh`, `lazygit`, `mise`, `uv`, `ruff`).
- **Cross-distro**: same tools available inside distrobox containers.
- **User-managed**: no `rpm-ostree install` + reboot dance.

```bash
cp /usr/share/anubis-os/Brewfile ~/.config/anubis-os/Brewfile
$EDITOR ~/.config/anubis-os/Brewfile
ujust setup-brew
```

Your local Brewfile survives every image upgrade.

---

## Security

- **firewalld** — default zone `public`, SSH + HTTP/HTTPS allowed.
- **firejail** — profiles for every GUI app.
- **usbguard** — USB allowlist. Run `usbguard generate-policy` on first boot to whitelist your current devices.
- **clamav** — freshclam enabled, scans on-demand.
- **rkhunter** + **aide** — integrity baseline; run `aide --init` after install.

---

## Troubleshooting

### First boot didn't run user setup
```bash
systemctl status anubis-first-boot.service
systemctl status anubis-setup-user.service
journalctl -u anubis-first-boot.service -b
journalctl -u anubis-setup-user.service -b
```

Re-run manually:
```bash
ujust setup-shell
ujust setup-kde
```

### sched_ext didn't load
```bash
uname -r   # need >= 6.12
lsmod | grep sched_ext
systemctl status scx_modscheduler.service
```

Fallback to EEVDF:
```bash
ujust scheduler eevdf
```

### Wallpapers not showing in Plasma picker
Plasma's wallpaper picker should auto-discover every file under
`/usr/share/wallpapers/anubis-os/`. If it doesn't:
```bash
ujust wallpaper anubis-wallpaper.png   # force-set via plasma-apply-wallpaperplugin
```

### RAM is over 1.5 GB at idle
```bash
systemd-cgtop -m -n 1   # see which cgroup is eating RAM
balooctl6 status         # confirm Baloo is suspended
systemctl --user list-units --state=running   # see user services
```

Common culprits:
- Discover installed via layered RPM → `sudo rpm-ostree uninstall plasma-discover` (Bazaar is the default app store)
- KRunner with baloosearch enabled → `kwriteconfig6 --file krunnerrc --group Plugins --key baloosearchEnabled false`
- Akonadi still running → `akonadictl stop && systemctl --user mask akonadi_*`

### Plymouth shows the Fedora logo
The theme is baked into the initramfs at build time. Re-trigger:
```bash
sudo dracut -f --regenerate-all
```

---

## Hacking on Anubis OS

### Build locally
```bash
bluebuild build recipe.yml
```

### Test the image in a VM
```bash
# Boot the built image directly with podman + qemu
podman run -it --rm \
    -v /dev/kvm:/dev/kvm \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    ghcr.io/floatingskies/anubis-os:latest /bin/bash
```

### Iterate on a script
Every script is idempotent. To re-run one against the live system:
```bash
sudo bash /path/to/script.sh
```

For user-side scripts:
```bash
ujust setup-shell       # or any other recipe
```

### Add a new `ujust` recipe
Edit `files/usr/share/ublue-os/just/anubis.just` and add a new recipe block:
```just
[group('anubis')]
my-recipe:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Hello from my recipe"
```

Rebuild. The recipe shows up in `ujust --list` on the next boot.

### Replace the placeholder logo
```bash
# Replace this with your real Anubis logo (256×256 PNG, transparent background):
files/usr/share/pixmaps/anubis-logo.png
```

Rebuild. The logo will appear on SDDM, KInfoCenter, the icon theme, and
Plymouth.

---

## Credits

- [Universal Blue](https://universal-blue.org/) — the base images + the `ujust` ecosystem.
- [BlueBuild](https://blue-build.org/) — the recipe format + build tooling.
- [CachyOS](https://cachyos.org/) — inspiration for the performance layer + the scx-scheds COPR.
- [Fedora Kinoite](https://kinoite.fedoraproject.org/) — the actual distribution underneath.

Anubis OS is an independent project and is not affiliated with any of the
above.
