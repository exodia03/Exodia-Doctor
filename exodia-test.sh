#!/usr/bin/env bash
#
# exodia-test.sh
# Read-only health and reboot-readiness diagnostic for Exodia / Arch Linux.
#
# Usage:
#   ./exodia-test.sh
#   sudo ./exodia-test.sh
#
# Exit codes:
#   0 = No blocking issues detected
#   1 = Warnings or blockers detected
#
# This script does not guarantee that a reboot will succeed.

set -uo pipefail
export LC_ALL=C

VERSION="1.0.0"
WARNINGS=0
ERRORS=0
CHECKS=0

if [[ -t 1 ]]; then
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    BLUE=$'\033[34m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'
else
    RED="" GREEN="" YELLOW="" BLUE="" BOLD="" RESET=""
fi

pass() {
    printf '  %s[PASS]%s %s\n' "$GREEN" "$RESET" "$*"
}

warn() {
    printf '  %s[WARN]%s %s\n' "$YELLOW" "$RESET" "$*"
    ((WARNINGS += 1))
}

fail() {
    printf '  %s[FAIL]%s %s\n' "$RED" "$RESET" "$*"
    ((ERRORS += 1))
}

section() {
    printf '\n%s== %s ==%s\n' "$BLUE" "$*" "$RESET"
}

run_check() {
    ((CHECKS += 1))
}

printf '%sExodia System Diagnostic v%s%s\n' "$BOLD" "$VERSION" "$RESET"
printf 'Date: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
printf 'Host: %s\n' "$(hostname)"
printf 'Kernel: %s\n' "$(uname -r)"
printf 'User: %s\n' "$(id -un)"

if [[ $EUID -ne 0 ]]; then
    printf '\nNote: Running without root privileges. Some checks may be limited.\n'
fi

# ------------------------------------------------------------
section "1. Operating system and package manager"

run_check
if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    pass "Distribution: ${PRETTY_NAME:-unknown}"
else
    warn "Cannot read /etc/os-release."
fi

run_check
if command -v pacman >/dev/null 2>&1; then
    pass "pacman is available."
else
    fail "pacman is missing. This does not appear to be a normal Arch-based system."
fi

# ------------------------------------------------------------
section "2. Package database and interrupted transactions"

run_check
if [[ -e /var/lib/pacman/db.lck ]]; then
    warn "Pacman lock exists: /var/lib/pacman/db.lck"
    printf '       Check whether another pacman process is running before doing anything.\n'
else
    pass "No pacman database lock found."
fi

run_check
if command -v pacman >/dev/null 2>&1; then
    if pacman -Dk >/dev/null 2>&1; then
        pass "Pacman local database dependency checks passed."
    else
        fail "Pacman database dependency checks failed."
        pacman -Dk 2>&1 | sed 's/^/       /' | head -n 30
    fi
fi

run_check
if command -v pacman >/dev/null 2>&1; then
    if pacman -Q linux-firmware >/dev/null 2>&1; then
        pass "linux-firmware is installed."
        pacman -Q linux-firmware | sed 's/^/       /'
    else
        warn "linux-firmware is not installed under that package name."
    fi
fi

# ------------------------------------------------------------
section "3. Pending package updates"

run_check
if command -v checkupdates >/dev/null 2>&1; then
    updates="$(checkupdates 2>/dev/null)"
    rc=$?

    if [[ $rc -eq 0 && -n "$updates" ]]; then
        warn "Package updates are available:"
        printf '%s\n' "$updates" | head -n 15 | sed 's/^/       /'
        printf '       Update status alone does not mean rebooting is unsafe.\n'
    elif [[ $rc -eq 2 ]]; then
        pass "No pending updates reported by checkupdates."
    else
        warn "Could not determine pending updates; checkupdates returned status $rc."
    fi
else
    warn "checkupdates is unavailable; install pacman-contrib if you want this check."
fi

# ------------------------------------------------------------
section "4. NVIDIA GPU, driver and firmware"

NVIDIA_GPU=0
if command -v lspci >/dev/null 2>&1 &&
   lspci -nn 2>/dev/null | grep -qiE 'VGA compatible controller|3D controller|Display controller' &&
   lspci -nn 2>/dev/null | grep -qi 'NVIDIA'; then
    NVIDIA_GPU=1
fi

if (( NVIDIA_GPU )); then
    pass "An NVIDIA graphics device was detected."
    lspci -nn 2>/dev/null | grep -i 'NVIDIA' | sed 's/^/       /' | head -n 5

    run_check
    if command -v pacman >/dev/null 2>&1; then
        nvidia_packages="$(
            pacman -Qq 2>/dev/null |
            grep -E '^(nvidia|lib32-nvidia|opencl-nvidia|cuda)' || true
        )"

        if [[ -n "$nvidia_packages" ]]; then
            printf '%s\n' "$nvidia_packages" | sed 's/^/       Installed package: /'
        else
            warn "No package with a standard NVIDIA driver name was found."
            printf '       A third-party driver package may use another name.\n'
        fi
    fi

    run_check
    if command -v modinfo >/dev/null 2>&1 &&
       modinfo nvidia >/dev/null 2>&1; then
        pass "The NVIDIA kernel module is available for inspection."
    else
        warn "The NVIDIA kernel module is not available for the running kernel."
        printf '       This can be normal if using nouveau or a different driver.\n'
    fi

    run_check
    if command -v nvidia-smi >/dev/null 2>&1; then
        if nvidia-smi >/dev/null 2>&1; then
            pass "nvidia-smi can communicate with the NVIDIA driver."
            nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null |
                sed 's/^/       /' | head -n 5
        else
            warn "nvidia-smi exists but cannot communicate with the driver."
        fi
    else
        warn "nvidia-smi is unavailable; proprietary NVIDIA driver status is unverified."
    fi

    run_check
    if command -v pacman >/dev/null 2>&1; then
        for chip in ad103 ad104 ad106 ad107; do
            fw="/usr/lib/firmware/nvidia/$chip"
            if [[ -d "$fw" ]]; then
                if pacman -Qo "$fw" >/dev/null 2>&1; then
                    owner="$(pacman -Qo "$fw" 2>/dev/null)"
                    pass "$chip firmware directory exists and is package-owned."
                    printf '       %s\n' "$owner"
                else
                    warn "$fw exists but is not owned by an installed package."
                fi
            else
                # These chips are not present on every NVIDIA GPU.
                printf '  [INFO] %s firmware directory is absent; not required on every GPU.\n' "$chip"
            fi
        done
    fi

    run_check
    if command -v journalctl >/dev/null 2>&1; then
        nvidia_errors="$(
            journalctl -k -b --no-pager -p err 2>/dev/null |
            grep -iE 'nvidia|nouveau|NVRM|firmware' |
            tail -n 10 || true
        )"

        if [[ -n "$nvidia_errors" ]]; then
            warn "Kernel error-level messages related to graphics were found:"
            printf '%s\n' "$nvidia_errors" | sed 's/^/       /'
        else
            pass "No matching graphics-related error-level kernel messages found."
        fi
    fi
else
    printf '  [INFO] No NVIDIA GPU detected by lspci, or lspci is unavailable.\n'
    printf '         NVIDIA-specific checks are skipped.\n'
fi

# ------------------------------------------------------------
section "5. Kernel and boot files"

run_check
if [[ -d /boot ]]; then
    pass "/boot exists."
    df -h /boot 2>/dev/null | sed 's/^/       /'
else
    fail "/boot does not exist."
fi

run_check
if mountpoint -q /boot; then
    pass "/boot is a mounted filesystem."
else
    warn "/boot is not a separate mount point."
    printf '       This may be normal. Verify your boot setup before rebooting after an upgrade.\n'
fi

run_check
if [[ -r /etc/fstab ]]; then
    if findmnt --verify --tab-file /etc/fstab >/dev/null 2>&1; then
        pass "fstab verification passed."
    else
        warn "fstab verification reported a problem; inspect findmnt --verify."
    fi
else
    warn "/etc/fstab is missing or unreadable."
fi

run_check
if command -v bootctl >/dev/null 2>&1 &&
   [[ -d /sys/firmware/efi ]]; then
    if bootctl is-installed >/dev/null 2>&1; then
        pass "systemd-boot appears to be installed."
    else
        printf '  [INFO] systemd-boot is not reported as installed; another bootloader may be used.\n'
    fi
fi

run_check
kernel_images=0
for image in /boot/vmlinuz-* /efi/vmlinuz-*; do
    if [[ -f "$image" ]]; then
        ((kernel_images += 1))
    fi
done

if (( kernel_images > 0 )); then
    pass "Found $kernel_images kernel image(s) in common boot directories."
else
    warn "No kernel images found in /boot or /efi."
    printf '       Your boot partition may be mounted elsewhere; inspect findmnt and bootloader configuration.\n'
fi

run_check
initramfs_images=0
for image in /boot/initramfs-*.img /boot/initramfs-linux.img \
             /boot/initramfs-linux-lts.img /efi/initramfs-*.img; do
    if [[ -f "$image" ]]; then
        ((initramfs_images += 1))
    fi
done

if (( initramfs_images > 0 )); then
    pass "Found $initramfs_images initramfs image(s) in common boot directories."
else
    warn "No common initramfs images found. Verify your kernel and bootloader setup."
fi

# ------------------------------------------------------------
section "6. Disk space"

for mount in / /boot; do
    [[ -e "$mount" ]] || continue

    run_check
    usage="$(df -P "$mount" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}')"

    if [[ "$usage" =~ ^[0-9]+$ ]]; then
        if (( usage >= 95 )); then
            fail "$mount is critically full (${usage}% used)."
        elif (( usage >= 85 )); then
            warn "$mount is running low on space (${usage}% used)."
        else
            pass "$mount has sufficient free space (${usage}% used)."
        fi
    else
        warn "Could not determine disk usage for $mount."
    fi
done

# ------------------------------------------------------------
section "7. Failed systemd services"

run_check
if command -v systemctl >/dev/null 2>&1; then
    failed_units="$(systemctl --failed --no-legend --no-pager 2>/dev/null || true)"

    if [[ -n "$failed_units" ]]; then
        warn "One or more systemd units are failed:"
        printf '%s\n' "$failed_units" | head -n 15 | sed 's/^/       /'
        printf '       Investigate with: systemctl --failed\n'
    else
        pass "No failed systemd units reported."
    fi
else
    warn "systemctl is unavailable."
fi

# ------------------------------------------------------------
section "8. Kernel errors from the current boot"

run_check
if command -v journalctl >/dev/null 2>&1; then
    kernel_errors="$(journalctl -k -b --no-pager -p err 2>/dev/null | tail -n 15 || true)"

    if [[ -n "$kernel_errors" ]]; then
        warn "Kernel error-level messages exist. Review them to determine whether they matter:"
        printf '%s\n' "$kernel_errors" | sed 's/^/       /' | head -n 15
    else
        pass "No kernel error-level messages found in the current boot journal."
    fi
else
    warn "journalctl is unavailable; kernel journal checks were skipped."
fi

# ------------------------------------------------------------
section "9. Reboot-readiness summary"

printf 'Checks run: %d\n' "$CHECKS"
printf '%sWarnings: %d%s\n' "$YELLOW" "$WARNINGS" "$RESET"
printf '%sErrors: %d%s\n' "$RED" "$ERRORS" "$RESET"

if (( ERRORS > 0 )); then
    printf '\n%sDO NOT REBOOT YET%s\n' "$RED" "$RESET"
    printf 'Blocking issues were detected. Review the failures above first.\n'
    exit 1
elif (( WARNINGS > 0 )); then
    printf '\n%sWARNING: REVIEW BEFORE REBOOT%s\n' "$YELLOW" "$RESET"
    printf 'No explicit blocking checks failed, but issues need investigation.\n'
    exit 1
else
    printf '\n%sCHECKS PASSED: REBOOT READINESS LOOKS GOOD%s\n' "$GREEN" "$RESET"
    printf 'No issues were detected by this script. A successful reboot is not guaranteed.\n'
    exit 0
fi
