🩺 Exodia Doctor
Arch Linux Diagnostics & Pacman Troubleshooting

![Platform](https://img.shields.io/badge/platform-Arch%20Linux-1793D1?logo=arch-linux&logoColor=white) ![Language](https://img.shields.io/badge/language-Bash-4EAA25?logo=gnubash&logoColor=white) ![License](https://img.shields.io/badge/license-Choose%20a%20license-lightgrey)

Exodia Doctor is a lightweight Bash utility designed to diagnose common Arch Linux and Exodia OS package-management issues. It collects system information, inspects Pacman configuration, checks package signatures and keyrings, examines recent package errors, and investigates NVIDIA firmware file ownership.

Whether you're troubleshooting a failed system upgrade, a PGP signature error, or a firmware conflict after updating your system, Exodia Doctor helps you gather the information needed to identify the problem safely.

[!IMPORTANT]
Exodia Doctor prioritizes diagnosis over automatic repair. Diagnostic mode does not install, remove, or overwrite packages. Upgrade mode runs pacman -Syu only after explicit confirmation. It does not disable signature verification or automatically trust signing keys.
📑 Table of Contents
Features
Use Cases
Requirements
Installation
Usage
Diagnostic Checks
NVIDIA Firmware Troubleshooting
Log Files
Troubleshooting Guide
Safety and Limitations
Roadmap
Contributing
License
✨ Features
Feature	Description
🖥️ System information	Reports distribution details, kernel version, date, and Pacman version.
🌐 Network diagnostics	Checks basic IP connectivity and DNS/network access.
🕒 Clock diagnostics	Displays system time and synchronization information.
🔐 Signature configuration	Inspects Pacman signature settings and repository configuration.
🔑 Keyring checks	Reports installed Arch Linux and Chaotic-AUR keyring packages.
📦 Package ownership	Identifies packages owning selected NVIDIA firmware directories.
🧾 Error analysis	Searches the Pacman log for signature, keyring, and file-conflict errors.
📝 Diagnostic reports	Saves terminal output to timestamped log files.
⬆️ Optional system upgrade	Offers an interactive full system upgrade with pacman -Syu.
🛡️ Safety-first behavior	Avoids automatic key trust changes, forced overwrites, and package removals.
🎯 Use Cases

Exodia Doctor is useful when:

A system upgrade fails because of package-file conflicts.
Pacman reports unknown trust or PGP signature errors.
A keyring appears outdated or a signing key cannot be retrieved.
NVIDIA firmware directories are involved in a package conflict.
You want to inspect recent package-manager errors after a system update.
You need a diagnostic report to share when asking for technical support.
🧰 Requirements
Arch Linux, Exodia OS, or a compatible Arch-based distribution.
Bash.
Pacman.
sudo for the optional system upgrade.
Standard system utilities such as grep, tee, date, and uname.

The script uses ping when available. A failed ping does not necessarily mean that the internet is unavailable, since some networks block ICMP traffic.

📥 Installation
Option 1: Clone the repository
git clone https://github.com/exodia03/Exodia-Doctor.git
cd Exodia-Doctor
chmod +x exodia-doctor.sh

Option 2: Download the script
curl -fLO https://raw.githubusercontent.com/exodia03/Exodia-Doctor/main/exodia-doctor.sh
chmod +x exodia-doctor.sh


Review the script before executing it, especially when downloading code directly from the internet.

🚀 Usage
1. Run diagnostics

The recommended starting point is diagnostic mode:

./exodia-doctor.sh


This collects system information and writes a report without initiating a package upgrade.

2. Review the diagnostic report

The script stores its reports in:

~/pacman-doctor-logs/


List available reports:

ls -lt ~/pacman-doctor-logs/


Read the latest diagnostic report:

less "$(ls -t ~/pacman-doctor-logs/diagnostic-*.log | head -n 1)"

3. Run an optional system upgrade

After reviewing the report, you can request an interactive full system upgrade:

./exodia-doctor.sh --upgrade


The script asks for confirmation before running:

sudo pacman -Syu


Review package replacement and removal prompts carefully. If Pacman reports an error, save the upgrade log and investigate the specific cause before attempting a repair.

[!WARNING]
The --upgrade option performs a real system upgrade. It is not a repair-only operation. It does not automatically resolve every signature, keyring, or package-file conflict.
🔍 Diagnostic Checks
System information

Collects:

Distribution information from /etc/os-release.
The running kernel version.
Current date and time.
Installed Pacman version.
Network and clock

Checks basic connectivity and displays clock synchronization status. These checks help identify possible DNS, network, or incorrect-system-time issues that can interfere with package downloads and signature verification.

Pacman configuration and keyrings

Inspects Pacman signature configuration and repository settings, and checks whether the following packages are installed:

archlinux-keyring
chaotic-keyring

The script reports their status; it does not automatically update or reinstall them.

Recent Pacman errors

Searches /var/log/pacman.log for relevant messages, including:

Unknown signing-key trust.
PGP signature failures.
Invalid or corrupted packages.
Conflicting files.
Failed transactions.
Keyring errors.

The output is intended to help you locate the underlying issue rather than apply an indiscriminate fix.

🟢 NVIDIA Firmware Troubleshooting

One of the main use cases for Exodia Doctor is investigating NVIDIA firmware package conflicts after a system upgrade.

For example, a system might report that the following directories are owned by linux-firmware:

/usr/lib/firmware/nvidia/ad103/
/usr/lib/firmware/nvidia/ad104/
/usr/lib/firmware/nvidia/ad106/
/usr/lib/firmware/nvidia/ad107/


These directories are associated with NVIDIA GPU firmware.

Step 1: Check installed packages
pacman -Q | grep -E '^(linux-firmware|nvidia)'


This displays installed packages whose names begin with linux-firmware or nvidia.

Step 2: Identify firmware ownership
pacman -Qo /usr/lib/firmware/nvidia/ad103
pacman -Qo /usr/lib/firmware/nvidia/ad104
pacman -Qo /usr/lib/firmware/nvidia/ad106
pacman -Qo /usr/lib/firmware/nvidia/ad107


Pacman reports which installed package owns each path.

Step 3: Inspect package conflicts

If an upgrade reports that one package cannot install files because another package already owns them, record the exact conflicting paths and package names.

Check the distribution's package-transition instructions and determine whether a package replacement or ownership transition is expected.

Step 4: Resolve the underlying issue

Use the actual error message to select the appropriate repair.

Package transition: Follow the relevant distribution or repository instructions.
Unexpected file ownership: Verify which package should own the conflicting path.
Outdated firmware package: Check available package updates and dependency requirements.
Repository or signature error: Resolve the signing-key, repository, or package-integrity problem first.
[!CAUTION]
Do not blindly use pacman --overwrite, pacman -Rdd, or manually delete firmware directories. These actions can bypass package safeguards or break dependencies. Use them only when the exact conflict is understood and a documented repair requires them.

Important: A directory being owned by linux-firmware is not, by itself, evidence of a problem. The conflict message and package metadata determine whether intervention is necessary.

🗂️ Log Files

Exodia Doctor creates timestamped diagnostic and upgrade reports under:

~/pacman-doctor-logs/


Example layout:

~/pacman-doctor-logs/
├── diagnostic-YYYYMMDD-HHMMSS.log
└── upgrade-YYYYMMDD-HHMMSS.log


The actual filenames contain timestamps. An upgrade log is created for each upgrade-mode invocation.

View recent errors
grep -Ei \
  'unknown trust|PGP signature|invalid or corrupted package|conflicting files|failed to commit transaction|keyring' \
  /var/log/pacman.log | tail -n 60

Share a diagnostic report

When requesting help, share the relevant error message and diagnostic output. Review reports before publishing them because they may contain usernames, repository configuration, installed package information, and other system details.

🛠️ Troubleshooting Guide
Symptom	Recommended next step
unknown trust	Verify the package signature, repository, system clock, and appropriate keyring repair procedure.
PGP signature failure	Check package integrity and signing-key information. Do not disable signature verification.
Unknown host	Investigate DNS resolution, network connectivity, and keyserver or repository access.
conflicting files	Run pacman -Qo /path/to/file for each reported path and identify the ownership transition.
Failed package transaction	Inspect the complete error in the upgrade log before retrying.
NVIDIA firmware conflict	Check the conflicting paths, installed firmware packages, and distribution-specific migration instructions.
Ping fails	Verify connectivity using other methods; ICMP may be blocked.
🔒 Safety and Limitations

Exodia Doctor is a diagnostic and guided-maintenance script, not a universal package repair tool.

Diagnostic mode does not intentionally change installed packages.
Upgrade mode requires confirmation before running a full system upgrade.
The script does not automatically disable Pacman signature checks.
It does not automatically trust arbitrary signing keys.
It does not automatically remove packages or force file overwrites.
It inspects selected NVIDIA firmware directories rather than every possible GPU firmware path.
It relies on available system tools and the contents of the local Pacman log.
Its error matching is intentionally limited and may not detect every possible failure.

Always maintain a working backup and ensure that you have a recovery method before performing significant package-management operations.

🗺️ Roadmap

Potential future improvements include:

Interactive diagnostic menu.
NVIDIA GPU detection using PCI device information.
Expanded firmware ownership and package-integrity checks.
Improved detection of incomplete upgrades.
Distribution-aware repair recommendations.
Optional JSON diagnostic reports.
Automated tests and ShellCheck integration.
More detailed diagnostic summaries with severity levels.
Separate, explicitly confirmed repair commands for supported failure scenarios.

These are planned improvements, not claims about features currently implemented.

🤝 Contributing

Contributions, bug reports, and suggestions are welcome.

Fork the repository.
Create a feature branch.
Test your changes on an Arch-based system.
Verify shell syntax with bash -n exodia-doctor.sh.
Run ShellCheck if available.
Open a pull request describing the change and its testing.

Please include the relevant Pacman error messages when reporting package-management bugs, and redact any sensitive information.

📄 License

No license is specified by this README. Before redistributing or modifying the project, check the repository for an existing LICENSE file or add an appropriate open-source license.

<p align="center"> <strong>Exodia Doctor</strong><br> Diagnose first. Understand the problem. Repair safely. </p>
