Windows 11 Junk File Removal — GUI v1.2.0
Windows system cleanup and maintenance utility
======================================================================

This is the graphical version of Windows 11 Junk File Removal. It uses a
WinUI 3 interface and includes the PowerShell cleanup script inside the
application. Select the cleanup operations in the app, then choose
"Run" at the bottom right. Progress, messages, and supported prompts are shown in
the Activity panel rather than in a separate PowerShell console.


REQUIREMENTS
----------------------------------------------------------------------

• Windows 10 or Windows 11, 64-bit (x64)
• Administrator approval through UAC for system-wide cleanup operations
• No separate .NET installation is required for the published
  self-contained executable


RUN
----------------------------------------------------------------------

1. Extract the downloaded archive to a folder.
2. Run Win11JunkFileRemovalGui.exe.
3. Select the cleanup operations you want to perform.
4. Choose "Run" at the bottom right and approve the UAC prompt if Windows displays it.
5. Follow any in-app prompts, such as closing browsers or selecting
   restore points.
6. The progress panel shows the current phase and item, elapsed time, and—when a reliable estimate is available—completion percentage and estimated remaining time. The chart updates after each stage, shows measured reclaimed space and file counts, and remains beside Activity when the run finishes. cleanmgr/DISM measurements use the change in system-drive free space; restore-point measurements use the change in VSS storage usage. Other system activity can affect these measurements. "Open session log" becomes active when the task finishes and opens its complete, uncoloured log. Each run creates a separate file in %LOCALAPPDATA%\Windows11JunkFileRemoval\Logs; "Export logs" saves a copy.

The application executable is intended to be run directly; it does not
require installing the PowerShell script separately. The self-contained
single-file app may extract runtime components when it starts.


LANGUAGE AND APPEARANCE
----------------------------------------------------------------------

The application selects English or Polish based on the Windows system
locale. It follows the Windows system appearance by default; use the
appearance options shown in the application to change it.


CLEANUP OPERATIONS
----------------------------------------------------------------------

The GUI runs the embedded cleanup script. Depending on the selected operations, it can:

• Remove Windows and current-user temporary files and recognised application caches of at least 100 MB (Chrome, Edge, Brave, Vivaldi, Opera, Firefox, Discord, Teams, Slack, Visual Studio Code, Steam). Cookies, browser profiles and other personal files are excluded.
• Run Disk Cleanup (cleanmgr) in a visible window on detected drives, for safe categories only. Downloads, cookies, Recycle Bin and previous Windows installations are excluded.
• Remove Windows Update download remnants, the Delivery Optimization cache, and memory/crash dumps when applicable.
• Show restore points as a checkbox list so you can pick single points or all.
• Remove archived diagnostic logs older than 30 days, keeping active logs and Windows event logs.
• Analyze the DISM component store, clean it up, and run /ResetBase /Defer.

Files in use or inaccessible may remain. The Activity summary shows how many files and folders could not be removed; paths and reasons are in the session log.


IMPORTANT WARNINGS
----------------------------------------------------------------------

• Review the selected operations before starting. Cleanup begins without
  an extra confirmation for each selected operation.
• /ResetBase is irreversible. After it completes, installed Windows
  updates can no longer be uninstalled, and previous versions of
  superseded components cannot be restored. A restore point cannot undo
  these changes.
• Disk Cleanup may wait for input in its own window. If so, switch to it from the taskbar and do not close the GUI until it finishes.
• Restore-point deletion is destructive. Review the displayed list and
  choose carefully. A new restore point is created after cleanup only
  when existing restore points were selected for deletion.
• Close browsers if prompted before cleaning their caches.


VERSION AND SCRIPT
----------------------------------------------------------------------

GUI file version: 1.2.0
Embedded PowerShell script version: 2.0

The standalone PowerShell script WIN11_SYSTEM_CLEANER.ps1 is the same script embedded in the GUI, with identical functions. For console use, run it from an elevated PowerShell: powershell -ExecutionPolicy Bypass -File .\WIN11_SYSTEM_CLEANER.ps1 The legacy
clean.cmd file is not recommended; it removes Windows\Logs and
SoftwareDistribution contents without separate operation selection.


AUTHOR AND LICENCE
----------------------------------------------------------------------

Author: Jacek Żaczek
Contact: j.zaczek@data.pl

Freeware: provided at no charge. This is proprietary software and is not
released under an open-source licence. See LICENCE.txt in this archive.
