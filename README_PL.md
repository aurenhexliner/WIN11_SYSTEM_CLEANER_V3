<div align="center">

# Windows 11 Junk File Removal

### Praktyczne narzędzie do czyszczenia plików tymczasowych, rozpoznanych pamięci podręcznych, zrzutów i archiwalnych logów Windows.

[![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows&logoColor=white)](#wymagania)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-5391FE?logo=powershell&logoColor=white)](#wymagania)
[![GUI](https://img.shields.io/badge/GUI-WinUI%203-6B4FBB)](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest)
[![Licencja](https://img.shields.io/badge/Licencja-GPL--3.0-2EA44F)](LICENSE)
[![Language](https://img.shields.io/badge/Language-English%20%7C%20Polski-6B7280)](README.md)

**Wybierz wersję. Sprawdź działania nieodwracalne. Zachowaj szczegółowy log sesji.**

[Pobierz GUI](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest) · [English: README.md](README.md)

</div>

---

## Wybierz wersję

| | GUI (zalecane) | Skrypt PowerShell |
|---|---|---|
| **Pobieranie** | [Najnowsze wydanie](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest) → `Win11JunkFileRemovalGui.exe` | [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1) |
| **Interfejs** | WinUI 3, pojedynczy plik, polski/angielski | Interaktywne menu konsolowe |
| **Funkcje** | Postęp na żywo, wybór punktów przywracania, wykres podsumowania, eksport logów | Ten sam silnik czyszczenia co w GUI |

GUI uruchamia osadzony skrypt PowerShell, dzięki czemu zakres operacji jest spójny w obu wersjach.

## Opcje czyszczenia

| # | Operacja | Ważna informacja |
|:--:|---|---|
| **1** | Czyści pliki tymczasowe Windows i użytkownika, wybrane pamięci podręczne aplikacji, pliki Windows Error Reporting i obsługiwane pozostałości Windows Update. | Rozpoznane cache aplikacji jest najpierw mierzone; foldery mniejsze niż **100 MB** pozostają bez zmian. |
| **2** | Uruchamia Oczyszczanie dysku Windows (`cleanmgr`) z tymczasowym profilem wybranych kategorii. | Okno jest widoczne i może wymagać uwagi. Wykluczone są Pobrane, cookies, Kosz i poprzednie instalacje Windows. |
| **3** | Wyszukuje zrzuty pamięci i awarii w standardowych lokalizacjach. | Przed usunięciem sprawdź znalezione pliki i potwierdź operację. |
| **4** | Wyświetla punkty przywracania i pozwala wybrać pojedyncze lub wszystkie. | Usunięcie jest trwałe. |
| **5** | Usuwa obsługiwane archiwalne logi diagnostyczne i instalacyjne starsze niż 30 dni. | Bieżące logi i dzienniki zdarzeń Windows pozostają nienaruszone. |
| **6** | Analizuje i czyści magazyn składników Windows za pomocą DISM. | Końcowy etap **ResetBase** jest nieodwracalny; zainstalowanych aktualizacji nie można już odinstalować. |

## Szybki start GUI

1. Pobierz `Win11JunkFileRemovalGui.exe` z [najnowszego wydania](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest).
2. Uruchom program i zaakceptuj monit UAC, jeśli się pojawi.
3. Zaznacz operacje czyszczenia i kliknij **Uruchom**.
4. Obserwuj postęp na żywo i sprawdź końcowe podsumowanie odzyskanego miejsca.
5. Użyj **Otwórz plik log** lub **Eksportuj logi**, aby odczytać albo zapisać pełny zapis sesji.

## Szybki start PowerShell

1. Pobierz [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1).
2. Otwórz PowerShell w folderze pliku i uruchom:

   ```powershell
   .\WIN11_SYSTEM_CLEANER.ps1
   ```

3. **1-6** przełącza pojedyncze operacje, **7** wszystkie, **Enter** uruchamia, a **0** kończy.

Skrypt nie zmienia ustawień Execution Policy. Jeśli organizacja ogranicza uruchamianie skryptów, postępuj zgodnie z jej polityką.

## Wymagania

- Windows 10 lub Windows 11 (x64 dla GUI).
- Windows PowerShell 5.1 albo PowerShell 7.x dla skryptu.
- Zgoda administratora (UAC) dla operacji systemowych.

## Bezpieczeństwo i zakres

- Cookies, zapisane hasła, historia przeglądania, profile i dokumenty osobiste nie są celem czyszczenia.
- Czyszczenie cache jest ograniczone do rozpoznanych lokalizacji; pamięci podręczne aplikacji poniżej 100 MB pozostają bez zmian.
- Zajęte lub niedostępne elementy są pomijane, a informacja o nich trafia do logu sesji.
- Dowiązania/reparse points nie są śledzone podczas rekurencyjnego czyszczenia.
- Usuwanie punktów przywracania i DISM ResetBase są destrukcyjne; uważnie czytaj monity.
- Oczyszczania dysku (`cleanmgr`) nie da się uruchomić całkowicie po cichu i może wymagać przełączenia na jego okno.

Logi sesji są zapisywane w `%LOCALAPPDATA%\Windows11JunkFileRemoval\Logs`.

## Pliki repozytorium

| Plik | Opis |
|---|---|
| [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1) | Interaktywny skrypt konsolowy; ten sam silnik czyszczenia co w GUI. |
| [`README.md`](README.md) | Angielski opis projektu. |
| [`README_PL.md`](README_PL.md) | Polski opis projektu. |
| [`LICENSE`](LICENSE) | Licencja GNU General Public License v3.0. |
| [Wydania](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases) | Pliki GUI i opisy wydań. |

## Licencja

Projekt jest udostępniany na warunkach [GNU General Public License v3.0](LICENSE).

---

<div align="center">

**Sprawdź zaznaczenie. Zabezpiecz ważne dane. Uruchamiaj tylko operacje, których skutki rozumiesz.**

</div>
