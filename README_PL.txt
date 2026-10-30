Windows 11 Junk File Removal — GUI v1.2.0
Graficzne narzędzie do czyszczenia i konserwacji systemu Windows
======================================================================

To graficzna wersja programu Windows 11 Junk File Removal. Korzysta
z interfejsu WinUI 3 i zawiera osadzony skrypt czyszczący PowerShell.
Zaznacz wybrane operacje w aplikacji i wybierz „Uruchom” w prawym dolnym rogu.
Postęp, komunikaty i obsługiwane pytania są wyświetlane w panelu
„Aktywność”, bez osobnego okna konsoli PowerShell.


WYMAGANIA
----------------------------------------------------------------------

• Windows 10 lub Windows 11 w wersji 64-bitowej (x64)
• Zgoda na podniesienie uprawnień przez UAC dla operacji systemowych
• Opublikowany, samodzielny plik EXE nie wymaga osobnej instalacji .NET


URUCHOMIENIE
----------------------------------------------------------------------

1. Wypakuj pobrane archiwum do wybranego folderu.
2. Uruchom Win11JunkFileRemovalGui.exe.
3. Zaznacz operacje czyszczenia, które chcesz wykonać.
4. Wybierz „Uruchom” w prawym dolnym rogu i zaakceptuj monit UAC, jeśli Windows go
   wyświetli.
5. Odpowiedz na pytania w aplikacji, na przykład dotyczące zamknięcia
   przeglądarek lub wyboru punktów przywracania.
6. Panel postępu pokazuje bieżący etap i element, czas działania, a gdy
   można je wiarygodnie obliczyć — procent wykonania i szacowany pozostały
   czas. Wykres aktualizuje się po kolejnych etapach, prezentuje zmierzone
   odzyskane miejsce i liczbę plików, a po zakończeniu pozostaje obok
   panelu aktywności. Dla cleanmgr/DISM pomiar opiera się na zmianie
   wolnego miejsca dysku systemowego, a dla punktów przywracania na zmianie
   użycia magazynu VSS; aktywność innych procesów może wpłynąć na pomiar.
   Przycisk „Otwórz plik log” aktywuje się po zakończeniu czyszczenia
   i otwiera pełny, bezkolorowy log tej sesji. Osobny plik logu jest
   tworzony przy każdym uruchomieniu. „Eksportuj logi” zapisuje jego kopię.

Aplikację uruchamia się bezpośrednio; nie trzeba osobno instalować
skryptu PowerShell. Samodzielny plik EXE może podczas uruchamiania
rozpakować składniki środowiska uruchomieniowego.


JĘZYK I WYGLĄD
----------------------------------------------------------------------

Aplikacja wybiera język polski lub angielski na podstawie LOCALE systemu
Windows. Domyślnie korzysta z wyglądu systemowego. Aby go zmienić, użyj
opcji wyglądu dostępnych w aplikacji.


OPERACJE CZYSZCZENIA
----------------------------------------------------------------------

GUI uruchamia osadzony skrypt czyszczący Windows. Zależnie od wybranych
operacji może on:

• Usuwać pliki tymczasowe Windows i bieżącego użytkownika oraz rozpoznane
  pamięci podręczne aplikacji o rozmiarze co najmniej 100 MB. Obsługiwane
  aplikacje obejmują Chrome, Edge, Brave, Vivaldi, Opera, Firefox, Discord,
  Teams, Slack, Visual Studio Code i Steam. Cookies, profile przeglądarek
  i inne pliki osobiste są wykluczone.
• Uruchamiać Oczyszczanie dysku (cleanmgr) w widocznym oknie na wykrytych
  dyskach, tylko dla bezpiecznych kategorii. Pobrane, cookies, Kosz
  i poprzednie instalacje Windows są wyłączone.
• Usuwać pozostałości pobierania Windows Update, pamięć podręczną
  Optymalizacji dostarczania oraz zrzuty pamięci
  i awarii, jeśli ma to zastosowanie.
• Wyświetlać punkty przywracania jako listę pól wyboru, aby wybrać
  pojedyncze punkty lub zaznaczyć wszystkie.
• Usuwać archiwalne logi diagnostyczne starsze niż 30 dni, zachowując
  aktywne logi i dzienniki zdarzeń Windows.
• Analizować magazyn składników DISM, wykonać jego czyszczenie oraz
  uruchomić /ResetBase /Defer.

Pliki używane lub niedostępne mogą pozostać na dysku. Panel „Aktywność”
pokazuje ich łączną liczbę w podsumowaniu; szczegółowe ścieżki i powody
znajdują się w automatycznie zapisanym logu sesji w
`%LOCALAPPDATA%\Windows11JunkFileRemoval\Logs`.
Niektóre narzędzia Windows nie udostępniają dokładnej liczby plików ani
ilości zwolnionego miejsca.


WAŻNE OSTRZEŻENIA
----------------------------------------------------------------------

• Przed rozpoczęciem sprawdź zaznaczone operacje. Nie są wyświetlane
  dodatkowe monity o potwierdzenie każdej z nich.
• /ResetBase jest nieodwracalne. Po jego wykonaniu nie można
  odinstalować zainstalowanych aktualizacji Windows ani przywrócić
  poprzednich wersji zastąpionych składników. Punkt przywracania nie
  cofnie tych zmian.
• Oczyszczanie dysku może oczekiwać na reakcję w osobnym oknie. Wtedy
  przełącz się na „Disk Cleanup”/„Oczyszczanie dysku” na pasku zadań
  i nie zamykaj GUI, dopóki operacja się nie zakończy. Program nie
  uruchamia następnej instancji, jeśli poprzednia nadal działa.
• Czyszczenie ogranicza się do jawnie dozwolonych kategorii
  plików tymczasowych, zrzutów, shaderów i logów; nie czyści Pobranych,
  cookies, Kosza ani poprzednich instalacji.
• Usuwanie punktów przywracania jest nieodwracalne. Sprawdź wyświetloną
  listę i dokonaj wyboru ostrożnie. Nowy punkt przywracania jest
  tworzony po czyszczeniu tylko wtedy, gdy wybrano istniejące punkty
  do usunięcia.
• Przed czyszczeniem można zatwierdzić grzeczne zamknięcie wykrytych
  przeglądarek i aplikacji. Procesy nie są kończone siłą; niezapisana
  praca może zostać utracona przy zamykaniu okna.


WERSJA I SKRYPT
----------------------------------------------------------------------

Wersja pliku GUI: 1.2.0
Wersja osadzonego skryptu PowerShell: 2.0

Samodzielny skrypt PowerShell to WIN11_SYSTEM_CLEANER.ps1. Nie zaleca
się używania starszego pliku clean.cmd, który usuwa zawartość
Windows\Logs i SoftwareDistribution bez osobnego wyboru tych operacji.


AUTOR I LICENCJA
----------------------------------------------------------------------

Autor: Jacek Żaczek
Kontakt: j.zaczek@data.pl

Freeware: program jest udostępniany bezpłatnie. Jest to oprogramowanie
własnościowe i nie jest publikowane na licencji open source. Szczegóły
znajdują się w pliku LICENCE.txt dołączonym do archiwum.

SKRYPT KONSOLOWY
----------------------------------------------------------------------

WIN11_SYSTEM_CLEANER.ps1 to ten sam skrypt, który jest osadzony w GUI,
z identycznymi funkcjami. W konsoli uruchom go z podwyższonego PowerShell:
powershell -ExecutionPolicy Bypass -File .\WIN11_SYSTEM_CLEANER.ps1
