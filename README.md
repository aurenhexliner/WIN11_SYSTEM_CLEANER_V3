<div align="center">

# Windows 11 Junk File Removal

### A practical Windows cleanup utility for temporary files, recognized caches, dumps and archived logs.

[![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows&logoColor=white)](#requirements)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-5391FE?logo=powershell&logoColor=white)](#requirements)
[![GUI](https://img.shields.io/badge/GUI-WinUI%203-6B4FBB)](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest)
[![License](https://img.shields.io/badge/License-GPL--3.0-2EA44F)](LICENSE)
[![Language](https://img.shields.io/badge/Language-English%20%7C%20Polski-6B7280)](README_PL.md)

**Choose your version. Review destructive actions. Keep a detailed session log.**

[Download the GUI](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest) · [Polski: README_PL.md](README_PL.md)

</div>

---

## Choose your version

| | GUI (recommended) | PowerShell script |
|---|---|---|
| **Download** | [Latest Release](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest) → `Win11JunkFileRemovalGui.exe` | [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1) |
| **Interface** | WinUI 3, single-file app, English/Polish | Interactive console menu |
| **Features** | Live progress, restore-point selection, summary chart, log export | Same cleanup engine as the GUI |

The GUI runs the PowerShell script embedded within it, keeping the cleanup operations consistent between versions.

## Cleanup options

| # | Operation | Important detail |
|:--:|---|---|
| **1** | Cleans Windows and user temporary files, selected application caches, Windows Error Reporting files, and supported Windows Update remnants. | Recognized application caches are measured first; folders below **100 MB** are left unchanged. |
| **2** | Runs Windows Disk Cleanup (`cleanmgr`) with a temporary profile of selected categories. | The window is visible and may need attention. Downloads, cookies, Recycle Bin, and previous Windows installations are excluded. |
| **3** | Finds memory and crash dumps in standard locations. | Review the discovered files and confirm before deletion. |
| **4** | Lists system restore points and lets you select individual points or all points. | Deletion is permanent. |
| **5** | Removes supported archived diagnostic and setup logs older than 30 days. | Active logs and Windows Event Logs are preserved. |
| **6** | Analyzes and cleans the Windows component store with DISM. | The final **ResetBase** step is irreversible; installed updates can no longer be uninstalled. |

## GUI quick start

1. Download `Win11JunkFileRemovalGui.exe` from the [latest release](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest).
2. Run the application and approve the UAC prompt when requested.
3. Select cleanup operations and click **Run**.
4. Follow live progress and review the final recovered-space summary.
5. Use **Open session log** or **Export logs** to inspect or save the complete session record.

## PowerShell quick start

1. Download [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1).
2. Open PowerShell in its folder and run:

   ```powershell
   .\WIN11_SYSTEM_CLEANER.ps1
   ```

3. Use **1-6** to toggle individual operations, **7** to toggle all, **Enter** to run, or **0** to exit.

The script does not change execution-policy settings. Follow your organization's policy if it restricts script execution.

## Requirements

- Windows 10 or Windows 11 (x64 for the GUI).
- Windows PowerShell 5.1 or PowerShell 7.x for the script.
- Administrator approval (UAC) for system-wide cleanup operations.

## Safety and scope

- Browser cookies, saved passwords, browsing history, profiles, and personal documents are not targeted.
- Cache cleanup is limited to recognized locations; application cache folders smaller than 100 MB are left unchanged.
- Locked or inaccessible items are skipped and recorded in the session log.
- Reparse points are not followed during recursive cleanup.
- Restore-point deletion and DISM ResetBase are destructive; read each confirmation carefully.
- Disk Cleanup (`cleanmgr`) cannot be fully silent and may need foreground attention.

Session logs are stored under `%LOCALAPPDATA%\Windows11JunkFileRemoval\Logs`.

## Repository files

| File | Description |
|---|---|
| [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1) | Interactive console cleaner; same cleanup engine used by the GUI. |
| [`README.md`](README.md) | English project guide. |
| [`README_PL.md`](README_PL.md) | Polish project guide. |
| [`LICENSE`](LICENSE) | GNU General Public License v3.0. |
| [Releases](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases) | GUI downloads and release notes. |

## License

This project is distributed under the [GNU General Public License v3.0](LICENSE).

---

<div align="center">

**Review your selections. Back up important data. Run only the operations you understand.**

</div>
