<div align="center">

# Windows 11 Junk File Removal

### A Windows cleanup utility for temporary files, selected application caches, crash dumps, and archived diagnostic logs.

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows&logoColor=white)](#requirements)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](#requirements)
[![WinUI 3](https://img.shields.io/badge/GUI-WinUI%203-6B4FBB)](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest)
[![License](https://img.shields.io/badge/License-GPL--3.0-2EA44F)](LICENSE)
[![Polski](https://img.shields.io/badge/Language-Polski%20version-6B7280)](README_PL.md)

**Choose the operations you need. Review prompts carefully. Keep a detailed session log.**

[Download the latest GUI](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest) · [Standalone PowerShell script](WIN11_SYSTEM_CLEANER.ps1) · [Polski](README_PL.md)

</div>

---

## At a glance

Windows 11 Junk File Removal is available as a WinUI 3 desktop application and as a standalone PowerShell script. The GUI embeds the cleanup script and is published as a self-contained, single-file x64 executable; no separate .NET installation is required. Both editions provide the same cleanup operations.

The tool focuses on Windows and application temporary data. It does **not** target browser cookies, saved passwords, browsing history, profiles, or personal documents. Items that could not be removed are reported rather than silently treated as success.

## Choose your edition

| | GUI (recommended) | PowerShell script |
|---|---|---|
| **Download** | [Latest release](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest) → `Win11JunkFileRemovalGui.exe` | [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1) |
| **Interface** | WinUI 3; English and Polish; appearance options | Interactive console menu; language follows Windows locale |
| **Highlights** | Live progress, restore-point selection, cleanup summary and chart, session log and export | Select operations and follow prompts in the console |
| **Runtime** | Self-contained; no separate .NET install | Windows PowerShell 5.1 or PowerShell 7.x |

The latest release also includes the standalone script and `SHA256SUMS.txt` to verify downloads.

## Cleanup operations

| # | Operation | Scope and notes |
|:--:|---|---|
| **1** | Temporary files and selected caches | Windows and current-user Temp folders, DirectX shader cache, archived Windows Error Reporting files, the Delivery Optimization cache, and supported browser/application caches, including Chrome, Edge, Firefox, Opera, Vivaldi, Discord, Teams, Slack, and VS Code. A supported cache is measured first and left unchanged if it is below **100 MB** or cannot be measured completely. With permission, detected application windows are asked to close gracefully; processes are never force-terminated. Windows Update download cleanup is a separate confirmed step and may temporarily stop and restart related services. |
| **2** | Windows Disk Cleanup (`cleanmgr`) | Runs selected categories with a temporary profile, which is restored afterward. Its window is visible and may require attention. Downloads, cookies, Recycle Bin contents, and previous Windows installations are excluded. It is not fully silent. |
| **3** | Memory and crash dumps | Finds dumps in standard Windows and user crash-dump locations, lists them, and asks before permanent deletion. |
| **4** | System restore points | Displays available points for individual or bulk selection. Deletion is permanent; a new restore point may be created afterward if Windows permits it. |
| **5** | Archived diagnostic and setup logs | Removes supported matching logs older than 30 days. Current/active logs and Windows Event Logs are preserved. |
| **6** | DISM component-store maintenance | Analyzes the component store and runs standard cleanup. The optional final **ResetBase** step requires separate confirmation and is irreversible: installed Windows updates can no longer be uninstalled, and superseded component versions cannot be restored. |

File counts and recovered-space totals vary by operation. Some Windows tools do not provide exact per-file statistics.

## GUI quick start

1. Download `Win11JunkFileRemovalGui.exe` from [Releases](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest).
2. Run it and approve the UAC prompt if Windows requests administrator access.
3. Select cleanup operations and click **Run**. Read operation-specific prompts before confirming.
4. Follow progress and activity messages. If Disk Cleanup waits for attention, switch to its window from the taskbar. Keep the cleaner open until the operation completes.
5. Review the final summary. Use **Open session log** or **Export logs** to inspect or save the detailed results, including skipped items.

The published GUI is a self-contained single-file application. It may extract runtime components at startup; a separate script or .NET installation is not needed to run it.

## PowerShell quick start

1. Download [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1).
2. Open PowerShell in its folder and run:

   ```powershell
   .\WIN11_SYSTEM_CLEANER.ps1
   ```

3. Use **1–6** to toggle individual operations, **7** to toggle all, **Enter** to run, or **0** to exit. Follow the prompts.

The script does not change execution-policy settings. If your organization restricts scripts, follow its policy or ask your administrator.

## Requirements

- Windows 10 or Windows 11; the published GUI requires 64-bit (x64) Windows.
- Windows PowerShell 5.1 or PowerShell 7.x for the standalone script.
- Administrator approval through UAC for system-wide cleanup. Windows or organizational policy may restrict some actions.
- No separate .NET installation is required for the published self-contained GUI.

## Safety, privacy, and limitations

- **Personal browser data is out of scope:** cookies, saved passwords, browsing history, browser profiles, and personal documents are not targeted.
- **Caches are allow-listed:** only supported locations are considered; supported application cache folders under 100 MB are left unchanged.
- **Applications are not force-closed:** if approved, the tool requests a normal window close for supported running applications. Save work first; apps that remain open may keep files locked.
- **Errors are recorded:** inaccessible or in-use files and folders are skipped where possible, with details written to the session log. Administrator access cannot guarantee removal of every locked file.
- **Reparse points are not followed** during recursive folder cleanup.
- **Some actions are irreversible:** restore-point deletion permanently removes selected points; DISM ResetBase prevents uninstalling installed updates. Read confirmations carefully.
- **Disk Cleanup is not fully silent:** `cleanmgr` opens a visible window and may wait for user attention. Keep the cleaner running until it exits.
- **Windows services may be restarted:** cleaning downloaded Windows Update files requires stopping related services temporarily; the script attempts to restore their original running state.

## Language, appearance, and logs

The console script selects Polish or English from the Windows locale. The GUI has a language selector and appearance options. Progress and activity appear in the application; detailed session logs are stored under `%LOCALAPPDATA%\Windows11JunkFileRemoval\Logs`. The GUI can open the session log or export it to a chosen location.

## Repository contents

| File | Description |
|---|---|
| [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1) | Standalone interactive console script; the GUI embeds the same cleanup script. |
| [`README.md`](README.md) | English project guide. |
| [`README_PL.md`](README_PL.md) | Polish project guide. |
| [`LICENSE`](LICENSE) | GNU General Public License v3.0. |
| [Releases](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases) | GUI, standalone script, checksums, and release notes. |

## Verify release downloads

The latest release includes `SHA256SUMS.txt`. Calculate local file hashes in PowerShell:

```powershell
Get-FileHash .\Win11JunkFileRemovalGui.exe -Algorithm SHA256
Get-FileHash .\WIN11_SYSTEM_CLEANER.ps1 -Algorithm SHA256
```

Compare each value with the corresponding entry in `SHA256SUMS.txt`.

## License

This project is distributed under the [GNU General Public License v3.0](LICENSE). The repository's `LICENSE` file is authoritative.

---

<div align="center">

**Review your selections. Save your work before closing applications. Run only the operations you understand.**

</div>
