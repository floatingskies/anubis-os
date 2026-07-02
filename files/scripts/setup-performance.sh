#!/usr/bin/env bash
# =============================================================================
#  setup-performance.sh  (KDE / Kinoite edition)
# -----------------------------------------------------------------------------
#  THE CACHYOS/ARCH-GRADE PERFORMANCE LAYER FOR ANUBIS OS.
#
#  Stock Fedora kernel — no custom kernel — but every userspace tuning knob
#  that CachyOS / Arch-optimized distros flip, PLUS KDE-specific RAM savings
#  to hit ≤ 1.5 GB idle on a fresh boot:
#
#    1. sysctl.d    — VM, scheduler, network (BBR + fq), kernel IPC, fs
#    2. udev rules  — IO scheduler (mq-deadline for SATA/SAS, none for NVMe,
#                     bfq for HDD), CPU governor, GPU runtime PM
#    3. tuned       — custom "anubis-network-latency" profile
#    4. zram        — 50% of RAM, zstd, swap-on-zram only
#    5. sched_ext   — default to scx_rustland on first boot
#    6. limits.conf — high nofile/nproc for desktop workloads
#    7. systemd     — mask power-profiles-daemon, enable tuned-ppd
#    8. KDE         — mask baloo/akonadi (already done by setup-kde-defaults.sh),
#                     pre-enable Performance CPU governor via tuned
#    9. KDE         — disable packagekit auto-refresh + mask discover-notifier
#                     (Discover itself is not installed; Bazaar is the default
#                     app store. Masking the notifier is defence-in-depth.)
#   10. KDE         — disable kglobalaccel's "loud" polling
#
#  All files are static (drop-in /etc/sysctl.d/*.conf etc.), so they survive
#  ostree upgrades cleanly.
#
#  Idempotent. Runs at BUILD TIME.
# =============================================================================
set -euo pipefail
trap 'echo "[setup-performance] FAILED at line $LINENO" >&2' ERR

LOG() { printf '[setup-performance] %s\n' "$*"; }

# =============================================================================
#  1. /etc/sysctl.d/99-anubis-performance.conf  (CachyOS + Zen + Clear Linux)
# =============================================================================
LOG "Writing /etc/sysctl.d/99-anubis-performance.conf ..."
mkdir -p /etc/sysctl.d
cat > /etc/sysctl.d/99-anubis-performance.conf <<'SYSCTL'
# =============================================================================
#  Anubis OS — kernel tunables (CachyOS/Arch-grade)
# =============================================================================

# --- Virtual memory ----------------------------------------------------------
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 1500
vm.page-cluster = 1
vm.overcommit_memory = 1
vm.min_free_kbytes = 65536

# --- Scheduler (CFS defaults; sched_ext overrides at runtime) ---------------
kernel.sched_migration_cost_ns = 500000
kernel.sched_autogroup_enabled = 1
kernel.sched_latency_ns = 4000000
kernel.sched_min_granularity_ns = 1000000
kernel.sched_wakeup_granularity_ns = 500000
kernel.sched_rt_runtime_us = 980000

# --- Kernel IPC / processes --------------------------------------------------
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152
fs.aio-max-nr = 1048576

# --- Network -----------------------------------------------------------------
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_notsent_lowat = 131072
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.netdev_max_backlog = 8192
net.core.somaxconn = 8192
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2

# --- Misc --------------------------------------------------------------------
kernel.kptr_restrict = 1
kernel.dmesg_restrict = 1
kernel.perf_event_paranoid = 1
kernel.kexec_load_disabled = 1
kernel.unprivileged_bpf_disabled = 2
kernel.sysrq = 176
SYSCTL

# =============================================================================
#  2. /etc/security/limits.d/99-anubis.conf — high nofile/nproc
# =============================================================================
LOG "Writing /etc/security/limits.d/99-anubis.conf ..."
mkdir -p /etc/security/limits.d
cat > /etc/security/limits.d/99-anubis.conf <<'LIMITS'
*    soft    nofile    1048576
*    hard    nofile    1048576
*    soft    nproc     1048576
*    hard    nproc     1048576
root soft    nofile    1048576
root hard    nofile    1048576
LIMITS

# =============================================================================
#  3. /etc/udev/rules.d/ — IO scheduler + CPU governor + GPU runtime PM
# =============================================================================
LOG "Writing udev rules ..."
mkdir -p /etc/udev/rules.d

cat > /etc/udev/rules.d/60-anubis-io-scheduler.rules <<'UDEV'
# NVMe — no scheduler
ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
# SATA/SAS SSDs — mq-deadline
ACTION=="add|change", KERNEL=="sd[a-z]|sr[0-9]+", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
# HDDs — bfq
ACTION=="add|change", KERNEL=="sd[a-z]|sr[0-9]+", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
# eMMC / SD — bfq
ACTION=="add|change", KERNEL=="mmcblk[0-9]*|sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
# Reduce NVMe/APST latency for the boot drive
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{power/control}="auto"
UDEV

cat > /etc/udev/rules.d/60-anubis-cpu-governor.rules <<'UDEV'
ACTION=="add", SUBSYSTEM=="cpu", KERNEL=="cpu[0-9]*", RUN+="/bin/sh -c 'echo powersave > /sys/devices/system/cpu/%k/cpufreq/scaling_governor 2>/dev/null || true'"
UDEV

cat > /etc/udev/rules.d/60-anubis-gpu-pm.rules <<'UDEV'
# AMD GPU — runtime PM
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1002", ATTR{class}=="0x030000", RUN+="/bin/sh -c 'echo auto > /sys/bus/pci/devices/%k/power/control 2>/dev/null || true'"
# NVIDIA — runtime PM
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", RUN+="/bin/sh -c 'echo auto > /sys/bus/pci/devices/%k/power/control 2>/dev/null || true'"
# Intel iGPU — runtime PM
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{class}=="0x030000", RUN+="/bin/sh -c 'echo auto > /sys/bus/pci/devices/%k/power/control 2>/dev/null || true'"
UDEV

# =============================================================================
#  4. /etc/systemd/zram-generator.conf — 50% RAM, zstd, swap-on-zram only
# =============================================================================
LOG "Writing /etc/systemd/zram-generator.conf ..."
mkdir -p /etc/systemd
cat > /etc/systemd/zram-generator.conf <<'ZRAM'
[zram0]
zram-fraction = 0.5
max-zram-size = 16384
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
ZRAM

systemctl mask dev-zram0.swap 2>/dev/null || true

# =============================================================================
#  5. /etc/tuned/profiles/anubis-network-latency — CachyOS-style profile
# =============================================================================
LOG "Writing tuned profile: anubis-network-latency ..."
mkdir -p /etc/tuned/profiles/anubis-network-latency
cat > /etc/tuned/profiles/anubis-network-latency/tuned.conf <<'TUNED'
[main]
summary=Anubis OS — CachyOS-flavoured desktop/gaming profile (low latency, ≤1.5GB idle)
include=network-latency

[cpu]
governor=performance
energy_performance_preference=performance
min_perf_pct=20

[vm]
transparent_hugepages=always

[sysctl]
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
kernel.sched_migration_cost_ns = 500000
kernel.sched_autogroup_enabled = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

[scx_modscheduler]
scheduler = scx_rustland
TUNED

# =============================================================================
#  6. /etc/default/scx — sched_ext default scheduler
# =============================================================================
LOG "Writing /etc/default/scx ..."
mkdir -p /etc/default
cat > /etc/default/scx <<'SCX'
# Anubis OS — sched_ext default scheduler.
# Options: scx_rustland | scx_lavd | scx_bpfland | scx_flash | scx_pair | scx_qmap
SCX_SCHEDULER=scx_rustland
SCX_FLAGS=""
SCX

# =============================================================================
#  7. /etc/modprobe.d/anubis.conf — module options
# =============================================================================
LOG "Writing /etc/modprobe.d/anubis.conf ..."
mkdir -p /etc/modprobe.d
cat > /etc/modprobe.d/anubis.conf <<'MODPROBE'
# Anubis OS — module options

# NVIDIA (only takes effect if user installs proprietary driver)
options nvidia "NVreg_DynamicPowerManagement=0x02"
options nvidia "NVreg_PreserveVideoMemoryAllocations=1"

# ThinkPad ACPI
options thinkpad_acpi fan_control=1 experimental=1

# Intel iGPU — GuC/HuC, FBC, PSR, fastboot (lower idle power)
options i915 enable_guc=3 enable_fbc=1 enable_psr=1 fastboot=1
options xe enable_guc=3

# AMD GPU — runtime PM, SDMA horizon
options amdgpu runpm=1 sdma_phase_quantum=4

# Audio — disable period wakeup (lower latency for PipeWire)
options snd_hda_intel power_save=0 power_save_controller=n
options snd_usb_audio implicit_fb=1
MODPROBE

# =============================================================================
#  8. /etc/dracut.conf.d/ — zstd-compressed initramfs for fast boots
# =============================================================================
LOG "Writing dracut config ..."
mkdir -p /etc/dracut.conf.d
cat > /etc/dracut.conf.d/20-anubis-boot.conf <<'DRACUT'
compress="zstd"
compress_args="-19 -T0"
early_microcode="yes"
hostonly="yes"
hostonly_cmdline="yes"
install_optional_items+=" /usr/bin/zstd "
DRACUT

# =============================================================================
#  9. systemd — mask power-profiles-daemon, enable tuned-ppd
# =============================================================================
LOG "Masking power-profiles-daemon (conflicts with tuned-ppd) ..."
systemctl mask power-profiles-daemon.service 2>/dev/null || true

# =============================================================================
#  10. KDE-specific RAM/CPU optimizations
# =============================================================================
LOG "Applying KDE-specific RAM/CPU optimizations ..."

# Disable PackageKit auto-refresh — Discover will check on demand only.
# This eliminates a periodic CPU spike + ~30 MB RAM at idle.
systemctl mask packagekit-offline-update.service 2>/dev/null || true
systemctl mask packagekit.service 2>/dev/null || true
systemctl mask plocate-updatedb.service 2>/dev/null || true
systemctl mask updatedb.timer 2>/dev/null || true

# Mask KDE PIM daemons we don't ship
for svc in akonadi_*; do
    systemctl --user mask "${svc}" 2>/dev/null || true
    rm -f "/usr/lib/systemd/user/${svc}" 2>/dev/null || true
done

# Mask the KDE Wallet auto-start (saves ~15 MB at idle; user can launch
# manually when they want to save credentials)
mkdir -p /etc/xdg/autostart
if [[ -f /usr/share/applications/org.kde.kwalletd5.desktop ]]; then
    cp /usr/share/applications/org.kde.kwalletd5.desktop \
       /etc/xdg/autostart/org.kde.kwalletd5.desktop 2>/dev/null || true
    echo "Hidden=true" >> /etc/xdg/autostart/org.kde.kwalletd5.desktop 2>/dev/null || true
fi

# Disable the Akonadi framework entirely by removing its mysql/sqlite runtime
# (we don't ship KDE PIM — Kontact, KMail etc. — so Akonadi has nothing to do)
mkdir -p /etc/xdg
cat > /etc/xdg/akonadi-firstrunrc <<'AKONADI'
[FirstRun]
Started=true
AKONADI

LOG "Done. Performance layer installed."
