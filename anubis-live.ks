# =============================================================================
#  Anubis OS - Live ISO kickstart
# -----------------------------------------------------------------------------
#  This kickstart is used by BlueBuild's `generate-iso` to build the LIVE
#  environment of the ISO. It makes the live session Anubis OS directly -
#  NOT Fedora Kinoite with a rebase queued for later.
#
#  What this does:
#    1. Pulls the Anubis OS OCI image as the live tree (via ostreecontainer)
#    2. Brands the live session: hostname, os-release, Plymouth, wallpaper
#    3. Auto-logs in as the `anubis` live user
#    4. Launches Anaconda WebUI on boot for one-click install
#    5. Pre-bakes Plymouth + initramfs so early boot shows Anubis, not Fedora
#
#  The install kickstart (anubis-os.ks) handles the actual disk install.
# =============================================================================

# --- Localization ------------------------------------------------------------
lang en_US.UTF-8
keyboard us
timezone America/Sao_Paulo --utc

# --- Network -----------------------------------------------------------------
network --bootproto=dhcp --device=link --activate
network --hostname=anubis-live

# --- Installation source - THE ANUBIS IMAGE, NOT FEDORA KINOITE -------------
# ostreecontainer pulls the Anubis OS OCI image and uses it as the live tree.
# When you boot the ISO, the desktop you see IS Anubis OS (KDE Plasma 6,
# Anubis wallpaper, Anubis logo, Anubis Plymouth).
ostreecontainer --url docker://ghcr.io/floatingskies/anubis-os:latest \
                --remote anubis \
                --transport registry

# --- Live session user -------------------------------------------------------
# Create a passwordless live user that auto-logs into the Plasma desktop.
user --name=anubis --password= --gecos="Anubis OS Live" --groups=wheel
autopart --type=plain --fstype=ext4

# --- Bootloader --------------------------------------------------------------
# Custom GRUB menu entry name + kernel args for the live boot.
bootloader --location=mbr --append="rhgb quiet inst.webui=true inst.auto-webui=true liveuser=anubis"

# --- Firewall ----------------------------------------------------------------
firewall --enabled --ssh --http --https

# --- Display -----------------------------------------------------------------
xconfig --startxonboot

# --- First-boot setup --------------------------------------------------------
firstboot --enable

# --- Services ----------------------------------------------------------------
services --enabled=NetworkManager.service,sshd.service,tuned.service,earlyoom.service

# --- Packages ----------------------------------------------------------------
# The live tree IS the Anubis OCI image. These packages are added ON TOP
# for the live session only (installer + live tools).
%packages --ignoremissing
# Anaconda WebUI installer (so the user can install to disk from the live session)
anaconda-webui
anaconda-install-env-deps
initial-setup
initial-setup-gui
# Live session tools
livecd-tools
syslinux
# Kernel + firmware for broad hardware support on the live ISO
kernel
kernel-modules
kernel-modules-extra
linux-firmware
microcode_ctl
# Plymouth (the Anubis theme is already in the OCI image; we just need the binary)
plymouth
plymouth-plugin-script
%end

# --- Post-install: brand the live session as Anubis OS ----------------------
%post --erroronfail
set -x

# --- 1. Hostname ------------------------------------------------------------
echo "anubis-live" > /etc/hostname

# --- 2. os-release (already in the OCI image, but reassert for live) --------
cat > /usr/lib/os-release <<'EOF'
NAME="Anubis OS"
PRETTY_NAME="Anubis OS 44 (Live)"
ID=anubis-os
ID_LIKE=fedora
VERSION_ID=44
VERSION="44 (CachyOS-flavoured Fedora, KDE Plasma)"
HOME_URL="https://github.com/floatingskies/anubis-os"
SUPPORT_URL="https://github.com/floatingskies/anubis-os/issues"
BUG_REPORT_URL="https://github.com/floatingskies/anubis-os/issues"
LOGO=anubis-logo
ANSI_COLOR="0;38;2;139;92;246"
EOF
ln -sf ../usr/lib/os-release /etc/os-release

# --- 3. Live user setup -----------------------------------------------------
# Auto-login on SDDM for the live session
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/01-anubis-live-autologin.conf <<'EOF'
[Autologin]
User=anubis
Session=plasma
EOF

# Give the live user passwordless sudo
echo "anubis ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/anubis-live
chmod 0440 /etc/sudoers.d/anubis-live

# --- 4. Plymouth (already themed in the OCI image, but force-rebuild) ------
if command -v plymouth-set-default-theme &>/dev/null; then
    plymouth-set-default-theme anubis || true
fi
if command -v dracut &>/dev/null; then
    mapfile -t KERNEL_VERSIONS < <(ls /usr/lib/modules 2>/dev/null || true)
    for kv in "${KERNEL_VERSIONS[@]}"; do
        dracut -f --kver "$kv" || true
    done
fi

# --- 5. Desktop icon for "Install Anubis OS" --------------------------------
mkdir -p /usr/share/applications
cat > /usr/share/applications/anubis-install.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Install Anubis OS
GenericName=System Installer
Comment=Install Anubis OS to your hard drive
Exec=anaconda-webui --browser firefox
Icon=anubis-logo
Terminal=false
Categories=System;
Keywords=install;installer;anaconda;anubis;
StartupNotify=true
EOF

# Also put it on the live desktop
mkdir -p /home/anubis/Desktop
cp /usr/share/applications/anubis-install.desktop /home/anubis/Desktop/
chown anubis:anubis /home/anubis/Desktop/anubis-install.desktop
chmod +x /home/anubis/Desktop/anubis-install.desktop

# --- 6. Anaconda WebUI auto-launch on first login ---------------------------
mkdir -p /home/anubis/.config/autostart
cat > /home/anubis/.config/autostart/anubis-webui-installer.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Anubis OS Installer
Comment=Launch the web-based installer
Exec=firefox http://localhost:9090
Icon=anubis-logo
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
chown -R anubis:anubis /home/anubis/.config

# --- 7. Stamp version file --------------------------------------------------
mkdir -p /etc/anubis-os
echo "44-live" > /etc/anubis-os/version

# --- 8. Enable Anubis first-boot services (they'll fire after install) -----
systemctl enable anubis-first-boot.service 2>/dev/null || true
systemctl enable anubis-setup-user.service 2>/dev/null || true
systemctl enable anubis-boot-verify.service 2>/dev/null || true

%end

# --- Reboot ------------------------------------------------------------------
reboot
