# anubis-os

A GNOME-based, gaming- and everyday-security-focused immutable Linux desktop, built on [BlueBuild](https://blue-build.org) / [Universal Blue](https://universal-blue.org).

This image is **not** a pentesting distro. Security tooling here is defensive/privacy-oriented (firewall, antivirus, rootkit scanning, app sandboxing, per-app network monitoring) — there is no BlackArch/Kali layer and no offensive tooling shipped or scripted in.

## Desktop

- **GNOME** (Silverblue base), customized with:
  - **Dash to Dock**
  - **AppIndicator and KStatusNotifierItem Support** (tray icons)
  - **Blur my Shell**
  - **Arc Menu** (logo/app menu)
  - **Caffeine**
  - **PaperWM**
- Bundled wallpapers, **one chosen at random on first boot** (see "Wallpapers" below).

## Apps

- **Browser:** Brave (default)
- **Office:** OnlyOffice Desktop Editors
- **Creative:** GIMP, Inkscape, Pinta
- **Gaming:** Steam, Gamescope (SteamOS-style session), GameMode, MangoHud, Lutris, Wine, ProtonUp-Qt, Heroic
- **Homebrew** wired in via BlueBuild's `brew` module for anything not packaged as RPM/Flatpak

## Performance

[CachyOS kernel](https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos/) — **generic build by default**, compatible from 1st-gen Intel Core through current Intel/AMD, so old hardware always boots. CPU-tuned (`znver3`/`znver4`) builds and sched-ext schedulers are opt-in via `ujust`, never default.

## Security (defensive, not offensive)

firewalld, ClamAV, rkhunter, AIDE, Firejail, OpenSnitch — all toggled on as a bundle via `ujust enable-hardened-profile`, since full lockdown by default breaks too much for a general-purpose desktop.

## Hardware support / automatic detection

- **Broadcom Wi-Fi** (`broadcom-wl` akmod) — covers most older MacBooks and many third-party laptops/desktops.
- **fwupd** — automatic firmware updates for BIOS/EC/peripherals, no manual driver hunting.
- **NetworkManager + bluez** — automatic Wi-Fi/Bluetooth detection and pairing out of the box.
- Kernel modules load automatically via standard udev/kmod mechanisms — there's no special "auto-connect" step needed beyond having the right driver present, which is what the akmods modules above guarantee at build time.

### MacBook Air (2013 / 2015 / 2017) variant

`recipes/recipe-macbook.yml` adds the **FaceTime HD webcam driver** (out-of-tree, via COPR) on top of Broadcom Wi-Fi. These models predate Apple's T2 chip, so no T2 hardware-bridge drivers are needed — Broadcom + FaceTime HD covers essentially everything that doesn't work out of the box.

**Apple Silicon MacBook Airs (M1/M2/M3) are out of scope.** They need [Asahi Linux](https://asahilinux.org/)'s own kernel/bootloader stack — a different boot pipeline entirely, not something a BlueBuild recipe can add.

### Self-sustaining update story

- `rpm-ostree` auto-updates the base image (staged, applied on reboot) via the standard ublue-os update timer.
- `fwupd` keeps firmware current automatically.
- `ujust anubis-update-all` is a single command that upgrades the OS, Flatpaks, Homebrew, and firmware in one pass for anyone who wants to trigger it manually.

## Wallpapers

⚠️ **Copyright note for maintainers:** the wallpaper set currently staged in this scaffold is built from fan-made *Firewatch*-style artwork/screenshots. Some of these closely mirror the official game's box art and promotional screenshots (Campo Santo / Panic). **Do not publish these exact files in a public repo or public OCI image** without confirming you have rights to redistribute them — bundling them as a distro default risks both a copyright claim and (if anyone notices the resemblance) brand confusion with the actual game. For a public release, either:
- commission/create original artwork in a similar style, or
- ship no wallpapers by default and offer a separate, clearly-labeled "Firewatch-inspired wallpaper pack" as an optional `ujust` download with attribution and a link to buy/support the game, or
- keep this exact set for your own personal/local builds only (not pushed to GHCR or a public repo).

Mechanism (works regardless of which images you end up shipping):
- Wallpapers live in `/usr/share/backgrounds/anubis-os/`.
- A oneshot systemd unit (`anubis-first-boot-wallpaper.service`) runs on first boot, picks one at random, and writes it as the default via a dconf override.
- `ujust reroll-wallpaper` lets a user re-randomize at any time after first boot.

## Installation

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/floatingskies/anubis-os:latest
systemctl reboot
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/floatingskies/anubis-os:latest
systemctl reboot
```

For the older MacBook Air variant, replace `anubis-os` with `anubis-os-macbook`.

## `ujust` command menu

Run `ujust` with no arguments for the full menu, including:

- `ujust detect-cpu`, `ujust switch-kernel-znver3`, `ujust switch-kernel-znver4` — opt-in CPU-tuned kernel builds
- `ujust enable-scx-scheduler` — CachyOS-style sched-ext scheduler
- `ujust enable-hardened-profile` — defensive security toggle bundle
- `ujust reroll-wallpaper` — pick a new random default wallpaper
- `ujust anubis-update-all` — update OS, Flatpaks, Homebrew, and firmware in one pass

## Verification

```bash
cosign verify --key cosign.pub ghcr.io/floatingskies/anubis-os
```

## Maintainer TODO

- [ ] Resolve the wallpaper copyright question above before any public push.
- [ ] Verify the FaceTime HD COPR repo URL/package name against the current snapshot before building — COPR repos drift.
- [ ] Confirm `gnome-extensions` module extension IDs against the current BlueBuild module syntax (ID numbers correspond to extensions.gnome.org listings and can be matched to UUIDs there if the module needs UUIDs instead of IDs).
- [ ] Consider adding `tlp`/`power-profiles-daemon` tuning specifically for the 2013-era MacBook Air, where battery life matters more than on newer hardware.
- [ ] Factor duplicated package blocks between `recipe.yml` and `recipe-macbook.yml` into shared custom modules once both are stable.
