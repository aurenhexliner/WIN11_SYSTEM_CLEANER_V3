<div align="center">

# Windows 11 Junk File Removal

### Safe cleanup of Windows temp files, caches, dumps and archived logs &nbsp;|&nbsp; Bezpieczne czyszczenie plików tymczasowych, cache, zrzutów i logów Windows

[![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows&logoColor=white)](#requirements--wymagania)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-5391FE?logo=powershell&logoColor=white)](#requirements--wymagania)
[![GUI](https://img.shields.io/badge/GUI-WinUI%203-6B4FBB)](../../releases/latest)
[![License](https://img.shields.io/badge/License-GPL--3.0-2EA44F)](LICENSE)
[![Language](https://img.shields.io/badge/Interface-English%20%7C%20Polski-6B7280)](#language--język)

**[🇬🇧 English](#-english) &nbsp;•&nbsp; [🇵🇱 Polski](#-polski) &nbsp;•&nbsp; [⬇️ Download GUI / Pobierz GUI](../../releases/latest)**

</div>

---

## Choose your version / Wybierz wersję

| | 🖥️ GUI (recommended / zalecane) | 💻 PowerShell script / Skrypt PowerShell |
|---|---|---|
| **Get it / Pobierz** | [**Releases**](../../releases/latest) → `Win11JunkFileRemovalGui.exe` | [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1) (this repo / to repozytorium) |
| **Interface / Interfejs** | WinUI 3, single file, PL/EN | Console menu / menu konsolowe |
| **Extras / Dodatki** | Progress bar, restore point picker, summary chart, log export | Same cleanup engine / ten sam silnik czyszczenia |

> The GUI runs this same script internally, so both versions clean exactly the same things.
> GUI uruchamia wewnętrznie ten sam skrypt, więc obie wersje czyszczą dokładnie to samo.

---

## 🇬🇧 English

### At a glance

An interactive cleaner for Windows 10 and 11. It groups common cleanup tasks into selectable operations, asks for confirmation before sensitive actions, skips files it cannot safely remove, and writes a detailed session log.

It targets temporary files and recognized cache locations. It does **not** touch browser cookies, saved passwords, browsing history, user profiles or personal documents.

### Cleanup options

| # | What it does | Important detail |
|:--:|---|---|
| **1** | Cleans Windows and user temp files, selected application caches, Windows Error Reporting files and Windows Update remnants. | Application caches are measured first; folders below **100 MB** are left unchanged. |
| **2** | Runs Windows Disk Cleanup (`cleanmgr`) with a temporary profile of selected categories. | The window is visible and may need foreground attention. Downloads, cookies, Recycle Bin and previous Windows installations are excluded. |
| **3** | Finds memory and crash dumps in standard locations. | Review the findings and confirm before deletion. |
| **4** | Lists system restore points; choose single points or all. | Deletion is permanent. |
| **5** | Removes archived diagnostic and setup logs older than 30 days. | Active logs and Windows Event Logs are preserved. |
| **6** | Analyzes and cleans the component store with DISM. | The final **ResetBase** step is irreversible; installed updates can no longer be uninstalled. |

### Using the GUI

1. Open the [latest release](../../releases/latest) and download `Win11JunkFileRemovalGui.exe`.
2. Run it and accept the UAC prompt.
3. Tick the operations (or **Select all**) and press **Run**.
4. Watch live progress and logs; at the end see the summary with recovered space.
5. Use **Open session log** or **Export logs** to keep the full record.

### Using the script

1. Download `WIN11_SYSTEM_CLEANER.ps1`.
2. Open PowerShell in its folder and run:

   ```powershell
   .\WIN11_SYSTEM_CLEANER.ps1
   ```

3. Press **1-6** to toggle operations, **7** to toggle all, **Enter** to run, **0** to exit.

The script does not change your execution policy. If your organization blocks scripts, follow its policy.

### Requirements / Wymagania

- Windows 10 or 11 (x64 for the GUI).
- Windows PowerShell 5.1 or PowerShell 7.x.
- Administrator approval (UAC) for system-wide cleanup.

### Safety

- Cache cleanup is allow-listed; personal browser data is out of scope.
- Locked or inaccessible items are skipped and recorded in the log.
- Reparse points are not followed.
- Restore point deletion and DISM ResetBase are destructive: read the prompts.
- Disk Cleanup cannot be fully silent; switch to its window if it appears idle.

Logs are stored in `%LOCALAPPDATA%\Windows11JunkFileRemoval\Logs`.

### Language / Język

The interface follows the Windows locale (Polish for Polish systems, English otherwise). The GUI also has a language selector.

---

## 🇵🇱 Polski

### W skrócie

Interaktywne narzędzie do czyszczenia Windows 10 i 11. Grupuje typowe zadania w wybierane operacje, pyta o zgodę przed wrażliwymi działaniami, pomija pliki, których nie może bezpiecznie usunąć, i zapisuje szczegółowy log sesji.

Dotyczy plików tymczasowych i rozpoznanych lokalizacji cache. **Nie** rusza cookies, zapisanych haseł, historii przeglądania, profili użytkownika ani dokumentów osobistych.

### Opcje czyszczenia

| # | Działanie | Ważna informacja |
|:--:|---|---|
| **1** | Czyści pliki tymczasowe Windows i użytkownika, wybrane cache aplikacji, pliki Windows Error Reporting i pozostałości Windows Update. | Cache aplikacji jest najpierw mierzony; foldery poniżej **100 MB** pozostają bez zmian. |
| **2** | Uruchamia Oczyszczanie dysku (`cleanmgr`) z tymczasowym profilem wybranych kategorii. | Okno jest widoczne i może wymagać przełączenia na nie. Wykluczone: Pobrane, cookies, Kosz, poprzednie instalacje Windows. |
| **3** | Wyszukuje zrzuty pamięci i awarii w standardowych lokalizacjach. | Przed usunięciem sprawdź wyniki i potwierdź. |
| **4** | Wyświetla punkty przywracania; wybierz pojedyncze lub wszystkie. | Usunięcie jest trwałe. |
| **5** | Usuwa archiwalne logi diagnostyczne i instalacyjne starsze niż 30 dni. | Bieżące logi i dzienniki zdarzeń Windows pozostają nienaruszone. |
| **6** | Analizuje i czyści magazyn składników za pomocą DISM. | Końcowy etap **ResetBase** jest nieodwracalny; zainstalowanych aktualizacji nie da się już odinstalować. |

### Korzystanie z GUI

1. Otwórz [najnowsze wydanie](../../releases/latest) i pobierz `Win11JunkFileRemovalGui.exe`.
2. Uruchom program i zaakceptuj monit UAC.
3. Zaznacz operacje (lub **Zaznacz wszystko**) i naciśnij **Uruchom**.
4. Obserwuj postęp i logi na żywo; na końcu zobaczysz podsumowanie z odzyskanym miejscem.
5. Użyj **Otwórz plik log** lub **Eksportuj logi**, aby zachować pełny zapis.

### Korzystanie ze skryptu

1. Pobierz `WIN11_SYSTEM_CLEANER.ps1`.
2. Otwórz PowerShell w jego folderze i uruchom:

   ```powershell
   .\WIN11_SYSTEM_CLEANER.ps1
   ```

3. **1-6** przełącza operacje, **7** wszystkie, **Enter** uruchamia, **0** kończy.

Skrypt nie zmienia Execution Policy. Jeśli organizacja blokuje skrypty, postępuj zgodnie z jej polityką.

### Wymagania

- Windows 10 lub 11 (x64 dla GUI).
- Windows PowerShell 5.1 albo PowerShell 7.x.
- Zgoda administratora (UAC) dla operacji systemowych.

### Bezpieczeństwo

- Czyszczenie cache jest ograniczone do rozpoznanych lokalizacji; dane osobiste przeglądarek są poza zakresem.
- Zajęte lub niedostępne elementy są pomijane i zapisywane w logu.
- Dowiązania (reparse points) nie są śledzone.
- Usuwanie punktów przywracania i DISM ResetBase są destrukcyjne: czytaj monity.
- Oczyszczania dysku nie da się uruchomić w pełni cicho; jeśli wygląda na zawieszone, przełącz się na jego okno.

Logi: `%LOCALAPPDATA%\Windows11JunkFileRemoval\Logs`.

### Język

Interfejs zależy od ustawień regionalnych Windows (polski dla polskiego systemu, w pozostałych przypadkach angielski). GUI ma też selektor języka.

---

## Repository contents / Zawartość repozytorium

| File / Plik | Description / Opis |
|---|---|
| `WIN11_SYSTEM_CLEANER.ps1` | Console script, same engine as the GUI / skrypt konsolowy, ten sam silnik co GUI |
| `README.md` | This bilingual guide / ten dwujęzyczny przewodnik |
| `LICENSE` | GPL-3.0 |
| [Releases](../../releases) | GUI executable and release notes / plik EXE GUI i opis wydań |

## License / Licencja

Released under the [GNU GPL v3.0](LICENSE). / Udostępniane na licencji [GNU GPL v3.0](LICENSE).

---

<div align="center">

**Review your selections. Back up important data. Run only what you understand.**
<br>
**Sprawdź zaznaczenie. Zabezpiecz ważne dane. Uruchamiaj tylko to, co rozumiesz.**

</div>
