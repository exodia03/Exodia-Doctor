#!/usr/bin/env bash
#
# Exodia / Arch Linux Pacman Doctor
# Diagnoses package signature errors, repository/keyring problems,
# failed upgrades, and package file conflicts.
#
# Usage:
#   ./exodia-pacman-doctor.sh
#   ./exodia-pacman-doctor.sh --upgrade
#
# Does not disable signature checks or automatically trust keys.

set -uo pipefail

LOG_DIR="${HOME}/pacman-doctor-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/diagnostic-$(date +%Y%m%d-%H%M%S).log"
UPGRADE_LOG="${LOG_DIR}/upgrade-$(date +%Y%m%d-%H%M%S).log"

# Log diagnostics to both the terminal and a file.
exec > >(tee -a "$LOG_FILE") 2>&1

section() {
    printf '\n\n========== %s ==========\n' "$1"
}

has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

section "System information"
cat /etc/os-release 2>/dev/null || true
printf '\nKernel: '
uname -r
printf 'Date: '
date -Is
printf 'Pacman: '
pacman --version | head -n 1

section "Clock and network"
timedatectl status 2>&1 || true

if has_cmd ping; then
    if ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
        echo "Network IP connectivity: OK"
    else
        echo "WARNING: Cannot ping 1.1.1.1"
    fi

    if ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
        echo "DNS resolution/connectivity: OK"
    else
        echo "WARNING: archlinux.org did not respond."
        echo "Check DNS and network connectivity."
    fi
fi

section "Pacman signature configuration"
pacman-conf SigLevel 2>&1 || true
echo
grep -nE '^\[|^[[:space:]]*(Include|Server|SigLevel)[[:space:]]*=' \
    /etc/pacman.conf 2>/dev/null || true

section "Installed keyrings"
for pkg in archlinux-keyring chaotic-keyring; do
    if pacman -Q "$pkg" 2>/dev/null; then
        :
    else
        echo "$pkg is not installed."
    fi
done

section "Firmware package ownership"
pacman -Q | grep -E '^(linux-firmware|nvidia)' || true

for path in \
    /usr/lib/firmware/nvidia/ad103 \
    /usr/lib/firmware/nvidia/ad104 \
    /usr/lib/firmware/nvidia/ad106 \
    /usr/lib/firmware/nvidia/ad107
do
    if [[ -e "$path" ]]; then
        pacman -Qo "$path" 2>&1 || true
    fi
done

section "Recent package-manager errors"
if [[ -f /var/log/pacman.log ]]; then
    grep -Ei \
        'unknown trust|PGP signature|invalid or corrupted package|conflicting files|failed to commit transaction|keyring' \
        /var/log/pacman.log | tail -n 60 || true
else
    echo "No /var/log/pacman.log found."
fi

section "Diagnosis summary"
echo "Look for these patterns:"
echo
echo "1. 'unknown trust' / 'PGP signature'"
echo "   A signing key is not trusted or a package signature failed."
echo "   Do not disable signature verification or trust keys blindly."
echo
echo "2. 'Unknown host' during key retrieval"
echo "   Check DNS, the keyserver, or the key's WKD service."
echo
echo "3. 'conflicting files'"
echo "   Run pacman -Qo on each reported path to identify its owner."
echo "   Resolve the package transition before removing anything."
echo
echo "4. Old firmware package owns files claimed by a new package"
echo "   Check the distribution's package transition instructions."
echo "   Do not blindly use --overwrite or pacman -Rdd."
echo
echo "Full diagnostic log: $LOG_FILE"

if [[ "${1:-}" != "--upgrade" ]]; then
    cat <<'EOF'

Diagnostic mode only: no packages were installed or removed.

To run the normal full system upgrade after reviewing the report:
  ./exodia-pacman-doctor.sh --upgrade
EOF
    exit 0
fi

section "Upgrade confirmation"
echo "This will run a full system upgrade using pacman -Syu."
echo "Review any package replacements and removal prompts carefully."
read -r -p "Continue with the upgrade? [y/N] " answer

case "$answer" in
    y|Y|yes|YES) ;;
    *)
        echo "Upgrade cancelled."
        exit 0
        ;;
esac

section "Running full system upgrade"
echo "Upgrade output will also be saved to: $UPGRADE_LOG"

set +e
sudo pacman -Syu 2>&1 | tee "$UPGRADE_LOG"
upgrade_status=${PIPESTATUS[0]}
set -e

section "Upgrade result"
if [[ "$upgrade_status" -eq 0 ]]; then
    echo "Pacman completed successfully."
else
    echo "Pacman exited with status $upgrade_status."
    echo "No automatic key trust changes or forced file overwrites were made."
    echo
    echo "Relevant errors from this attempt:"
    grep -Ein \
        'unknown trust|PGP signature|Unknown host|conflicting files|failed to commit transaction|error:' \
        "$UPGRADE_LOG" | tail -n 80 || true

    echo
    echo "If file conflicts occurred, identify each owner's package with:"
    echo "  pacman -Qo /path/reported/by/pacman"
    echo
    echo "If signature errors occurred, check the repository and signing-key"
    echo "instructions before attempting a keyring repair."
fi

echo
echo "Diagnostic log: $LOG_FILE"
echo "Upgrade log:    $UPGRADE_LOG"
exit "$upgrade_status"
