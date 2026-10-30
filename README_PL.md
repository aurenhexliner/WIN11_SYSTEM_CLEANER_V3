<div align="center">

# Windows 11 Junk File Removal

### Narzędzie do czyszczenia plików tymczasowych, wybranych pamięci podręcznych aplikacji, zrzutów awarii i archiwalnych logów diagnostycznych Windows.

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows&logoColor=white)](#wymagania)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)](#wymagania)
[![WinUI 3](https://img.shields.io/badge/GUI-WinUI%203-6B4FBB)](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest)
[![Licencja](https://img.shields.io/badge/Licencja-GPL--3.0-2EA44F)](LICENSE)
[![English](https://img.shields.io/badge/Language-English%20version-6B7280)](README.md)

**Wybierz potrzebne operacje. Uważnie czytaj monity. Zachowaj szczegółowy log sesji.**

[Pobierz najnowsze GUI](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest) · [Samodzielny skrypt PowerShell](WIN11_SYSTEM_CLEANER.ps1) · [English](README.md)

</div>

---

## W skrócie

Windows 11 Junk File Removal jest dostępny jako aplikacja WinUI 3 oraz samodzielny skrypt PowerShell. GUI zawiera skrypt czyszczący i jest publikowane jako samodzielny, pojedynczy plik wykonywalny x64; nie wymaga osobnej instalacji .NET. Obie wersje oferują te same operacje.

Narzędzie skupia się na plikach tymczasowych Windows i aplikacji. **Nie** czyści cookies, zapisanych haseł, historii przeglądania, profili przeglądarek ani dokumentów osobistych. Elementy, których nie udało się usunąć, są raportowane, a błędy nie są ukrywane.

## Wybierz wersję

| | GUI (zalecane) | Skrypt PowerShell |
|---|---|---|
| **Pobieranie** | [Najnowsze wydanie](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest) → `Win11JunkFileRemovalGui.exe` | [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1) |
| **Interfejs** | WinUI 3; polski i angielski; wybór wyglądu | Menu konsolowe; język zależny od ustawień Windows |
| **Najważniejsze funkcje** | Postęp na żywo, wybór punktów przywracania, podsumowanie i wykres, log sesji i eksport | Wybór operacji i monity w konsoli |
| **Wymagania środowiska** | Samodzielna aplikacja; bez osobnej instalacji .NET | Windows PowerShell 5.1 lub PowerShell 7.x |

Najnowsze wydanie zawiera również samodzielny skrypt i `SHA256SUMS.txt` do weryfikacji pobranych plików.

## Operacje czyszczenia

| # | Operacja | Zakres i uwagi |
|:--:|---|---|
| **1** | Pliki tymczasowe i wybrane cache | Katalogi Temp Windows i bieżącego użytkownika, cache shaderów DirectX, archiwalne raporty Windows Error Reporting oraz obsługiwane pamięci podręczne przeglądarek i aplikacji. Cache jest najpierw mierzony; folder mniejszy niż **100 MB** lub niemożliwy do pełnego sprawdzenia pozostaje bez zmian. Po uzyskaniu zgody wykryte okna aplikacji są proszone o normalne zamknięcie; procesy nie są zamykane wymuszeniem. Czyszczenie pobranych plików Windows Update jest osobnym potwierdzanym krokiem i może tymczasowo zatrzymać oraz ponownie uruchomić powiązane usługi. |
| **2** | Oczyszczanie dysku Windows (`cleanmgr`) | Uruchamia wybrane kategorie z tymczasowym profilem, który jest następnie przywracany. Okno jest widoczne i może wymagać uwagi. Pobrane, cookies, zawartość Kosza i poprzednie instalacje Windows są wykluczone. Operacja nie działa całkowicie po cichu. |
| **3** | Zrzuty pamięci i awarii | Wyszukuje zrzuty w standardowych lokalizacjach Windows i użytkownika, wyświetla listę i prosi o potwierdzenie przed trwałym usunięciem. |
| **4** | Punkty przywracania systemu | Wyświetla punkty i pozwala zaznaczyć pojedyncze lub wszystkie. Usunięcie jest trwałe; po usunięciu wybranych punktów program może spróbować utworzyć nowy, jeśli pozwala na to Windows. |
| **5** | Archiwalne logi diagnostyczne i instalacyjne | Usuwa obsługiwane pasujące logi starsze niż 30 dni. Bieżące/aktywne logi i dzienniki zdarzeń Windows pozostają bez zmian. |
| **6** | Obsługa magazynu składników DISM | Analizuje magazyn składników i wykonuje standardowe czyszczenie. Końcowy etap **ResetBase** wymaga osobnego potwierdzenia i jest nieodwracalny: zainstalowanych aktualizacji Windows nie można już odinstalować, a poprzednich wersji zastąpionych składników nie można przywrócić. |

Liczba plików i odzyskane miejsce zależą od wybranych operacji. Niektóre narzędzia Windows nie udostępniają dokładnych statystyk dla każdego pliku.

## Szybki start GUI

1. Otwórz [Wydania](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases/latest) i pobierz `Win11JunkFileRemovalGui.exe`.
2. Uruchom plik. Zaakceptuj monit UAC, jeśli Windows poprosi o uprawnienia administratora.
3. Zaznacz operacje i kliknij **Uruchom**. Przed potwierdzeniem przeczytaj monity dotyczące poszczególnych działań.
4. Obserwuj postęp i komunikaty. Jeśli Oczyszczanie dysku czeka na reakcję, przełącz się na jego okno z paska zadań. Nie zamykaj programu czyszczącego, dopóki operacja się nie zakończy.
5. Sprawdź podsumowanie. Użyj **Otwórz plik log** lub **Eksportuj logi**, aby przejrzeć albo zapisać szczegółowy raport, w tym informacje o pominiętych elementach.

Opublikowane GUI jest samodzielną aplikacją w pojedynczym pliku. Podczas uruchamiania może rozpakować składniki środowiska; nie wymaga osobnego skryptu ani instalacji .NET.

## Szybki start PowerShell

1. Pobierz [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1).
2. Otwórz PowerShell w folderze pliku i uruchom:

   ```powershell
   .\WIN11_SYSTEM_CLEANER.ps1
   ```

3. **1–6** przełącza pojedyncze operacje, **7** wszystkie, **Enter** uruchamia wybór, a **0** kończy. Postępuj zgodnie z monitami.

Skrypt nie zmienia ustawień Execution Policy. Jeśli organizacja ogranicza uruchamianie skryptów, postępuj zgodnie z jej polityką lub skontaktuj się z administratorem.

## Wymagania

- Windows 10 lub Windows 11; opublikowane GUI wymaga systemu 64-bitowego (x64).
- Windows PowerShell 5.1 lub PowerShell 7.x do uruchomienia samodzielnego skryptu.
- Zgoda administratora przez UAC dla czyszczenia systemowego. Windows lub polityka organizacji mogą ograniczać niektóre działania.
- Opublikowane, samodzielne GUI nie wymaga osobnej instalacji .NET.

## Bezpieczeństwo, prywatność i ograniczenia

- **Dane osobiste przeglądarek są poza zakresem:** cookies, zapisane hasła, historia, profile przeglądarek i dokumenty osobiste nie są celem czyszczenia.
- **Cache jest ograniczony do rozpoznanych lokalizacji:** sprawdzane są tylko obsługiwane ścieżki; pamięci podręczne aplikacji mniejsze niż 100 MB pozostają bez zmian.
- **Aplikacje nie są zamykane wymuszeniem:** po zaakceptowaniu monitu program prosi obsługiwane aplikacje o normalne zamknięcie okna. Wcześniej zapisz pracę; niezamknięte okna mogą nadal blokować pliki.
- **Błędy są zapisywane:** niedostępne lub używane pliki i foldery są w miarę możliwości pomijane, a szczegóły trafiają do logu. Uprawnienia administratora nie gwarantują usunięcia każdego zablokowanego pliku.
- **Dowiązania/reparse points nie są śledzone** podczas rekurencyjnego czyszczenia folderów.
- **Niektóre operacje są nieodwracalne:** usuniętych punktów przywracania nie można odzyskać; DISM ResetBase uniemożliwia odinstalowanie zainstalowanych aktualizacji. Uważnie czytaj monity.
- **Oczyszczanie dysku nie jest całkowicie ciche:** `cleanmgr` otwiera widoczne okno i może czekać na reakcję użytkownika. Pozostaw program uruchomiony do zakończenia.
- **Usługi Windows Update mogą być tymczasowo zatrzymane:** po czyszczeniu pobranych plików aktualizacji skrypt próbuje przywrócić ich wcześniejszy stan działania.

## Język, wygląd i logi

Skrypt konsolowy wybiera polski lub angielski na podstawie ustawień regionalnych Windows. GUI udostępnia wybór języka i wyglądu. Postęp i komunikaty są widoczne w aplikacji; szczegółowe logi sesji są zapisywane w `%LOCALAPPDATA%\Windows11JunkFileRemoval\Logs`. GUI może otworzyć plik logu albo wyeksportować go w wybrane miejsce.

## Pliki repozytorium

| Plik | Opis |
|---|---|
| [`WIN11_SYSTEM_CLEANER.ps1`](WIN11_SYSTEM_CLEANER.ps1) | Samodzielny skrypt konsolowy; GUI zawiera ten sam skrypt czyszczący. |
| [`README.md`](README.md) | Angielski opis projektu. |
| [`README_PL.md`](README_PL.md) | Polski opis projektu. |
| [`LICENSE`](LICENSE) | GNU General Public License v3.0. |
| [Wydania](https://github.com/aurenhexliner/WIN11_SYSTEM_CLEANER_V3/releases) | GUI, skrypt, sumy kontrolne i opisy wydań. |

## Weryfikacja pobranych plików

Najnowsze wydanie zawiera `SHA256SUMS.txt`. Sumy pobranych plików obliczysz w PowerShell:

```powershell
Get-FileHash .\Win11JunkFileRemovalGui.exe -Algorithm SHA256
Get-FileHash .\WIN11_SYSTEM_CLEANER.ps1 -Algorithm SHA256
```

Porównaj wyświetlone wartości z odpowiednimi wierszami w `SHA256SUMS.txt`.

## Licencja

Projekt jest udostępniany na warunkach [GNU General Public License v3.0](LICENSE). Wiążącym źródłem warunków jest plik `LICENSE` w repozytorium.

---

<div align="center">

**Sprawdź zaznaczenie. Zapisz pracę przed zamykaniem aplikacji. Uruchamiaj tylko operacje, których skutki rozumiesz.**

</div>
