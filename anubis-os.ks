# =============================================================================
#  Anubis OS — kickstart for ISO install
# -----------------------------------------------------------------------------
#  This kickstart file is consumed by Anaconda (the Fedora installer) when the
#  user runs "Install Anubis OS" from the live ISO. It tells Anaconda to
#  install the Anubis OS OCI image DIRECTLY — NOT Fedora Kinoite + rebase.
#
#  How it works:
#    1. User boots the anubis-os-webui-live ISO
#    2. Anaconda WebUI launches in Firefox
#    3. User picks disk, timezone, etc. via the web UI
#    4. Anaconda reads this kickstart and runs `ostreecontainer` — which pulls
#       the Anubis OS image from GHCR and installs it as the system tree
#    5. First boot is Anubis OS (KDE Plasma 6 + all RPMs + Flatpaks + branding)
#
#  No Fedora Kinoite intermediate step. No post-install rebase needed.
#
#  To customise: edit this file, rebuild the ISO with `bluebuild generate-iso
#  --kickstart anubis-os.ks`.
# =============================================================================

# --- Localization ------------------------------------------------------------
lang en_US.UTF-8
keyboard us
timezone America/Sao_Paulo --utc

# --- Network -----------------------------------------------------------------
network --bootproto=dhcp --device=link --activate
network --hostname=anubis

# --- Installation source — THE KEY LINE -------------------------------------
# `ostreecontainer` tells Anaconda to install an OCI image directly. This is
# what makes the installed system Anubis OS, not Fedora Kinoite.
#
#   --url     → the OCI image to install (Anubis OS from GHCR)
#   --remote  → the ostree remote name (so future `rpm-ostree rebase` works)
#   --transport  → registry (docker:// URL)
#
# Anaconda pulls this image, writes it to /var/lib/containers/storage, and
# sets up the ostree deployment pointing at it. First boot is Anubis OS.
ostreecontainer --url docker://ghcr.io/floatingskies/anubis-os:latest \
                --remote anubis \
                --transport registry

# --- Root account (locked — user creates their account at first boot) -------
rootpw --lock

# --- First-boot setup --------------------------------------------------------
# Enable initial-setup so the user creates their account on first login.
firstboot --enable

# --- Firewall ----------------------------------------------------------------
firewall --enabled --ssh --http --https

# --- Display -----------------------------------------------------------------
xconfig --startxonboot

# --- Bootloader --------------------------------------------------------------
bootloader --location=mbr --append="rhgb quiet"

# --- Services to enable on first boot ----------------------------------------
# (Anaconda's `services` command lets us enable systemd units at install time)
services --enabled=anubis-first-boot.service,anubis-setup-user.service,anubis-boot-verify.service,tuned.service,tuned-ppd.service,irqbalance.service,earlyoom.service,nohang.service,gamemoded.service,firewalld.service,usbguard.service

# --- Packages ----------------------------------------------------------------
# ostreecontainer handles ALL packages — the OCI image already contains every
# RPM. This %packages section is intentionally empty (just signals "use the
# image's package set").
%packages --ignoremissing
# Nothing — the OCI image IS the package set.
%end

# --- Post-install script -----------------------------------------------------
%post --erroronfail
# Re-enable the first-boot units (in case Anaconda's services command didn't
# take effect — defence in depth).
systemctl enable anubis-first-boot.service 2>/dev/null || true
systemctl enable anubis-setup-user.service 2>/dev/null || true
systemctl enable anubis-boot-verify.service 2>/dev/null || true

# Stamp the version file so anubis-first-boot.service's ConditionPathExists works.
mkdir -p /etc/anubis-os
grep '^VERSION_ID=' /usr/lib/os-release | cut -d= -f2 | tr -d '"' > /etc/anubis-os/version

# Make sure the ostree remote is named "anubis" (for future rebases).
if command -v ostree &>/dev/null; then
    ostree remote delete anubis 2>/dev/null || true
    ostree remote add --no-gpg-verify anubis \
        https://ghcr.io/floatingskies/anubis-os 2>/dev/null || true
fi

%end

# --- Reboot after install ----------------------------------------------------
reboot
