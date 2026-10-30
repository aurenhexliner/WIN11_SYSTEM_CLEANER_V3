<div align="center">

# Windows 11 Junk File Removal

### A practical PowerShell utility for reviewing and cleaning selected Windows temporary files, caches, dumps, and archived diagnostics.

[![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows&logoColor=white)](#requirements)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-5391FE?logo=powershell&logoColor=white)](#requirements)
[![Language](https://img.shields.io/badge/Interface-English%20%7C%20Polski-6B7280)](#language-and-controls)

**Choose what to run. Review destructive actions. Keep the full session log.**

</div>

---

## At a glance

This repository contains an interactive PowerShell script for Windows 10 and 11. It groups common cleanup tasks into selectable operations, requests confirmation for sensitive actions, skips files it cannot safely remove, and records a detailed session log.

The script targets temporary files and recognized cache locations—not browser cookies, saved passwords, browsing history, or arbitrary personal files. Some Windows utilities have their own windows and may need attention while they run.

## Cleanup options

| Option | What it does | Important detail |
|:--:|---|---|
| **1** | Cleans Windows and user temporary files, selected application caches, Windows Error Reporting files, and supported Windows Update remnants. | Recognized app caches are measured first; folders below **100 MB** are left unchanged. Related system actions may ask for confirmation. |
| **2** | Runs Windows Disk Cleanup (`cleanmgr`) with a temporary profile of explicitly selected categories. | The cleanmgr window is visible and may need foreground attention. Downloads, cookies, the Recycle Bin, and previous Windows installations are excluded from this profile. |
| **3** | Finds memory and crash dumps in standard locations. | Review the discovered files and confirm before deletion. |
| **4** | Lists existing system restore points and lets you choose individual points or all points. | Deletion is permanent. A new restore point may be created after selected points are removed. |
| **5** | Removes supported archived diagnostic and setup logs older than 30 days. | Active logs and Windows Event Logs are preserved. |
| **6** | Analyzes and cleans the Windows component store with DISM. | The final **ResetBase** step is irreversible and requires confirmation; afterward, installed updates cannot be uninstalled. |

Select one or more options from the menu, or use **7** to toggle all options. Press **Enter** to run the selection and **0**, then **Enter**, to exit. Exact space-recovery statistics are not available for every Windows operation.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1 or PowerShell 7.x.
- Administrator approval for system-wide cleanup. The script may request elevation through UAC.

## Quick start

1. Download `WIN11_SYSTEM_CLEANER.ps1` from this repository.
2. Open PowerShell in the downloaded file's folder.
3. Run:

   ```powershell
   .\WIN11_SYSTEM_CLEANER.ps1
   ```

4. Approve the UAC prompt if shown, choose cleanup options, and review any additional confirmations.

If your organization's execution policy blocks scripts, follow its policy; this script does not change execution-policy settings.

## Safety and scope

- **Personal browser data is out of scope:** cookies, passwords, browsing history, profiles, and personal documents are not targeted.
- **Cache cleanup is allow-listed:** the script checks known cache folders and only clears a recognized application cache when its measured size is at least 100 MB.
- **Locked or inaccessible items are skipped:** cleanup continues where possible, and skipped paths and reasons are recorded in the log.
- **Reparse points are not followed** during recursive folder cleanup.
- **Restore-point deletion and DISM ResetBase are destructive.** Read the prompts carefully; a restore point cannot undo ResetBase.
- **Disk Cleanup is not fully silent:** `cleanmgr` runs in its own visible window and may require switching to that window. Leave the script running until it finishes.

Session logs are stored under `%LOCALAPPDATA%\Windows11JunkFileRemoval\Logs`.

## Language and controls

The console language follows the Windows system locale: Polish for a Polish locale and English otherwise. In the menu, **1–6** toggle individual operations, **7** toggles all options, **Enter** runs the selected operations, and **0** exits.

## Repository contents

- `WIN11_SYSTEM_CLEANER.ps1` — the interactive cleanup script.
- `README.md` — this English guide.
- `README_PL.md` — the Polish guide.
- `LICENSE` and `LICENCE.txt` — license notices currently present in the repository.

> **License notice needs maintainer review:** GitHub identifies this repository as GPL-3.0, while `LICENCE.txt` describes the software as proprietary and restricts redistribution. These notices conflict. Confirm and align the repository license before redistributing the script; this README does not resolve that legal inconsistency.

---

<div align="center">

**Review your selections. Back up important data. Run only the operations you understand.**

</div>
