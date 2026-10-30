<div align="center">

# Windows 11 Junk File Removal

### Praktyczne narzędzie PowerShell do przeglądania i czyszczenia wybranych plików tymczasowych, pamięci podręcznych, zrzutów i archiwalnych logów Windows.

[![Windows 10/11](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows&logoColor=white)](#wymagania)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-5391FE?logo=powershell&logoColor=white)](#wymagania)
[![Język](https://img.shields.io/badge/Interfejs-Polski%20%7C%20English-6B7280)](#język-i-sterowanie)

**Wybierz zakres. Potwierdź działania nieodwracalne. Zachowaj pełny log sesji.**

</div>

---

## W skrócie

To repozytorium zawiera interaktywny skrypt PowerShell dla Windows 10 i 11. Grupuje typowe zadania porządkowe w wybierane operacje, pyta o zgodę przed wrażliwymi działaniami, pomija pliki, których nie może bezpiecznie usunąć, i zapisuje szczegółowy log sesji.

Skrypt skupia się na plikach tymczasowych i rozpoznanych lokalizacjach pamięci podręcznej — nie na cookies, zapisanych hasłach, historii przeglądania ani dowolnych plikach osobistych. Niektóre narzędzia Windows otwierają własne okna i mogą wymagać uwagi podczas działania.

## Opcje czyszczenia

| Opcja | Działanie | Ważna informacja |
|:--:|---|---|
| **1** | Czyści pliki tymczasowe Windows i użytkownika, wybrane pamięci podręczne aplikacji, pliki Windows Error Reporting i obsługiwane pozostałości Windows Update. | Najpierw mierzy rozpoznane cache aplikacji; foldery mniejsze niż **100 MB** pozostawia bez zmian. Powiązane działania systemowe mogą wymagać potwierdzenia. |
| **2** | Uruchamia Oczyszczanie dysku Windows (`cleanmgr`) z tymczasowym profilem jawnie wybranych kategorii. | Okno cleanmgr jest widoczne i może wymagać przełączenia na nie. W tym profilu wykluczone są Pobrane, cookies, Kosz i poprzednie instalacje Windows. |
| **3** | Wyszukuje zrzuty pamięci i awarii w standardowych lokalizacjach. | Przed usunięciem można sprawdzić znalezione pliki i trzeba potwierdzić operację. |
| **4** | Wyświetla istniejące punkty przywracania i pozwala zaznaczyć pojedyncze lub wszystkie. | Usunięcie jest trwałe. Po usunięciu wybranych punktów może zostać utworzony nowy punkt. |
| **5** | Usuwa obsługiwane archiwalne logi diagnostyczne i instalacyjne starsze niż 30 dni. | Bieżące logi i dzienniki zdarzeń Windows pozostają nienaruszone. |
| **6** | Analizuje i czyści magazyn składników Windows za pomocą DISM. | Końcowy etap **ResetBase** jest nieodwracalny i wymaga potwierdzenia; po nim nie można odinstalować zainstalowanych aktualizacji. |

Wybierz jedną lub więcej opcji z menu albo użyj **7**, aby przełączyć zaznaczenie wszystkich. Naciśnij **Enter**, aby uruchomić wybór, lub **0**, a następnie **Enter**, aby zakończyć. Nie każde narzędzie systemowe udostępnia dokładne statystyki odzyskanego miejsca.

## Wymagania

- Windows 10 lub Windows 11.
- Windows PowerShell 5.1 albo PowerShell 7.x.
- Zgoda na podniesienie uprawnień dla operacji systemowych. Skrypt może wyświetlić monit UAC.

## Szybki start

1. Pobierz z repozytorium plik `WIN11_SYSTEM_CLEANER.ps1`.
2. Otwórz PowerShell w folderze z pobranym plikiem.
3. Uruchom:

   ```powershell
   .\WIN11_SYSTEM_CLEANER.ps1
   ```

4. Zaakceptuj monit UAC, jeśli się pojawi, wybierz opcje i przeczytaj dodatkowe monity.

Jeśli zasady wykonywania skryptów w organizacji blokują uruchomienie, postępuj zgodnie z jej polityką. Skrypt nie zmienia ustawień Execution Policy.

## Bezpieczeństwo i zakres

- **Dane osobiste przeglądarek są poza zakresem:** cookies, hasła, historia, profile i dokumenty osobiste nie są celem czyszczenia.
- **Cache jest ograniczony do rozpoznanych lokalizacji:** skrypt sprawdza znane foldery i czyści pamięć podręczną aplikacji dopiero po stwierdzeniu, że zajmuje co najmniej 100 MB.
- **Zajęte lub niedostępne elementy są pomijane:** czyszczenie jest kontynuowane tam, gdzie to możliwe, a pominięte ścieżki i powody są zapisywane w logu.
- **Dowiązania/reparse points nie są śledzone** podczas rekurencyjnego czyszczenia folderów.
- **Usuwanie punktów przywracania i DISM ResetBase są destrukcyjne.** Uważnie czytaj monity; punkt przywracania nie cofnie ResetBase.
- **Oczyszczanie dysku nie jest całkowicie ciche:** `cleanmgr` działa we własnym, widocznym oknie i może wymagać przełączenia na nie. Nie zamykaj skryptu przed zakończeniem.

Logi sesji są zapisywane w `%LOCALAPPDATA%\Windows11JunkFileRemoval\Logs`.

## Język i sterowanie

Język konsoli zależy od języka systemowego Windows: polski dla polskiego locale, angielski w pozostałych przypadkach. W menu **1–6** przełącza poszczególne operacje, **7** zaznacza lub odznacza wszystkie, **Enter** uruchamia wybrane operacje, a **0** kończy działanie.

## Zawartość repozytorium

- `WIN11_SYSTEM_CLEANER.ps1` — interaktywny skrypt czyszczący.
- `README.md` — przewodnik angielski.
- `README_PL.md` — przewodnik polski.
- `LICENSE` i `LICENCE.txt` — pliki z informacjami o licencji obecne w repozytorium.

> **Licencje wymagają wyjaśnienia przez opiekuna repozytorium:** GitHub oznacza repozytorium jako GPL-3.0, natomiast `LICENCE.txt` opisuje program jako własnościowy i ogranicza redystrybucję. Te informacje są sprzeczne. Przed dalszą redystrybucją skryptu należy potwierdzić i ujednolicić licencję; ten README nie rozstrzyga kwestii prawnych.

---

<div align="center">

**Sprawdź zaznaczenie. Zabezpiecz ważne dane. Uruchamiaj tylko operacje, których skutki rozumiesz.**

</div>
