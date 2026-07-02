<div align="center">

<img width="200" height="200" alt="anubis-logo" src="https://github.com/user-attachments/assets/d717f027-cf77-4e9d-b129-0ca894f7d930" />

# Anubis OS

The opinionated Fedora. Security-minded, gaming-ready, immutable.

CachyOS-grade performance on a stock kernel. Clean KDE Plasma 6 desktop. Homebrew for userland. `ujust` for everything else. No reinstall, ever.

[![Stars](https://img.shields.io/github/stars/floatingskies/anubis-os?style=for-the-badge&logo=github&color=8b5cf6)](https://github.com/floatingskies/anubis-os/stargazers)
[![Build](https://img.shields.io/github/actions/workflow/status/floatingskies/anubis-os/build.yml?style=for-the-badge&logo=githubactions&label=BUILD)](https://github.com/floatingskies/anubis-os/actions/workflows/build.yml)
[![ISO](https://img.shields.io/github/actions/workflow/status/floatingskies/anubis-os/iso.yml?style=for-the-badge&logo=githubactions&label=ISO)](https://github.com/floatingskies/anubis-os/actions/workflows/iso.yml)
[![License](https://img.shields.io/github/license/floatingskies/anubis-os?style=for-the-badge&color=8b5cf6)](LICENSE)
[![Downloads](https://img.shields.io/github/downloads/floatingskies/anubis-os/total?style=for-the-badge&logo=github&color=8b5cf6)](https://github.com/floatingskies/anubis-os/releases)
[![Fedora](https://img.shields.io/badge/Fedora-44-294172?style=for-the-badge&logo=fedora&logoColor=white)](https://fedoraproject.org/)
[![KDE](https://img.shields.io/badge/KDE-Plasma%206-1d99f3?style=for-the-badge&logo=kde&logoColor=white)](https://kde.org/)
[![BlueBuild](https://img.shields.io/badge/Built%20with-BlueBuild-3b82f6?style=for-the-badge&logo=linuxcontainers&logoColor=white)](https://blue-build.org/)

**Idle RAM:** 1.1 to 1.5 GB &nbsp;·&nbsp; **Boot time:** under 15 seconds &nbsp;·&nbsp; **Reinstall needed:** never

</div>

---

Anubis OS is what happens when you take Fedora Kinoite, strip out everything that doesn't earn its keep, and pour in the kind of performance tuning CachyOS users take for granted. It is not a separate distribution. It is an opinionated, atomic, transactionally updated overlay that rides on top of `ghcr.io/ublue-os/kinoite-main` and ships as an OCI image via [Universal Blue](https://universal-blue.org/) and [BlueBuild](https://blue-build.org/).

The whole thing is built around one idea. You install once. After that, every upgrade, every new tool, every system tweak is something you can do from a running session without ever wiping your home folder. The system is immutable. Your environment is not.

<div align="center">

| | |
|:---|:---|
| **Performance** | tuned + sched_ext with scx_rustland, BBR + fq networking, low latency CFS, zram at 50 percent of RAM, mq-deadline and none IO schedulers, earlyoom,, ananicy-cpp |
| **Lean idle** | Baloo disabled, Akonadi masked, KWin effects trimmed, KDE Connect and KWallet autostart off, PackageKit auto refresh masked, plasma-discover not installed |
| **DIY desktop** | KDE Plasma 6 with just the core apps: Dolphin, Konsole, Kate, Okular, Gwenview, Spectacle, KCalc, KRDC, KInfoCenter. Everything else is a `ujust` command or a Flatpak |
| **CLI first** | eza, bat, fd, ripgrep, fzf, zoxide, delta, btop, fastfetch, starship, oh-my-bash, tmux, and 40 more modern Unix tools |
| **Homebrew** | The full brew layer. Userland apps upgrade in place, no reinstall, no rpm-ostree reboot dance |
| **Ujust** | 70 recipes covering setup, performance, maintenance, diagnostics, fixes, dev tools, and security |
| **Security** | firewalld, firejail, usbguard, clamav, rkhunter, aide. Sensible defaults, nothing paranoid |
| **Hardware** | Stock Fedora kernel, broad x86_64 support from first gen Intel Core through current, all AMD64 |

</div>

---

## Get it

You have three paths into Anubis OS.

### The ISO (recommended for new installs)

Grab the latest `anubis-os-webui-live` ISO from [Releases](https://github.com/floatingskies/anubis-os/releases). Flash it to a USB with [Fedora Writer](https://flathub.org/apps/org.fedoraproject.MediaWriter) or `dd`, boot it, and the live session that comes up IS Anubis OS. KDE Plasma 6, Anubis wallpaper, Anubis Plymouth, all the CLI tools, all the Flatpaks. Firefox auto opens Anaconda's WebUI installer. Click Install, pick your disk, and the same Anubis image gets written to your hard drive. No Fedora Kinoite intermediary at any point.

### Rebase an existing Silverblue or Kinoite install

Already running Fedora Kinoite, Silverblue, Sericea, or any other ostree based system? You can rebase onto Anubis without reinstalling:

```bash
sudo ostree remote add anubis https://ghcr.io/floatingskies/anubis-os
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/floatingskies/anubis-os:latest
sudo systemctl reboot
```

Your home folder, your Flatpaks, your layered RPMs, all of it survives. On reboot you land in Anubis OS with Plasma 6 and the first boot units fire automatically to theme the desktop and clone Oh My Bash.

### Build it yourself

Clone this repo and build locally with [BlueBuild](https://blue-build.org/):

```bash
curl -fsSL https://raw.githubusercontent.com/blue-build/cli/main/install.sh | bash
bluebuild build recipe.yml
```

Or generate a fresh ISO from your local image:

```bash
bluebuild generate-iso --output-dir iso-out --iso-name anubis-os-webui-live image ghcr.io/floatingskies/anubis-os:latest
```

---

## What happens on first boot

Two systemd units fire in sequence, in the background, while you land on the Plasma login screen.

`anubis-first-boot.service` activates the `anubis-network-latency` tuned profile, starts the `scx_rustland` BPF scheduler, stamps the version file, and triggers user setup. It runs once. The `anubis-boot-verify.service` unit then takes over for every subsequent boot, rechecking that Plymouth, wallpaper, tuned, and sched_ext are still in place and silently fixing them if a kernel upgrade or package update clobbered anything.

`anubis-setup-user.service` runs as your just created user account. It clones Oh My Bash into `~/.oh-my-bash`, installs Starship into `~/.local/bin`, seeds your `~/.bashrc`, `~/.zshrc`, `~/.config/starship.toml`, `~/.config/fastfetch/config.jsonc`, and `~/.tmux.conf` from `/etc/skel` (only if you haven't already customised them), calls `plasma-apply-wallpaperplugin` to set the Anubis wallpaper, locks in Breeze Dark as the color scheme, applies the breeze-dark cursor theme, makes sure Baloo stays disabled, and runs `brew bundle` against `~/.config/anubis-os/Brewfile` (copying the default from `/usr/share/anubis-os/Brewfile` on first run).

About 30 seconds after you log in for the first time, you open a terminal and fastfetch prints the Anubis logo with your system info. The prompt is a purple Powerline style Starship. Aliases for eza, bat, fd, rg, fzf, zoxide, delta, and 40 more tools are already wired up. You are home.

---

## The upgrade contract

This is the part that matters. **You never need to reinstall to upgrade your user environment.** Every user side step is re-runnable. Image upgrades via `rpm-ostree upgrade` never touch your home directory. There are three independent upgrade tiers, and they don't depend on each other.

The system tier runs `rpm-ostree upgrade`. That pulls the new base image and any layered RPMs. It requires a reboot. The Flatpak tier runs `flatpak update` and applies to every Flatpak app. No reboot. The user tier runs `ujust upgrade-user`, which re-runs the shell setup, the Plasma defaults, and the brew bundle. No reboot, no reinstall, no data loss.

Or do all three at once:

```bash
ujust upgrade-system
```

---

## The `ujust` API

There are 70 recipes. They cover everything from setup to diagnostics to security. Every one is idempotent. Run any of them as many times as you want.

```bash
ujust --list          # see every recipe
ujust help            # anubis specific help
```

A few highlights:

```bash
ujust setup-shell             # reinstall oh-my-bash + starship
ujust setup-brew              # install or refresh the Homebrew bundle
ujust setup-gaming            # enable gamemode, verify Steam and Lutris
ujust setup-performance       # reapply the CachyOS grade tuning layer
ujust setup-kde               # reapply Plasma defaults, wallpaper, no Baloo
ujust software-store          # launch Bazaar, the default app store
ujust wallpaper <name>        # switch desktop wallpaper
ujust scheduler rustland      # switch sched_ext scheduler at runtime, no reboot
ujust scheduler eevdf         # disable sched_ext, fall back to stock kernel CFS
ujust tuned throughput-performance   # switch tuned profile
ujust snapshot                # tag the current ostree deployment
ujust rollback                # roll back to the previous deployment
ujust gpu-info                # GPU info and driver status
ujust thermal                 # thermal sensors and throttling
ujust audio-fix               # restart pipewire and wireplumber
ujust bluetooth-reset         # reset the bluetooth adapter
ujust plasma-restart          # restart plasmashell without logging out
ujust rebuild-initramfs       # rebuild initramfs for all kernels
ujust health-check            # full system health check
ujust upgrade-user            # rerun every user side step
ujust upgrade-system          # rpm-ostree + flatpak + brew + user in one shot
ujust cleanup                 # prune journals, ostree, flatpak unused, brew cache
ujust info                    # fastfetch + tuned + sched_ext + ostree status
```

Run `ujust help` to see the full list with descriptions.

---

## Performance, the CachyOS way

`scripts/setup-performance.sh` is the layer that makes Anubis feel like CachyOS on a stock Fedora kernel.

The sysctl file at `/etc/sysctl.d/99-anubis-performance.conf` sets VM swappiness to 10, vfs_cache_pressure to 50, dirty ratios low for smoother desktop IO, page-cluster to 1 for zram friendliness, BBR congestion control with fq qdisc, ECN, tcp_fastopen, large socket buffers, and inotify max_user_watches at 524288 so VS Code and JetBrains stop complaining about file watcher limits.

The udev rules at `/etc/udev/rules.d/60-anubis-*.rules` pick the right IO scheduler per device class. NVMe gets none because the device has its own queue and the kernel scheduler just adds overhead. SATA SSDs get mq-deadline for predictable latency under mixed read write workloads. HDDs and eMMC get bfq for fair queuing. CPU governor defaults to powersave at the udev level, but tuned overrides it to performance at runtime. GPU runtime PM is set to auto for AMD, NVIDIA, and Intel iGPUs.

The tuned profile `anubis-network-latency` is a custom profile that inherits from `network-latency` and adds CachyOS style overrides. CPU governor performance, EPP performance, transparent hugepages always, and it reasserts the sysctl values as defence in depth against another profile clobbering them. It also activates the sched_ext scheduler.

zram is configured at 50 percent of RAM, zstd compressed, swap priority 100. No disk swap, no swapfile. The kernel can swap idle pages to zram, which is roughly 10x faster than disk, and free real RAM for active apps.

sched_ext is the Linux kernel's eBPF based extensible scheduler framework. Fedora ships it enabled by default on kernel 6.12 and newer. Anubis installs scx-scheds from the bieszczaders COPR and defaults to `scx_rustland`, the same scheduler CachyOS ships for desktop interactivity. Switch schedulers at runtime with `ujust scheduler <name>`, no reboot. The options are rustland, lavd, bpfland, flash, pair, qmap, and eevdf (which disables sched_ext entirely and falls back to the stock kernel CFS).

earlyoom kills misbehaving apps before the kernel OOM killer fires, which is slow and tends to kill the wrong process. is a userspace OOM avoidance daemon that warns before memory runs out. ananicy-cpp is a process priority daemon that automatically renices known background apps like indexers and builds so the foreground stays snappy.

---

## KDE Plasma, the lean way

The idle RAM target is 1.1 to 1.5 GB on a fresh boot. To hit that, a lot of KDE's default daemons are either disabled or not installed in the first place.

plasma-discover is not installed. Bazaar, a Flatpak only GUI for Flathub, replaces it as the default app store. That alone saves about 150 MB.

Baloo, the file indexer, is disabled via `baloofilerc` and the service is masked. Saves 50 to 100 MB and stops the periodic CPU spikes when it reindexes.

Akonadi, the KDE PIM framework, is masked. We don't ship Kontact, KMail, or any of the PIM apps that depend on it, so Akonadi has nothing to do. Saves 30 to 50 MB.

KDE Connect and KWallet have their autostart entries hidden. Users can launch them manually when they actually want them. Saves 35 MB combined.

PackageKit auto refresh is masked. Discover notifier is masked as defence in depth. plocate and updatedb are masked because we ship fd and ripgrep. KWin effects are trimmed, no wobbly windows, no magic lamp, no fallapart. Session restore is set to empty session so a cold start doesn't try to reload last logout's state.

The result on a typical 8 GB system is about 800 MB of system services at idle, plus 300 to 500 MB for your user session (Konsole, browser, etc.). That puts you around 1.1 to 1.3 GB at idle, comfortably under the 1.5 GB target.

Verify it yourself:

```bash
ujust info            # the Mem line should show under 1.5 GB
free -h               # the used column should be under 1.5 GB on a fresh boot
systemd-cgtop -m -n 1 # per cgroup memory breakdown, find what's eating RAM
```

---

## Bazaar is the app store

Anubis OS ships [Bazaar](https://github.com/kolunmi/Bazaar) as the default software store. It is a modern Flatpak only GUI for Flathub. Discover is not installed.

Discover is a fine tool on a traditional RPM based system, but on ostree it tries to update layered RPMs through PackageKit, which causes `rpm-ostree upgrade` loops and reboots. Bazaar skips all of that. It only manages Flatpaks, which is what you actually want on an immutable system. It uses about a third of the RAM at idle, its updates never require a reboot, and its UI is focused on the one repo that matters.

Launch it from the menu under System, Install Software. Or from the terminal:

```bash
ujust software-store
```

Clicking an `appstream://` link in Firefox opens Bazaar automatically.

---

## Homebrew for userland apps

Homebrew on Fedora sounds weird until you try it. The big win is update speed. Tools like k9s, helm, kubectl, gh, lazygit, mise, uv, and ruff move fast, sometimes faster than Fedora's repos can keep up. Brew gives you the latest version with a single `brew upgrade`. No `rpm-ostree install`, no reboot.

It is also cross distro. The same brew formulas work inside your distrobox containers, so your toolbelt follows you everywhere.

Customise by copying the default Brewfile into your home and editing it:

```bash
cp /usr/share/anubis-os/Brewfile ~/.config/anubis-os/Brewfile
$EDITOR ~/.config/anubis-os/Brewfile
ujust setup-brew
```

Your local Brewfile survives every image upgrade. That is the contract.

---

## Security, sensible

firewalld ships with the default zone set to public, SSH, HTTP, and HTTPS allowed. firejail has profiles for every GUI app. usbguard provides a USB allowlist, run `ujust usbguard-policy` on first boot to generate a policy from your currently connected devices. clamav runs freshclam in the background and scans on demand. rkhunter and aide provide integrity baselines, run `aide --init` after install to seed the database.

Nothing is paranoid. Nothing breaks your workflow. The defaults are tight enough to be safe on a laptop you take to a coffee shop, loose enough to actually use.

---

## Anaconda WebUI Live

The ISO is Anubis OS from the moment you boot it. Not Fedora Kinoite with a rebase queued for later. The live session IS Anubis OS.

When you flash the `anubis-os-webui-live` ISO to a USB and boot it, here is what happens, in order. GRUB loads with an Anubis branded boot menu. Plymouth shows the Anubis logo during early boot. The system auto logs in as the `anubis` live user into a KDE Plasma 6 desktop with the Anubis wallpaper, Breeze Dark theme, and all the CLI tools already installed. Firefox opens automatically and loads Anaconda's WebUI installer at `http://localhost:9090`. You interact with it like a modern web app. Disk partitioning, timezone, account creation, all in a browser tab.

When you click Install in the WebUI, Anaconda uses `ostreecontainer` to pull the same Anubis OCI image you are already running and writes it to your disk. The installed system is identical to the live session. Anubis OS, from the first reboot. No Fedora Kinoite intermediate step at any point.

Two kickstart files make this work. `anubis-live.ks` configures the live session itself: hostname `anubis-live`, auto login, the desktop shortcut to launch the installer, Plymouth theme, and the live user with passwordless sudo. `anubis-os.ks` configures the actual disk install: the Anubis OCI image as the install source, root account locked, `initial-setup` enabled for first login account creation, firewall enabled with SSH HTTP HTTPS, and the Anubis first boot services enabled so they fire on the very first boot of the installed system.

All Flatpaks are pre baked into the image at build time. The ISO is fully offline capable. No Flathub fetch during install, no network needed for the live session.

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
uname -r                              # need 6.12 or newer
lsmod | grep sched_ext
systemctl status scx_modscheduler.service
```

Fall back to the stock kernel CFS:

```bash
ujust scheduler eevdf
```

### Wallpapers not showing in the Plasma picker

Plasma's wallpaper picker should auto discover every file under `/usr/share/wallpapers/anubis-os/`. If it doesn't:

```bash
ujust wallpaper anubis-wallpaper.png   # force set via plasma-apply-wallpaperplugin
```

### RAM is over 1.5 GB at idle

```bash
systemd-cgtop -m -n 1                  # see which cgroup is eating RAM
balooctl6 status                       # confirm Baloo is suspended
systemctl --user list-units --state=running   # see user services
```

Common culprits: Discover installed via layered RPM, in which case `sudo rpm-ostree uninstall plasma-discover`. KRunner with baloosearch enabled, in which case `kwriteconfig6 --file krunnerrc --group Plugins --key baloosearchEnabled false`. Akonadi still running, in which case `akonadictl stop && systemctl --user mask akonadi_*`.

### Plymouth shows the Fedora logo

The theme is baked into the initramfs at build time. If a kernel upgrade clobbered it:

```bash
ujust plymouth-rebuild
```

Or manually:

```bash
sudo dracut -f --regenerate-all
```

The `anubis-boot-verify.service` unit should catch this automatically on the next boot, but the manual command is there if you need it now.

---

## Hacking on Anubis OS

### Build locally

```bash
bluebuild build recipe.yml
```

### Test the image in a VM

```bash
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

For user side scripts:

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

Replace `files/usr/share/pixmaps/anubis-logo.png` with your real Anubis logo, 256x256 PNG with a transparent background. Rebuild. The logo will appear on SDDM, KInfoCenter, the icon theme, and Plymouth.

---

## Project layout

```
anubis-os/
├── recipe.yml                              BlueBuild recipe, the spine of the image
├── anubis-os.ks                            Kickstart for the ISO installer
├── .github/workflows/
│   ├── build.yml                           CI image build with smoke test
│   └── iso.yml                             CI ISO generation, anubis-os-webui-live
├── scripts/                                Build time scripts, run inside the container
│   ├── setup-os-release.sh                 Branding, /usr/lib/os-release
│   ├── setup-hostname.sh                   Hostname and machine info
│   ├── setup-logo.sh                       SDDM, KInfoCenter, icon theme logo
│   ├── setup-plymouth.sh                   Boot splash theme and initramfs rebuild
│   ├── setup-wallpaper.sh                  KDE wallpapers and Plasma defaults
│   ├── setup-kde-defaults.sh               Plasma 6 config, dark theme, no Baloo, no Akonadi
│   ├── setup-bazaar-default.sh             Bazaar as default app store, hide Discover
│   ├── setup-performance.sh                CachyOS grade tuning and KDE RAM savings
│   ├── setup-ohmybash.sh                   Shell stack in /etc/skel
│   ├── setup-ujust.sh                      Install ujust recipes
│   ├── setup-brew.sh                       Ship default Brewfile
│   ├── setup-first-boot.sh                 Generate systemd units and first boot scripts
│   ├── setup-boot-verify.sh                Generate boot verification unit, runs every boot
│   ├── enable-first-boot-units.sh          Enable the first boot units
│   └── set-permissions.sh                  File modes and SELinux contexts
├── files/                                  Static files, shipped to / by the files module
│   └── usr/share/
│       ├── wallpapers/anubis-os/           7 Anubis wallpapers in KDE path
│       ├── pixmaps/anubis-logo.png         The Anubis logo
│       ├── anubis-os/Brewfile              Default Homebrew bundle
│       └── ublue-os/just/anubis.just       70 ujust recipes
└── README.md                               This file
```

---

## Credits

Anubis OS stands on the shoulders of giants.

[Universal Blue](https://universal-blue.org/) provides the base images and the `ujust` ecosystem. [BlueBuild](https://blue-build.org/) provides the recipe format and the build tooling. [CachyOS](https://cachyos.org/) is the inspiration for the performance layer and the scx-scheds COPR. [Fedora Kinoite](https://kinoite.fedoraproject.org/) is the actual distribution underneath. [Bazaar](https://github.com/kolunmi/Bazaar) is the app store. [Oh My Bash](https://github.com/ohmybash/oh-my-bash) and [Starship](https://starship.rs/) make the terminal feel like home.

Anubis OS is an independent project and is not affiliated with any of the above.

---

## License

MIT. See [LICENSE](LICENSE) for details.

<div align="center">

If Anubis OS makes your day better, consider [starring the repo](https://github.com/floatingskies/anubis-os/stargazers).

Made with care, on a thinkpad, in a coffee shop.

</div>
