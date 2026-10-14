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
```

### Download the script directly

```bash
curl -fLO https://raw.githubusercontent.com/exodia03/Exodia-Doctor/main/exodia-doctor.sh
chmod +x exodia-doctor.sh
```

> **Tip:** Review downloaded scripts before executing them.

---

## 🚀 Usage

### 1. Run diagnostics

```bash
./exodia-doctor.sh
```

Start with diagnostic mode to inspect your system and collect relevant information.

### 2. Run an optional system upgrade

```bash
./exodia-doctor.sh --upgrade
```

After confirmation, upgrade mode runs:

```bash
sudo pacman -Syu
```

This performs a full system upgrade; it is not a repair-only operation.

### 3. View diagnostic logs

List the latest reports:

```bash
ls -lt ~/pacman-doctor-logs/
```

Read the latest diagnostic report:

```bash
less "$(ls -t ~/pacman-doctor-logs/diagnostic-*.log | head -n 1)"
```

The exact log filenames depend on the script's implementation.
