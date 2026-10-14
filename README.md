# 🩺 Exodia OS Doctor

### Arch Linux Diagnostics & Pacman Troubleshooting

[![Platform](https://img.shields.io/badge/platform-Arch%20Linux-1793D1?logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Language](https://img.shields.io/badge/language-Bash-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![GitHub](https://img.shields.io/badge/GitHub-Exodia--Doctor-181717?logo=github)](https://github.com/exodia03/Exodia-Doctor)

**Exodia Doctor** is a lightweight Bash utility for diagnosing common Arch Linux and Exodia OS package-management issues. It helps investigate Pacman signature errors, keyring problems, failed upgrades, package-file conflicts, and NVIDIA firmware ownership issues.

> [!IMPORTANT]
> Exodia Doctor prioritizes diagnosis over automatic repair. Review the findings before modifying your system.

---

## 📑 Table of Contents

- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Usage](#-usage)
- [Diagnostic Checks](#-diagnostic-checks)
- [NVIDIA Firmware Troubleshooting](#-nvidia-firmware-troubleshooting)
- [Logs](#-logs)
- [Troubleshooting](#-troubleshooting)
- [Safety](#-safety)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

- 🖥️ **System information** — Collects operating system, kernel, and Pacman details.
- 🌐 **Network diagnostics** — Helps investigate connectivity and DNS issues.
- 🕒 **Clock checks** — Displays system time and synchronization information.
- 🔐 **Pacman configuration** — Inspects repository and signature settings.
- 🔑 **Keyring diagnostics** — Checks installed Arch Linux and Chaotic-AUR keyring packages.
- 📦 **Package ownership checks** — Identifies packages owning selected NVIDIA firmware directories.
- 🧾 **Error analysis** — Searches Pacman's logs for common signature, keyring, and file-conflict errors.
- 📝 **Diagnostic reports** — Saves reports to a dedicated log directory.
- ⬆️ **Optional system upgrade** — Offers an interactive full system upgrade after confirmation.

## 🧰 Requirements

- Arch Linux, Exodia OS, or a compatible Arch-based distribution.
- Bash and Pacman.
- `sudo` for system upgrades.
- Standard utilities such as `grep`, `tee`, `date`, and `uname`.

---

## 📥 Installation

### Clone the repository

```bash
git clone https://github.com/exodia03/Exodia-Doctor.git
cd Exodia-Doctor
chmod +x exodia-doctor.sh
Download the script directly
bash
curl -fLO https://raw.githubusercontent.com/exodia03/Exodia-Doctor/main/exodia-doctor.sh
chmod +x exodia-doctor.sh
Tip: Review downloaded scripts before executing them.
🚀 Usage
1. Run diagnostics
bash
./exodia-doctor.sh
Start with diagnostic mode to inspect your system and collect relevant information.
2. Run an optional system upgrade
bash
./exodia-doctor.sh --upgrade
After confirmation, upgrade mode runs:
bash
sudo pacman -Syu
This performs a full system upgrade; it is not a repair-only operation.
3. View diagnostic logs
List the latest reports:
bash
ls -lt ~/pacman-doctor-logs/
Read the latest diagnostic report:
bash
less "$(ls -t ~/pacman-doctor-logs/diagnostic-*.log | head -n 1)"
The exact log filenames depend on the script's implementation.
🔍 Diagnostic Checks
Check	
Purpose
System information	
Identify the operating system, kernel, and Pacman version.
Network connectivity	
Investigate possible network and DNS problems.
System clock	
Check for time-related signature verification issues.
Signature configuration	
Inspect Pacman repository and signature settings.
Keyring packages	
Check whether relevant keyring packages are installed.
Package ownership	
Identify which package owns a conflicting path.
Pacman logs	
Locate recent errors and failed transactions.
🟢 NVIDIA Firmware Troubleshooting
NVIDIA firmware ownership conflicts can occur during package upgrades or package transitions. Exodia Doctor helps investigate these issues without blindly overwriting files.
For example, the following directories may be involved:
text
/usr/lib/firmware/nvidia/ad103/
/usr/lib/firmware/nvidia/ad104/
/usr/lib/firmware/nvidia/ad106/
/usr/lib/firmware/nvidia/ad107/
Step 1: Check installed firmware and NVIDIA packages
bash
pacman -Q | grep -E '^(linux-firmware|nvidia)'
Step 2: Check package ownership
bash
pacman -Qo /usr/lib/firmware/nvidia/ad103
pacman -Qo /usr/lib/firmware/nvidia/ad104
pacman -Qo /usr/lib/firmware/nvidia/ad106
pacman -Qo /usr/lib/firmware/nvidia/ad107
Example output:
text
/usr/lib/firmware/nvidia/ad103/ is owned by linux-firmware 20240220.97b693d2-1
This confirms that the installed linux-firmware package owns the directory. Ownership alone does not indicate a problem.
Step 3: Investigate conflicting files
If Pacman reports a file conflict during an upgrade:
Record the complete error message.
Identify the package that currently owns each conflicting path.
Check installed package versions and repository configuration.
Consult the relevant Arch Linux or distribution-specific package-transition instructions.
Retry the upgrade only after understanding the conflict.
Step 4: Avoid unsafe workarounds
Do not blindly run commands such as:
bash
sudo pacman -Rdd package-name
sudo pacman --overwrite '*' -Syu
These commands can bypass dependency or file-conflict safeguards. Manually deleting firmware files can also damage a package installation.
Recommended approach: Diagnose the actual conflict and use a targeted, documented repair rather than forcing the upgrade.
Note: A directory being owned by linux-firmware is not, by itself, evidence of a problem. The actual conflict message and package metadata determine whether intervention is necessary.
🗂️ Logs
Diagnostic reports are stored in:
text
~/pacman-doctor-logs/
Inspect recent Pacman errors directly:
bash
grep -Ei \
  'unknown trust|PGP signature|invalid or corrupted package|conflicting files|failed to commit transaction|keyring' \
  /var/log/pacman.log | tail -n 60
Before sharing logs publicly, review them for usernames, repository information, and other potentially sensitive details.
🛠️ Troubleshooting
Error	
Recommended action
unknown trust	
Investigate the signing key, keyring, system clock, and repository configuration.
PGP signature failure	
Verify package integrity and signing-key information.
Unknown host	
Check DNS resolution and network connectivity.
conflicting files	
Use pacman -Qo to identify file ownership.
Failed transaction	
Review the complete Pacman error and log.
NVIDIA firmware conflict	
Inspect conflicting paths and package-transition instructions.
Ping failure	
Check connectivity using other methods because ICMP may be blocked.
🔒 Safety
Exodia Doctor is a diagnostic and guided-maintenance tool, not an automatic solution for every package-management issue.
Diagnostic mode is intended to inspect the system without changing installed packages.
Upgrade mode requests confirmation before initiating a full system upgrade.
The script does not automatically disable signature verification.
It does not automatically trust arbitrary signing keys.
It does not automatically remove packages or force file overwrites.
Some errors require manual investigation or distribution-specific instructions.
Always maintain backups and ensure you have a recovery method before performing significant system maintenance.
🗺️ Roadmap
Potential future improvements:

Interactive diagnostic menu.

Automatic NVIDIA GPU detection.

Expanded firmware ownership checks.

Detection of incomplete or interrupted upgrades.

Distribution-aware repair recommendations.

JSON diagnostic reports.

ShellCheck integration and automated tests.

Clearer error severity indicators.

Optional, explicitly confirmed repair actions.
These items are proposed improvements, not necessarily implemented features.
🤝 Contributing
Contributions and suggestions are welcome!
Fork the repository.
Create a feature branch.
Make your changes.
Validate shell syntax:
bash
bash -n exodia-doctor.sh
Run ShellCheck if available:
bash
shellcheck exodia-doctor.sh
Submit a pull request describing your changes and tests.
Please include relevant Pacman error messages when reporting package-management bugs, and redact sensitive information.
📄 License
Check the repository for an existing LICENSE file. If no license exists, add an appropriate open-source license before advertising the project as open source.
