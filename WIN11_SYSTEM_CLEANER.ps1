#requires -Version 5.1

param(
    [string]$GuiOperations,
    [string]$GuiPipeName,
    [ValidateSet('en', 'pl')]
    [string]$InterfaceLanguage
)

$ErrorActionPreference = 'Stop'
$script:RemovedItems = 0
$script:FreedBytes = 0
$script:SkippedItems = 0
$script:SkippedFiles = 0
$script:SkippedDirectories = 0
$script:SkippedDetails = [Collections.Generic.List[string]]::new()
$script:SessionLogPath = $null
$script:RemovedDiagnosticLogs = 0
$script:RemovedRestorePoints = 0
$script:CreatedRestorePoints = 0
$script:PendingRestorePointCreation = $false
$script:CurrentOperationId = $null
$script:RunLog = [Collections.Generic.List[string]]::new()
$script:ConsoleBackgroundColor = [ConsoleColor]::DarkBlue
$script:ConsoleBackgroundRgb = @(11, 18, 32)
$script:UseTrueColorConsole = $false
$script:ConsoleThemeActive = $false
$script:RawUiThemeActive = $false
$script:ConsoleThemeWarning = $null
$script:OriginalRawUiBackground = $null
$script:OriginalRawUiForeground = $null
$script:Language = 'en'
$script:GuiPipe = $null
$script:GuiReader = $null
$script:GuiWriter = $null
try {
    $script:Language = if ((Get-WinSystemLocale).Name -like 'pl*') { 'pl' } else { 'en' }
}
catch {
    if ((Get-UICulture).Name -like 'pl*') { $script:Language = 'pl' }
}
if ($InterfaceLanguage) {
    $script:Language = $InterfaceLanguage
}
$displayCultureName = if ($script:Language -eq 'pl') { 'pl-PL' } else { 'en-US' }
$script:DisplayCulture = [Globalization.CultureInfo]::GetCultureInfo($displayCultureName)

if (-not ('CleanerConsoleTheme' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class CleanerConsoleTheme
{
    [StructLayout(LayoutKind.Sequential)]
    private struct CONSOLE_SCREEN_BUFFER_INFOEX
    {
        public int Size;
        public COORD BufferSize;
        public COORD CursorPosition;
        public ushort Attributes;
        public SMALL_RECT Window;
        public COORD MaximumWindowSize;
        public ushort PopupAttributes;
        [MarshalAs(UnmanagedType.Bool)]
        public bool FullscreenSupported;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)]
        public uint[] ColorTable;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct COORD
    {
        public short X;
        public short Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct SMALL_RECT
    {
        public short Left;
        public short Top;
        public short Right;
        public short Bottom;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr GetStdHandle(int handle);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetConsoleMode(IntPtr handle, out uint mode);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool SetConsoleMode(IntPtr handle, uint mode);

    [DllImport("kernel32.dll", EntryPoint = "GetConsoleScreenBufferInfoEx", SetLastError = true)]
    private static extern bool GetBufferInfo(IntPtr handle, ref CONSOLE_SCREEN_BUFFER_INFOEX info);

    [DllImport("kernel32.dll", EntryPoint = "SetConsoleScreenBufferInfoEx", SetLastError = true)]
    private static extern bool SetBufferInfo(IntPtr handle, ref CONSOLE_SCREEN_BUFFER_INFOEX info);

    private static IntPtr outputHandle = IntPtr.Zero;
    private static uint originalMode;
    private static bool modeChanged;
    private static CONSOLE_SCREEN_BUFFER_INFOEX originalBufferInfo;
    private static bool paletteChanged;

    public static bool EnableVirtualTerminal()
    {
        outputHandle = GetStdHandle(-11);
        uint mode;
        if (outputHandle == IntPtr.Zero || outputHandle == new IntPtr(-1) ||
            !GetConsoleMode(outputHandle, out mode))
            return false;

        originalMode = mode;
        if ((mode & 0x0004) == 0)
        {
            if (!SetConsoleMode(outputHandle, mode | 0x0004))
                return false;
            modeChanged = true;
        }
        return true;
    }

    public static bool SetPalette(uint[] colors)
    {
        if (outputHandle == IntPtr.Zero || colors == null || colors.Length != 16)
            return false;

        var info = new CONSOLE_SCREEN_BUFFER_INFOEX();
        info.Size = Marshal.SizeOf(typeof(CONSOLE_SCREEN_BUFFER_INFOEX));
        info.ColorTable = new uint[16];
        if (!GetBufferInfo(outputHandle, ref info))
            return false;

        originalBufferInfo = info;
        paletteChanged = true;
        Array.Copy(colors, info.ColorTable, 16);
        return SetBufferInfo(outputHandle, ref info);
    }

    public static void Restore()
    {
        if (paletteChanged && outputHandle != IntPtr.Zero)
        {
            SetBufferInfo(outputHandle, ref originalBufferInfo);
            paletteChanged = false;
        }
        if (modeChanged && outputHandle != IntPtr.Zero)
        {
            SetConsoleMode(outputHandle, originalMode);
            modeChanged = false;
        }
    }
}
'@ -ErrorAction SilentlyContinue
}

function Initialize-ConsoleTheme {
    if ([Console]::IsOutputRedirected) {
        return
    }

    try {
        $script:UseTrueColorConsole = [CleanerConsoleTheme]::EnableVirtualTerminal()
    }
    catch {
        $script:UseTrueColorConsole = $false
        $script:ConsoleThemeWarning = 'True-color console mode is unavailable.'
    }

    if ($script:UseTrueColorConsole) {
        $script:ConsoleThemeActive = $true
        $background = $script:ConsoleBackgroundRgb -join ';'
        [Console]::Write("$([char]27)[0m$([char]27)[48;2;${background}m$([char]27)[2J$([char]27)[H")
        return
    }

    try {
        $palette = [uint32[]]@(
            0x00101820, 0x0020120B, 0x00002A00, 0x00202A00,
            0x00000036, 0x00360036, 0x00363600, 0x00C8D1DA,
            0x00607080, 0x00FF6060, 0x0060E060, 0x00FFE060,
            0x00FFB060, 0x00E060E0, 0x0060E0E0, 0x00FFFFFF
        )
        $script:ConsoleThemeActive = [CleanerConsoleTheme]::SetPalette($palette)
    }
    catch {
        $script:ConsoleThemeActive = $false
        $script:ConsoleThemeWarning = 'The console color palette could not be adjusted.'
    }

    try {
        $script:OriginalRawUiBackground = $Host.UI.RawUI.BackgroundColor
        $script:OriginalRawUiForeground = $Host.UI.RawUI.ForegroundColor
        $script:RawUiThemeActive = $true
        $Host.UI.RawUI.BackgroundColor = $script:ConsoleBackgroundColor
        $Host.UI.RawUI.ForegroundColor = [ConsoleColor]::Gray
        Clear-Host
    }
    catch {
        $script:ConsoleThemeWarning = 'The host rejected the requested console colors.'
    }
}

function Restore-ConsoleTheme {
    if ($script:UseTrueColorConsole -and -not [Console]::IsOutputRedirected) {
        [Console]::Write("$([char]27)[0m$([char]27)[49m")
    }
    if ($script:ConsoleThemeActive) {
        try { [CleanerConsoleTheme]::Restore() } catch { }
    }
    if ($script:RawUiThemeActive) {
        try {
            $Host.UI.RawUI.BackgroundColor = $script:OriginalRawUiBackground
            $Host.UI.RawUI.ForegroundColor = $script:OriginalRawUiForeground
        }
        catch { }
    }
    $script:UseTrueColorConsole = $false
    $script:ConsoleThemeActive = $false
    $script:RawUiThemeActive = $false
}

function Clear-ConsoleScreen {
    if ($script:UseTrueColorConsole -and -not [Console]::IsOutputRedirected) {
        $background = $script:ConsoleBackgroundRgb -join ';'
        [Console]::Write("$([char]27)[0m$([char]27)[48;2;${background}m$([char]27)[2J$([char]27)[H")
        return
    }
    Clear-Host
}

if (-not $GuiPipeName) {
    Initialize-ConsoleTheme
}

$script:TextMap = @{
    'WINDOWS 11  |  PORZADKI SYSTEMOWE' = @{ pl = 'WINDOWS 11  |  PORZĄDKI SYSTEMOWE'; en = 'WINDOWS 11  |  Windows 11 Junk File Removal v2.0' }
    'Bezpieczne czyszczenie plikow tymczasowych i wybranych pamieci podrecznych' = @{ pl = 'Bezpieczne czyszczenie plików tymczasowych i wybranych pamięci podręcznych'; en = 'Safe cleanup of temporary files and selected caches' }
    'Objete potwierdzeniem zbiorczym.' = @{ pl = 'Objęte potwierdzeniem zbiorczym.'; en = 'Covered by the bulk confirmation.' }
    'brak plikow' = @{ pl = 'brak plików'; en = 'no files found' }
    'Nie usunieto' = @{ pl = 'Nie usunięto'; en = 'Could not remove' }
    'Usunieto' = @{ pl = 'Usunięto'; en = 'Deleted' }
    'usuniieto' = @{ pl = 'usunięto'; en = 'removed' }
    'usunięto' = @{ pl = 'usunięto'; en = 'removed' }
    'elementow' = @{ pl = 'elementów'; en = 'items' }
    'ok.' = @{ pl = 'ok.'; en = 'approx.' }
    'Pominieto' = @{ pl = 'Pominięto'; en = 'Skipped' }
    'np. pliki uzywane lub dowiazania' = @{ pl = 'np. pliki używane lub dowiązania'; en = 'for example, files in use or reparse points' }
    'Czyszczenie plikow tymczasowych i cache' = @{ pl = 'Czyszczenie plików tymczasowych i pamięci podręcznej'; en = 'Temporary files and cache cleanup' }
    'Zamknij przegladarki i aplikacje, aby zwiekszyc skutecznosc.' = @{ pl = 'Zamknij przeglądarki i aplikacje, aby zwiększyć skuteczność.'; en = 'Close browsers and apps first for best results.' }
    'Zamknac wykryte przegladarki i aplikacje? Niezapisana praca moze zostac utracona. Zostana zamkniete tylko okna, bez wymuszania zakonczenia.' = @{ pl = 'Zamknąć wykryte przeglądarki i aplikacje? Niezapisana praca może zostać utracona. Zostaną zamknięte tylko okna, bez wymuszania zakończenia.'; en = 'Close detected browsers and apps? Unsaved work may be lost. Only windows will be asked to close; processes will not be force-terminated.' }
    'Wybrano zamkniecie aplikacji' = @{ pl = 'Wybrano zamknięcie aplikacji'; en = 'Close applications' }
    'Aplikacje pozostawione uruchomione' = @{ pl = 'Aplikacje pozostawione uruchomione'; en = 'Applications left running' }
    'Cache pomniejszy niz 100 MB pozostawiono bez zmian.' = @{ pl = 'Pamięci podręczne mniejsze niż 100 MB pozostawiono bez zmian.'; en = 'Caches smaller than 100 MB were left unchanged.' }
    'Zaznacz punkty przywracania do trwalego usuniecia. Operacji nie mozna cofnac.' = @{ pl = 'Zaznacz punkty przywracania do trwałego usunięcia. Operacji nie można cofnąć.'; en = 'Select restore points to permanently delete. This operation cannot be undone.' }
    'Usun zaznaczone punkty' = @{ pl = 'Usuń zaznaczone punkty'; en = 'Delete selected points' }
    'Wybor punktow anulowany; niczego nie usunieto.' = @{ pl = 'Anulowano wybór punktów; niczego nie usunięto.'; en = 'Restore-point selection cancelled; nothing was deleted.' }
    'Usunac znalezione zrzuty pamieci? Usuniecie jest trwale.' = @{ pl = 'Usunąć znalezione zrzuty pamięci? Usunięcie jest trwałe.'; en = 'Delete the listed memory dumps? This is permanent.' }
    'Uruchomic nieodwracalne ResetBase? Po tej operacji nie bedzie mozna odinstalowac zainstalowanych aktualizacji.' = @{ pl = 'Uruchomić nieodwracalne ResetBase? Po tej operacji nie będzie można odinstalować zainstalowanych aktualizacji.'; en = 'Run irreversible ResetBase? Installed updates cannot be uninstalled afterward.' }
    'Rozpoczac czyszczenie?' = @{ pl = 'Rozpocząć czyszczenie?'; en = 'Start cleanup?' }
    'Pominieto czyszczenie.' = @{ pl = 'Pominięto czyszczenie.'; en = 'Cleanup skipped.' }
    'Tymczasowe pliki Windows' = @{ pl = 'Tymczasowe pliki Windows'; en = 'Windows temporary files' }
    'Tymczasowe pliki Windows TMP' = @{ pl = 'Tymczasowe pliki Windows TMP'; en = 'Windows TMP files' }
    'Tymczasowe pliki TMP uzytkownika' = @{ pl = 'Tymczasowe pliki TMP użytkownika'; en = 'User TMP files' }
    'Tymczasowe pliki biezacego uzytkownika' = @{ pl = 'Tymczasowe pliki bieżącego użytkownika'; en = 'Current user temporary files' }
    'Lokalny katalog Temp uzytkownika' = @{ pl = 'Lokalny katalog Temp użytkownika'; en = 'User local Temp folder' }
    'Pamiec podreczna shaderow DirectX' = @{ pl = 'Pamięć podręczna shaderów DirectX'; en = 'DirectX shader cache' }
    'Archiwalne raporty bledow Windows' = @{ pl = 'Archiwalne raporty błędów Windows'; en = 'Archived Windows error reports' }
    'Oczekujace raporty bledow Windows' = @{ pl = 'Oczekujące raporty błędów Windows'; en = 'Queued Windows error reports' }
    'Cache aplikacji' = @{ pl = 'Pamięć podręczna aplikacji'; en = 'Application cache' }
    'Czyszczenie pobranych plikow Windows Update wymaga zatrzymania uslug.' = @{ pl = 'Czyszczenie pobranych plików Windows Update wymaga zatrzymania usług.'; en = 'Cleaning downloaded Windows Update files requires stopping services.' }
    'Usunac pliki pobrane przez Windows Update?' = @{ pl = 'Usunąć pobrane pliki Windows Update?'; en = 'Delete downloaded Windows Update files?' }
    'Nie udalo sie ponownie uruchomic uslugi' = @{ pl = 'Nie udało się ponownie uruchomić usługi'; en = 'Could not restart service' }
    'Usunac cache Optymalizacji dostarczania Windows?' = @{ pl = 'Usunąć pamięć podręczną optymalizacji dostarczania Windows?'; en = 'Delete the Windows Delivery Optimization cache?' }
    'Usunieto cache Optymalizacji dostarczania.' = @{ pl = 'Usunięto pamięć podręczną optymalizacji dostarczania.'; en = 'Delivery Optimization cache removed.' }
    'Oproznic Kosz? Ta operacja trwale usuwa jego zawartosc.' = @{ pl = 'Opróżnić Kosz? Ta operacja trwale usuwa jego zawartość.'; en = 'Empty the Recycle Bin? This permanently deletes its contents.' }
    'Oprozniono Kosz biezacego uzytkownika.' = @{ pl = 'Opróżniono Kosz bieżącego użytkownika.'; en = 'Emptied the current user''s Recycle Bin.' }
    'Nie znaleziono polecenia Clear-RecycleBin; Kosz pozostawiono bez zmian.' = @{ pl = 'Nie znaleziono polecenia Clear-RecycleBin; Kosz pozostawiono bez zmian.'; en = 'Clear-RecycleBin is unavailable; the Recycle Bin was left unchanged.' }
    'Wbudowane Oczyszczanie dysku' = @{ pl = 'Wbudowane Oczyszczanie dysku'; en = 'Built-in Disk Cleanup' }
    'Koncowy etap: DISM i magazyn skladnikow' = @{ pl = 'Końcowy etap: DISM i magazyn składników'; en = 'Final stage: DISM and the component store' }
    'Nie znaleziono programu DISM.' = @{ pl = 'Nie znaleziono programu DISM.'; en = 'DISM was not found.' }
    'DISM wykona kolejno analize, standardowe czyszczenie i ResetBase /Defer.' = @{ pl = 'DISM kolejno przeanalizuje magazyn, wykona standardowe czyszczenie i ResetBase /Defer.'; en = 'DISM will analyze the component store, run standard cleanup, then ResetBase /Defer.' }
    'RESETBASE JEST NIEODWRACALNE:' = @{ pl = 'RESETBASE JEST NIEODWRACALNE:'; en = 'RESETBASE IS IRREVERSIBLE:' }
    'po wykonaniu nie bedzie mozna odinstalowac obecnie zainstalowanych aktualizacji Windows;' = @{ pl = 'po wykonaniu nie będzie można odinstalować obecnie zainstalowanych aktualizacji Windows;'; en = 'installed Windows updates can no longer be uninstalled;' }
    'nie bedzie mozna przywrocic poprzednich wersji zastapionych skladnikow;' = @{ pl = 'nie będzie można przywrócić poprzednich wersji zastąpionych składników;'; en = 'previous versions of superseded components cannot be restored;' }
    'Punkt przywracania nie cofnie tych zmian.' = @{ pl = 'Punkt przywracania nie cofnie tych zmian.'; en = 'A restore point will not undo these changes.' }
    'Analiza magazynu skladnikow (bez wprowadzania zmian)...' = @{ pl = 'Analiza magazynu składników (bez wprowadzania zmian)...'; en = 'Analyzing the component store (no changes will be made)...' }
    'Analiza DISM zakonczyla sie kodem' = @{ pl = 'Analiza DISM zakończyła się kodem'; en = 'DISM analysis exited with code' }
    'dalsze kroki pominieto.' = @{ pl = 'dalsze kroki pominięto.'; en = 'remaining steps skipped.' }
    'Standardowe czyszczenie zastapionych skladnikow...' = @{ pl = 'Standardowe czyszczenie zastąpionych składników...'; en = 'Cleaning up superseded components...' }
    'Standardowe czyszczenie DISM zakonczylo sie kodem' = @{ pl = 'Standardowe czyszczenie DISM zakończyło się kodem'; en = 'Standard DISM cleanup exited with code' }
    'ResetBase pominieto.' = @{ pl = 'ResetBase pominięto.'; en = 'ResetBase skipped.' }
    'ResetBase pominieto zgodnie z wyborem uzytkownika.' = @{ pl = 'ResetBase pominięto zgodnie z wyborem użytkownika.'; en = 'ResetBase was declined by the user.' }
    'Uruchamiam ResetBase /Defer (bez mozliwosci odinstalowania aktualizacji)...' = @{ pl = 'Uruchamiam ResetBase /Defer (bez możliwości odinstalowania aktualizacji)...'; en = 'Running ResetBase /Defer (updates will no longer be uninstallable)...' }
    'ResetBase DISM zakonczyl sie kodem' = @{ pl = 'ResetBase DISM zakończył się kodem'; en = 'DISM ResetBase exited with code' }
    'Oczyszczanie dysku Windows (bezpieczne kategorie)' = @{ pl = 'Oczyszczanie dysku Windows (bezpieczne kategorie)'; en = 'Windows Disk Cleanup (safe categories)' }
    'Oczyszczanie dysku jest otwarte. Jesli czeka, przelacz sie na jego okno z paska zadan. Nie zamykaj tej aplikacji; czyszczenie wznowi sie po zakonczeniu cleanmgr.' = @{ pl = 'Oczyszczanie dysku jest otwarte. Jeśli czeka, przełącz się na jego okno z paska zadań. Nie zamykaj tej aplikacji; czyszczenie wznowi się po zakończeniu cleanmgr.'; en = 'Disk Cleanup is open. If it is waiting, switch to its window from the taskbar. Keep this app open; cleanup will resume when cleanmgr exits.' }
    'Wykryto juz uruchomione Oczyszczanie dysku. Nie uruchamiam kolejnej instancji; przelacz sie na jego okno z paska zadan i poczekaj.' = @{ pl = 'Wykryto już uruchomione Oczyszczanie dysku. Nie uruchamiam kolejnej instancji; przełącz się na jego okno z paska zadań i poczekaj.'; en = 'An existing Disk Cleanup process was detected. No duplicate will be started; switch to its taskbar window and wait.' }
    'Oczekiwanie na zakonczenie Oczyszczania dysku. Jesli wymaga reakcji, jego okno jest dostepne na pasku zadan.' = @{ pl = 'Oczekiwanie na zakończenie Oczyszczania dysku. Jeśli wymaga reakcji, jego okno jest dostępne na pasku zadań.'; en = 'Waiting for Disk Cleanup to finish. If it needs input, its window is available on the taskbar.' }
    'Pobrane, cookies, Kosz i poprzednie instalacje sa jawnie wylaczone.' = @{ pl = 'Pobrane, cookies, Kosz i poprzednie instalacje są jawnie wyłączone.'; en = 'Downloads, cookies, the Recycle Bin, and previous Windows installations are explicitly excluded.' }
    'Profil cleanmgr jest tymczasowy i zostanie przywrocony po zakonczeniu.' = @{ pl = 'Profil cleanmgr jest tymczasowy i zostanie przywrócony po zakończeniu.'; en = 'The temporary cleanmgr profile will be restored when cleanup finishes.' }
    'Nie znaleziono cleanmgr.exe.' = @{ pl = 'Nie znaleziono cleanmgr.exe.'; en = 'cleanmgr.exe was not found.' }
    'Czyszczenie kategorii cleanmgr (profil tymczasowy' = @{ pl = 'Czyszczenie kategorii cleanmgr (profil tymczasowy'; en = 'Cleaning cleanmgr categories (temporary profile' }
    'zakonczyl sie kodem' = @{ pl = 'zakończył się kodem'; en = 'exited with code' }
    'Usuwanie pozostalosci po poprzednich aktualizacjach Windows...' = @{ pl = 'Usuwanie pozostałości po poprzednich aktualizacjach Windows...'; en = 'Removing remnants of previous Windows upgrades...' }
    'Czyszczenie cleanmgr zakonczone.' = @{ pl = 'Czyszczenie cleanmgr zakończone.'; en = 'cleanmgr cleanup complete.' }
    'Zrzuty pamieci i awarii' = @{ pl = 'Zrzuty pamięci i awarii'; en = 'Memory and crash dumps' }
    'Nie znaleziono zrzutow w typowych lokalizacjach.' = @{ pl = 'Nie znaleziono zrzutów w typowych lokalizacjach.'; en = 'No dumps were found in the usual locations.' }
    'Usunac pokazane zrzuty' = @{ pl = 'Usunąć pokazane zrzuty'; en = 'Delete the listed dumps' }
    'Lista obejmuje tylko standardowe lokalizacje zrzutow systemu i aplikacji.' = @{ pl = 'Lista obejmuje tylko standardowe lokalizacje zrzutów systemu i aplikacji.'; en = 'Only standard Windows and application dump locations are listed.' }
    'Dzienniki zdarzen Windows' = @{ pl = 'Dzienniki zdarzeń Windows'; en = 'Windows event logs' }
    'Ta operacja usuwa historie diagnostyczna i audytowa, w tym dziennik Security.' = @{ pl = 'Ta operacja usuwa historię diagnostyczną i audytową, w tym dziennik Security.'; en = 'This removes diagnostic and audit history, including the Security log.' }
    'Nie zalecamy jej rutynowo; moze utrudnic diagnostyke problemow.' = @{ pl = 'Nie zalecamy tej operacji rutynowo; może utrudnić diagnozowanie problemów.'; en = 'This is not recommended routinely; it can make troubleshooting harder.' }
    'Aby wyczyscic wszystkie dzienniki, wpisz DZIENNIKI' = @{ pl = 'Aby wyczyścić wszystkie dzienniki, wpisz DZIENNIKI'; en = 'Type EVENTLOGS to clear all logs' }
    'Dzienniki pozostawiono bez zmian.' = @{ pl = 'Dzienniki pozostawiono bez zmian.'; en = 'Event logs were left unchanged.' }
    'wevtutil nie mogl pobrac listy dziennikow (kod' = @{ pl = 'wevtutil nie mógł pobrać listy dzienników (kod'; en = 'wevtutil could not retrieve the log list (exit code' }
    'Dzienniki niedostepne lub chronione, pozostawione bez zmian:' = @{ pl = 'Dzienniki niedostępne lub chronione, pozostawione bez zmian:'; en = 'Inaccessible or protected logs left unchanged:' }
    'Punkty przywracania systemu' = @{ pl = 'Punkty przywracania systemu'; en = 'System restore points' }
    'Nie mozna odczytac punktow przywracania:' = @{ pl = 'Nie można odczytać punktów przywracania:'; en = 'Could not read restore points:' }
    'Sprawdz, czy Ochrona systemu jest wlaczona dla dysku systemowego.' = @{ pl = 'Sprawdź, czy Ochrona systemu jest włączona dla dysku systemowego.'; en = 'Check whether System Protection is enabled for the system drive.' }
    'System nie zglasza dostepnych punktow przywracania.' = @{ pl = 'System nie zgłasza dostępnych punktów przywracania.'; en = 'The system reports no available restore points.' }
    '  Nr       Data utworzenia         Opis' = @{ pl = '  Nr       Data utworzenia         Opis'; en = '  No.      Creation date           Description' }
    'Enter comma separated numbers to delete (ex. 10,11) or type ALL to delete all restore points listed above' = @{ pl = 'Wpisz numery punktów do usunięcia, oddzielając je przecinkami (np. 10,11), lub wpisz ALL, aby usunąć wszystkie widoczne punkty'; en = 'Enter comma-separated numbers to delete (e.g. 10,11), or type ALL to delete all restore points listed above' }
    'Enter restore point numbers or "ALL" (press ENTER to cancel whole operation)' = @{ pl = 'Wpisz numery punktów przywracania lub „ALL” (naciśnij ENTER, aby anulować całą operację)'; en = 'Enter restore point numbers or "ALL" (press ENTER to cancel the whole operation)' }
    'ALL mozna podac samodzielnie. Niczego nie usunieto.' = @{ pl = 'ALL można podać samodzielnie. Niczego nie usunięto.'; en = 'Enter ALL by itself. Nothing was deleted.' }
    'Nieprawidlowy lub nieistniejacy numer:' = @{ pl = 'Nieprawidłowy lub nieistniejący numer:'; en = 'Invalid or unknown number:' }
    'Niczego nie usunieto.' = @{ pl = 'Niczego nie usunięto.'; en = 'Nothing was deleted.' }
    'Do usuniecia:' = @{ pl = 'Do usunięcia:'; en = 'Selected for deletion:' }
    'Aby potwierdzic, wpisz USUN PUNKTY' = @{ pl = 'Aby potwierdzić, wpisz USUŃ PUNKTY'; en = 'Type DELETE RESTORE POINTS to confirm' }
    'Punkty pozostawiono bez zmian.' = @{ pl = 'Punkty pozostawiono bez zmian.'; en = 'Restore points were left unchanged.' }
    'Nie mozna zaladowac SrClient.dll.' = @{ pl = 'Nie można załadować SrClient.dll.'; en = 'Could not load SrClient.dll.' }
    'Nie znaleziono funkcji SRRemoveRestorePoint.' = @{ pl = 'Nie znaleziono funkcji SRRemoveRestorePoint.'; en = 'SRRemoveRestorePoint was not found.' }
    'Nie udalo sie usunac punktu' = @{ pl = 'Nie udało się usunąć punktu'; en = 'Could not delete restore point' }
    'Windows odmowil usuniecia tego punktu; moze byc chroniony lub zarzadzany przez system.' = @{ pl = 'Windows odmówił usunięcia tego punktu; może być chroniony lub zarządzany przez system.'; en = 'Windows denied deletion; this point may be protected or system-managed.' }
    'Czy po zmianach utworzyc nowy punkt przywracania?' = @{ pl = 'Czy po zmianach utworzyć nowy punkt przywracania?'; en = 'Create a new restore point after cleanup?' }
    'Punkt po zarzadzaniu punktami przywracania' = @{ pl = 'Punkt po zarządzaniu punktami przywracania'; en = 'After restore-point cleanup' }
    'Utworzono nowy punkt przywracania.' = @{ pl = 'Utworzono nowy punkt przywracania.'; en = 'A new restore point was created.' }
    'Nie utworzono punktu przywracania:' = @{ pl = 'Nie utworzono punktu przywracania:'; en = 'Could not create a restore point:' }
    'Windows moze ograniczac tworzenie punktow do jednego na 24 godziny.' = @{ pl = 'Windows może ograniczać tworzenie punktów do jednego na 24 godziny.'; en = 'Windows may limit restore point creation to once every 24 hours.' }
    'Bezpieczne czyszczenie (Temp, cache przegladarek, WER, Windows Update)' = @{ pl = 'Bezpieczne czyszczenie (Temp, pamięci podręczne przeglądarek, WER i Windows Update)'; en = 'Safe cleanup (Temp, browser caches, WER, and Windows Update)' }
    'DISM: analiza, czyszczenie i ResetBase (blokuje odinstalowanie aktualizacji)' = @{ pl = 'DISM: analiza, czyszczenie i ResetBase (blokuje odinstalowanie aktualizacji)'; en = 'DISM: analyze, clean up, and ResetBase (prevents update uninstall)' }
    'Wcisnij cyfre 1-6, aby wybrac warianty czyszczenia. 7 zaznacza wszystkie.' = @{ pl = 'Wciśnij cyfrę 1–6, aby wybrać warianty czyszczenia. 7 zaznacza wszystkie.'; en = 'Press 1–6 to select cleanup options. Press 7 to select all.' }
    'Zarzadzaj punktami przywracania (wybor konkretnych punktow)' = @{ pl = 'Zarządzaj punktami przywracania (wybierz konkretne punkty)'; en = 'Manage restore points (select specific points)' }
    'Wyszukaj i opcjonalnie usun zrzuty DMP' = @{ pl = 'Wyszukaj i opcjonalnie usuń zrzuty DMP'; en = 'Find and optionally delete DMP files' }
    'Wybrano czyszczenie archiwalnych logow diagnostycznych' = @{ pl = 'Wybrano czyszczenie archiwalnych logów diagnostycznych'; en = 'Archived diagnostic log cleanup selected' }
    'Wybrane operacje:' = @{ pl = 'Wybrane operacje:'; en = 'Selected operations:' }
    'UWAGA: DISM ResetBase jest nieodwracalne i blokuje odinstalowanie aktualizacji Windows.' = @{ pl = 'UWAGA: DISM ResetBase jest nieodwracalne i blokuje odinstalowanie aktualizacji Windows.'; en = 'WARNING: DISM ResetBase is irreversible and prevents uninstalling Windows updates.' }
    'cleanmgr uzyje tylko bezpiecznych kategorii; dane uzytkownika, Kosz i poprzednie instalacje sa wylaczone.' = @{ pl = 'cleanmgr użyje tylko bezpiecznych kategorii; dane użytkownika, Kosz i poprzednie instalacje są wyłączone.'; en = 'cleanmgr uses only safe categories; user data, the Recycle Bin, and previous installations are excluded.' }
    'Pobrane/Downloads jest wylaczone z profilu.' = @{ pl = 'Pobrane/Downloads jest wyłączone z profilu.'; en = 'Downloads is excluded from the profile.' }
    'Potwierdzenie obejmuje wszystkie pozycje, w tym usuwanie archiwalnych logow, zarzadzanie punktami przywracania oraz nieodwracalne ResetBase.' = @{ pl = 'Potwierdzenie obejmuje wszystkie pozycje, w tym usuwanie archiwalnych logów, zarządzanie punktami przywracania i nieodwracalne ResetBase.'; en = 'This confirms all options, including archived log cleanup, restore-point management, and irreversible ResetBase.' }
    'Czy uruchomic wybrane operacje?' = @{ pl = 'Czy uruchomić wybrane operacje?'; en = 'Run the selected operations?' }
    'Nie wybrano zadnej operacji.' = @{ pl = 'Nie wybrano żadnej operacji.'; en = 'No operations selected.' }
    'Wcisnij cyfre 1-6, aby wybrac warianty czyszczenia. 7 zaznacza wszystkie. 0 wybiera wyjscie; Enter je zatwierdza.' = @{ pl = 'Wciśnij cyfrę 1–6, aby wybrać warianty czyszczenia. 7 zaznacza wszystkie. 0 wybiera wyjście; Enter je zatwierdza.'; en = 'Press 1–6 to select cleanup options. Press 7 to select all. Press 0, then Enter, to exit.' }
    'Wyjdz z programu' = @{ pl = 'Wyjdź z programu'; en = 'Exit the program' }
    'Nie mozna w pelni ustawic kolorow terminala; zastosowano dostepny tryb zgodnosci.' = @{ pl = 'Nie można w pełni ustawić kolorów terminala; zastosowano dostępny tryb zgodności.'; en = 'The terminal colors could not be fully configured; using the available compatibility mode.' }
    'ENTER - zatwierdz wybor' = @{ pl = 'ENTER – zatwierdź wybór'; en = 'ENTER – confirm selection' }
    'ZAZNACZ WSZYSTKIE opcje (ponowne 7 odznacza wszystkie)' = @{ pl = 'ZAZNACZ WSZYSTKIE opcje (ponowne 7 odznacza wszystkie)'; en = 'SELECT ALL options (press 7 again to clear all)' }
    'BLAD w opcji' = @{ pl = 'BŁĄD w opcji'; en = 'ERROR in option' }
    'Ten skrypt jest przeznaczony dla systemu Windows.' = @{ pl = 'Ten skrypt jest przeznaczony dla systemu Windows.'; en = 'This script is intended for Windows.' }
    'Skrypt wymaga uprawnien administratora. Otwieram okno UAC...' = @{ pl = 'Skrypt wymaga uprawnień administratora. Otwieram okno UAC...'; en = 'Administrator privileges are required. Opening the UAC prompt...' }
    'Sesja zakonczyla sie.' = @{ pl = 'Sesja zakończyła się.'; en = 'Session finished.' }
    'Nacisnij ENTER, aby zamknac to okno.' = @{ pl = 'Naciśnij ENTER, aby zamknąć to okno.'; en = 'Press ENTER to close this window.' }
    'Usuniete elementy:' = @{ pl = 'Usunięte elementy:'; en = 'Items removed:' }
    'Pominiete:' = @{ pl = 'Pominięte:'; en = 'Skipped:' }
    'Szacowane dane:' = @{ pl = 'Szacowane dane:'; en = 'Estimated data:' }
    'Podsumowanie czyszczenia' = @{ pl = 'Podsumowanie czyszczenia'; en = 'Cleanup summary' }
    'Operacje wykonane:' = @{ pl = 'Wykonane operacje:'; en = 'Operations run:' }
    'Usuniete pliki:' = @{ pl = 'Usunięte pliki:'; en = 'Files removed:' }
    'Odzyskane miejsce (szacunek):' = @{ pl = 'Odzyskane miejsce (szacunek):'; en = 'Space reclaimed (estimated):' }
    'Odzyskane miejsce z mierzonych operacji (szacunek):' = @{ pl = 'Odzyskane miejsce z mierzonych operacji (szacunek):'; en = 'Estimated space reclaimed by tracked operations:' }
    'Odzyskane miejsce: brak danych z wybranych operacji.' = @{ pl = 'Odzyskane miejsce: brak danych z wybranych operacji.'; en = 'Space reclaimed: no data was reported by the selected operations.' }
    'Pominiete pliki lub elementy:' = @{ pl = 'Pominięte pliki lub elementy:'; en = 'Skipped files or items:' }
    'Nieusuniete pliki i katalogi: {0} plikow, {1} katalogow. Szczegoly zapisano w pliku logu.' = @{ pl = 'Nieusunięte pliki i katalogi: {0} plików, {1} katalogów. Szczegóły zapisano w pliku logu.'; en = 'Items not removed: {0} files, {1} folders. Details are in the session log.' }
    'Plik pelnego logu sesji:' = @{ pl = 'Plik pełnego logu sesji:'; en = 'Full session log:' }
    'Usuniete archiwalne logi diagnostyczne:' = @{ pl = 'Usunięte archiwalne logi diagnostyczne:'; en = 'Archived diagnostic logs removed:' }
    'Usuniete punkty przywracania:' = @{ pl = 'Usunięte punkty przywracania:'; en = 'Restore points removed:' }
    'Utworzone punkty przywracania:' = @{ pl = 'Utworzone punkty przywracania:'; en = 'Restore points created:' }
    'cleanmgr i czyszczenie systemowe nie udostepniaja dokladnych statystyk plikow.' = @{ pl = 'cleanmgr i czyszczenie systemowe nie udostępniają dokładnych statystyk plików.'; en = 'cleanmgr and system cleanup do not provide exact file statistics.' }
    'Nie usunieto plikow do zliczenia lub system nie udostepnia statystyk.' = @{ pl = 'Nie usunięto plików do zliczenia lub system nie udostępnia statystyk.'; en = 'No countable files were removed, or the system did not provide statistics.' }
    'Czy zapisac szczegolowy log czyszczenia? [T/N, Enter = N]' = @{ pl = 'Czy zapisać szczegółowy log czyszczenia? [T/N, Enter = N]'; en = 'Save a detailed cleanup log? [Y/N, Enter = N]' }
    'Log zapisano:' = @{ pl = 'Log zapisano:'; en = 'Log saved to:' }
    'Nie udalo sie zapisac logu:' = @{ pl = 'Nie udało się zapisać logu:'; en = 'Could not save the log:' }
    'Nie mozna zapisac logu; brakuje katalogu profilu uzytkownika.' = @{ pl = 'Nie można zapisać logu; brakuje katalogu profilu użytkownika.'; en = 'Cannot save the log; the user profile directory is unavailable.' }
    'Wybrano czyszczenie bezpieczne' = @{ pl = 'Wybrano czyszczenie bezpieczne'; en = 'Safe cleanup selected' }
    'Wybrano Oczyszczanie dysku Windows' = @{ pl = 'Wybrano Oczyszczanie dysku Windows'; en = 'Windows Disk Cleanup selected' }
    'Wybrano wyszukiwanie zrzutow DMP' = @{ pl = 'Wybrano wyszukiwanie zrzutów DMP'; en = 'DMP dump cleanup selected' }
    'Wybrano zarzadzanie punktami przywracania' = @{ pl = 'Wybrano zarządzanie punktami przywracania'; en = 'Restore point management selected' }
    'Czyszczenie archiwalnych logow diagnostycznych' = @{ pl = 'Czyszczenie archiwalnych logów diagnostycznych'; en = 'Archived diagnostic log cleanup' }
    'Wybrano DISM: analiza, czyszczenie i ResetBase' = @{ pl = 'Wybrano DISM: analiza, czyszczenie i ResetBase'; en = 'DISM analysis, cleanup, and ResetBase selected' }
    'Pobrane/Downloads pozostaly poza zakresem skryptu.' = @{ pl = 'Pobrane/Downloads pozostają poza zakresem skryptu.'; en = 'Downloads remains outside this script''s cleanup scope.' }
    'Nacisnij Enter, aby zamknac' = @{ pl = 'Naciśnij Enter, aby zamknąć'; en = 'Press Enter to close' }
    'Nacisnij Enter, aby kontynuowac' = @{ pl = 'Naciśnij Enter, aby kontynuować'; en = 'Press Enter to continue' }
    'Opcja' = @{ pl = 'Opcja'; en = 'Option' }
    'Tymczasowe pliki' = @{ pl = 'Tymczasowe pliki'; en = 'Temporary files' }
    'Pamiec' = @{ pl = 'Pamięć'; en = 'Storage' }
    'Pobrane' = @{ pl = 'Pobrane'; en = 'Downloads' }
    '[T/N]' = @{ pl = '[T/N]'; en = '[Y/N]' }
    'Aby potwierdzic, wpisz DZIENNIKI' = @{ pl = 'Aby potwierdzić, wpisz DZIENNIKI'; en = 'Type EVENTLOGS to confirm' }
    'BLAD' = @{ pl = 'BŁĄD'; en = 'ERROR' }
    'Nieprawidlowy wybor.' = @{ pl = 'Nieprawidłowy wybór.'; en = 'Invalid selection.' }
    'Uruchomienie uprawnien administratora nie powiodlo sie.' = @{ pl = 'Uruchomienie uprawnień administratora nie powiodło się.'; en = 'Could not start the elevated process.' }
    'True-color console mode is unavailable.' = @{ pl = 'Tryb konsoli z kolorami RGB jest niedostępny.'; en = 'True-color console mode is unavailable.' }
    'The console color palette could not be adjusted.' = @{ pl = 'Nie można zmienić palety kolorów konsoli.'; en = 'The console color palette could not be adjusted.' }
    'The host rejected the requested console colors.' = @{ pl = 'Host konsoli nie przyjął wybranych kolorów.'; en = 'The host rejected the requested console colors.' }
    'Wykonane operacje:' = @{ pl = 'Wykonane operacje:'; en = 'Operations run:' }
    'Pobrane pliki Windows Update' = @{ pl = 'Pobrane pliki Windows Update'; en = 'Downloaded Windows Update files' }
    'Tworzenie punktu przywracania' = @{ pl = 'Tworzenie punktu przywracania'; en = 'Creating a restore point' }
    'Usunieto punkt' = @{ pl = 'Usunięto punkt'; en = 'Removed restore point' }
    'Wpisz numery do usuniecia' = @{ pl = 'Wpisz numery do usunięcia'; en = 'Enter the numbers to delete' }
    'ALL usuwa wszystkie' = @{ pl = 'ALL usuwa wszystkie'; en = 'ALL deletes all' }
    'Opcja 7 uruchamia wszystkie wybrane operacje bez dodatkowych potwierdzen.' = @{ pl = 'Opcja 7 uruchamia wszystkie wybrane operacje bez dodatkowych potwierdzeń.'; en = 'Option 7 runs all selected operations without additional confirmation.' }
    'czyszczenie systemowe nie udostepnia dokladnych statystyk plikow.' = @{ pl = 'czyszczenie systemowe nie udostępnia dokładnych statystyk plików.'; en = 'system cleanup does not provide exact file statistics.' }
    'Could not load SrClient.dll.' = @{ pl = 'Nie można załadować biblioteki SrClient.dll.'; en = 'Could not load SrClient.dll.' }
    'SRRemoveRestorePoint was not found.' = @{ pl = 'Nie znaleziono funkcji SRRemoveRestorePoint.'; en = 'SRRemoveRestorePoint was not found.' }
}

function Convert-LocalizedText {
    param([AllowNull()][object]$Text)
    if ($null -eq $Text) { return $null }
    $result = [string]$Text
    $keys = @($script:TextMap.Keys | Sort-Object { $_.Length } -Descending)
    foreach ($source in $keys) {
        if ($result.Contains($source)) {
            $result = $result.Replace($source, $script:TextMap[$source][$script:Language])
        }
    }
    return $result
}

function Get-TerminalWidth {
    try {
        if ([Console]::WindowWidth -gt 0) {
            return [Console]::WindowWidth
        }
    }
    catch { }
    try {
        if ($Host.UI.RawUI.WindowSize.Width -gt 0) {
            return $Host.UI.RawUI.WindowSize.Width
        }
    }
    catch { }
    return 76
}

function Format-TerminalText {
    param([AllowNull()][string]$Text)
    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

    $lineWidth = [math]::Max(1, (Get-TerminalWidth) - 1)
    $formattedLines = [Collections.Generic.List[string]]::new()
    foreach ($line in [regex]::Split($Text, '\r\n|\n|\r')) {
        if ($line.Length -le $lineWidth) {
            $formattedLines.Add($line)
            continue
        }

        $indent = [regex]::Match($line, '^\s*').Value
        $words = $line.Substring($indent.Length) -split '\s+'
        $currentLine = $indent
        foreach ($word in $words) {
            if ([string]::IsNullOrEmpty($word)) {
                continue
            }

            $separator = if ($currentLine.Length -gt $indent.Length) { ' ' } else { '' }
            if ($currentLine.Length + $separator.Length + $word.Length -gt $lineWidth -and
                $currentLine.Length -gt $indent.Length) {
                $formattedLines.Add($currentLine)
                $currentLine = $indent + $word
            }
            else {
                $currentLine += $separator + $word
            }
        }
        $formattedLines.Add($currentLine)
    }

    return $formattedLines -join [Environment]::NewLine
}

function Write-Host {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
        [AllowNull()][object[]]$Object,
        [ConsoleColor]$ForegroundColor,
        [ConsoleColor]$BackgroundColor,
        [switch]$NoNewline
    )
    $text = if ($Object) { $Object -join ' ' } else { '' }
    if ($GuiPipeName -and $script:GuiWriter) {
        $colorName = if ($PSBoundParameters.ContainsKey('ForegroundColor')) { [string]$ForegroundColor } else { 'Gray' }
        Send-GuiMessage -Type 'output' -Text (Convert-LocalizedText $text) -Foreground $colorName
        return
    }

    if ($script:UseTrueColorConsole -and -not [Console]::IsOutputRedirected) {
        $colorName = if ($PSBoundParameters.ContainsKey('ForegroundColor')) { [string]$ForegroundColor } else { 'Gray' }
        $foreground = switch ($colorName) {
            'Black'       { '17;24;39' }
            'DarkBlue'    { '96;165;250' }
            'DarkGreen'   { '34;197;94' }
            'DarkCyan'    { '34;211;238' }
            'DarkRed'     { '239;68;68' }
            'DarkMagenta' { '217;70;239' }
            'DarkYellow'  { '250;204;21' }
            'Gray'        { '203;213;225' }
            'DarkGray'    { '148;163;184' }
            'Blue'        { '96;165;250' }
            'Green'       { '74;222;128' }
            'Cyan'        { '103;232;249' }
            'Red'         { '248;113;113' }
            'Magenta'     { '232;121;249' }
            'Yellow'      { '253;224;71' }
            'White'       { '248;250;252' }
            default       { '203;213;225' }
        }
        $background = $script:ConsoleBackgroundRgb -join ';'
        $sequence = "$([char]27)[38;2;${foreground}m$([char]27)[48;2;${background}m"
        $reset = "$([char]27)[0m$([char]27)[48;2;${background}m"
        $displayText = Format-TerminalText (Convert-LocalizedText $text)
        [Console]::Write($sequence + $displayText + $reset)
        if (-not $NoNewline) {
            [Console]::WriteLine()
        }
        return
    }

    $nativeParameters = @{
        Object = (Format-TerminalText (Convert-LocalizedText $text))
        NoNewline = $NoNewline
    }
    if (-not [Console]::IsOutputRedirected) {
        $nativeParameters.BackgroundColor = $script:ConsoleBackgroundColor
        if ($PSBoundParameters.ContainsKey('ForegroundColor')) { $nativeParameters.ForegroundColor = $ForegroundColor }
    }
    Microsoft.PowerShell.Utility\Write-Host @nativeParameters
}

function Read-Host {
    [CmdletBinding()]
    param([string]$Prompt)
    $localizedPrompt = Convert-LocalizedText $Prompt
    if ($GuiPipeName -and $script:GuiWriter) {
        Send-GuiMessage -Type 'input' -Text $localizedPrompt
        $response = Read-GuiResponse
        return [string]$response.value
    }

    if ($script:UseTrueColorConsole -and -not [Console]::IsOutputRedirected) {
        $background = $script:ConsoleBackgroundRgb -join ';'
        [Console]::Write("$([char]27)[38;2;203;213;225m$([char]27)[48;2;${background}m")
        $answer = Microsoft.PowerShell.Utility\Read-Host -Prompt $localizedPrompt
        [Console]::Write("$([char]27)[0m$([char]27)[48;2;${background}m")
        return $answer
    }
    Microsoft.PowerShell.Utility\Read-Host -Prompt $localizedPrompt
}

function Read-GuiResponse {
    $responseLine = $script:GuiReader.ReadLine()
    if ($null -eq $responseLine) {
        throw 'The GUI disconnected while the cleanup script was waiting for input.'
    }
    return $responseLine | ConvertFrom-Json -ErrorAction Stop
}

function Confirm-UserAction {
    param([Parameter(Mandatory)][string]$Prompt)
    $localizedPrompt = Convert-LocalizedText $Prompt
    if ($GuiPipeName -and $script:GuiWriter) {
        Send-GuiMessage -Type 'confirm' -Text $localizedPrompt
        $response = Read-GuiResponse
        return [bool]$response.value
    }

    $answer = Microsoft.PowerShell.Utility\Read-Host -Prompt "$localizedPrompt [T/N]"
    return $answer -match '^(?i:t|y|tak|yes)$'
}

function Connect-GuiChannel {
    if (-not $GuiPipeName) {
        return
    }

    $script:GuiPipe = [IO.Pipes.NamedPipeClientStream]::new(
        '.',
        $GuiPipeName,
        [IO.Pipes.PipeDirection]::InOut,
        [IO.Pipes.PipeOptions]::None
    )
    $script:GuiPipe.Connect(30000)
    $script:GuiReader = [IO.StreamReader]::new($script:GuiPipe, [Text.Encoding]::UTF8, $false, 4096, $true)
    $script:GuiWriter = [IO.StreamWriter]::new($script:GuiPipe, [Text.UTF8Encoding]::new($false), 4096, $true)
    $script:GuiWriter.AutoFlush = $true
}

function Send-GuiMessage {
    param(
        [Parameter(Mandatory)][string]$Type,
        [AllowEmptyString()][string]$Text = '',
        [string]$Foreground = 'Gray',
        [AllowNull()][object]$Data = $null
    )
    if (-not $script:GuiWriter) {
        throw 'The GUI communication channel is not connected.'
    }

    $message = @{ type = $Type; text = $Text; foreground = $Foreground }
    if ($null -ne $Data) {
        $message.data = $Data
    }
    $message = $message | ConvertTo-Json -Compress -Depth 5
    try {
        $script:GuiWriter.WriteLine($message)
    }
    catch {
        if (-not $script:GuiDisconnected) {
            $script:GuiDisconnected = $true
            $script:GuiWriter = $null
            Add-RunLog "The GUI disconnected; stopping the cleanup run: $($_.Exception.Message)"
            [void](Save-CleanupSessionLog)
        }
        exit 1
    }
}

function Send-CleanupProgress {
    param(
        [Parameter(Mandatory)][ValidateSet('scan', 'delete', 'analyze', 'external', 'complete')][string]$Phase,
        [AllowEmptyString()][string]$CurrentPath = '',
        [int]$Completed = -1,
        [int]$Total = -1,
        [double]$RemainingSeconds = -1
    )
    if (-not $GuiPipeName) {
        return
    }

    $percent = $null
    if ($Total -gt 0 -and $Completed -ge 0) {
        $percent = [math]::Min(100, [math]::Max(0, [math]::Round(($Completed / $Total) * 100, 1)))
    }
    $remaining = if ($RemainingSeconds -ge 0) { [math]::Round($RemainingSeconds, 1) } else { $null }
    Send-GuiMessage -Type 'progress' -Data @{
        phase = $Phase
        currentPath = $CurrentPath
        completed = $Completed
        total = $Total
        percent = $percent
        remainingSeconds = $remaining
    }
}

function Write-Rule {
    if ($GuiPipeName) {
        return
    }
    $width = [math]::Max(1, (Get-TerminalWidth) - 1)
    Write-Host ('_' * $width) -ForegroundColor Cyan
}

function Write-Header {
    if (-not $GuiPipeName) {
        Clear-ConsoleScreen
    }
    Write-Host ''
    Write-Host '  WINDOWS 11  |  PORZADKI SYSTEMOWE' -ForegroundColor White
    Write-Host '  Bezpieczne czyszczenie plikow tymczasowych i wybranych pamieci podrecznych' -ForegroundColor Gray
    Write-Rule
    if ($script:ConsoleThemeWarning) {
        Write-Host 'Nie mozna w pelni ustawic kolorow terminala; zastosowano dostepny tryb zgodnosci.' -ForegroundColor DarkYellow
        $script:ConsoleThemeWarning = $null
    }
    Write-Host ''
}

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)
    if ($GuiPipeName) {
        Write-Host $Title -ForegroundColor Cyan
        return
    }
    Write-Host ''
    Write-Rule
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Rule
}

function Add-RunLog {
    param([Parameter(Mandatory)][string]$Message)
    $script:RunLog.Add(('[{0:yyyy-MM-dd HH:mm:ss}] {1}' -f (Get-Date), $Message))
}

function Add-SkippedDetail {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Reason
    )
    $script:SkippedDetails.Add(('{0} | {1}' -f $Path, $Reason))
}

function Get-SystemDriveFreeBytes {
    try {
        $drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'" -ErrorAction Stop
        if ($null -eq $drive.FreeSpace) { return $null }
        return [long]$drive.FreeSpace
    }
    catch {
        Add-RunLog "Could not measure system-drive free space: $($_.Exception.Message)"
        return $null
    }
}

function Get-ShadowStorageUsedBytes {
    try {
        $storage = @(Get-CimInstance -Namespace 'root/cimv2' -ClassName Win32_ShadowStorage -ErrorAction Stop)
        if ($storage.Count -eq 0 -or @($storage | Where-Object { $null -eq $_.UsedSpace }).Count -gt 0) {
            return $null
        }
        return [long](($storage | Measure-Object -Property UsedSpace -Sum).Sum)
    }
    catch {
        Add-RunLog "Could not measure VSS shadow storage: $($_.Exception.Message)"
        return $null
    }
}

function Publish-GuiCleanupStatistics {
    if (-not $script:GuiPipeName -or -not $script:GuiWriter -or -not $script:OperationStats) {
        return
    }

    $currentOperation = @($script:OperationStats | Where-Object { $_.id -eq $script:CurrentOperationId }) | Select-Object -First 1
    if ($currentOperation) {
        $currentOperation.bytes = [long]($script:FreedBytes - $script:CurrentOperationBytesBase)
        $currentOperation.files = [int]($script:RemovedItems - $script:CurrentOperationFilesBase)
        $currentOperation.restorePoints = [int]($script:RemovedRestorePoints - $script:CurrentOperationRestorePointsBase)
    }
    $knownBytes = [long](($script:OperationStats | Where-Object { $_.bytesKnown } |
        Measure-Object -Property bytes -Sum).Sum)

    Send-GuiMessage -Type 'summary' -Data @{
        operations = @($script:OperationStats.ToArray())
        totalBytes = $knownBytes
        removedFiles = [int]$script:RemovedItems
        skippedFiles = [int]$script:SkippedFiles
        skippedDirectories = [int]$script:SkippedDirectories
        running = [bool]$script:CleanupRunInProgress
    }
}

function Save-CleanupSessionLog {
    if ($null -eq $script:RunStarted) {
        $script:RunStarted = Get-Date
    }

    $logDirectory = Join-Path $env:LOCALAPPDATA 'Windows11JunkFileRemoval\Logs'
    if ([string]::IsNullOrWhiteSpace($script:SessionLogPath)) {
        $script:SessionLogPath = Join-Path $logDirectory ('cleanup-{0:yyyyMMdd-HHmmss-fff}-{1}.log' -f (Get-Date), ([guid]::NewGuid().ToString('N').Substring(0, 6)))
    }
    $logContent = @(
        'Windows 11 Junk File Removal v2.0'
        "Started: $($script:RunStarted.ToString('yyyy-MM-dd HH:mm:ss'))"
        "Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "Language: $script:Language"
        "Files removed: $($script:RemovedItems)"
        "Estimated bytes reclaimed: $($script:FreedBytes)"
        "Files not removed: $($script:SkippedFiles)"
        "Directories not removed: $($script:SkippedDirectories)"
        "Full session log: $($script:SessionLogPath)"
        ''
        '=== Full activity and diagnostic log ==='
    ) + $script:RunLog.ToArray() + @(
        ''
        '=== Files and directories not removed (full paths and reasons) ==='
    ) + $script:SkippedDetails.ToArray()

    try {
        New-Item -Path $logDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Set-Content -LiteralPath $script:SessionLogPath -Value $logContent -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        $failedPath = $script:SessionLogPath
        $script:SessionLogPath = $null
        Write-Host "Nie udalo sie zapisac pelnego pliku logu sesji ($failedPath): $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    if ($GuiPipeName -and $script:GuiWriter) {
        try {
            Send-GuiMessage -Type 'logfile' -Text ($logContent -join [Environment]::NewLine) -Data @{ path = $script:SessionLogPath }
        }
        catch {
            Add-RunLog "Could not send session log to the GUI: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host ("  " + (Convert-LocalizedText 'Plik pelnego logu sesji:')) -ForegroundColor Gray
        Write-Host "  $($script:SessionLogPath)" -ForegroundColor Gray
    }
    return $true
}

function Format-ByteCount {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return [string]::Format($script:DisplayCulture, '{0:N2} GB', ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return [string]::Format($script:DisplayCulture, '{0:N2} MB', ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return [string]::Format($script:DisplayCulture, '{0:N2} KB', ($Bytes / 1KB)) }
    return [string]::Format($script:DisplayCulture, '{0:N0} B', $Bytes)
}

function Show-CleanupSummary {
    param(
        [Parameter(Mandatory)][string[]]$OperationNames,
        [Parameter(Mandatory)][string[]]$Choices
    )

    $tracksFileStatistics = ($Choices -contains '1') -or ($Choices -contains '3') -or ($Choices -contains '5')
    $hasMeasuredSpace = @($script:OperationStats | Where-Object { $_.bytesKnown }).Count -gt 0
    if (-not $GuiPipeName) {
        Write-Header
    }
    Write-Section 'Podsumowanie czyszczenia'
    Write-Host '  Wykonane operacje:' -ForegroundColor Cyan
    foreach ($operationName in $OperationNames) {
        Write-Host "    • $operationName" -ForegroundColor White
    }
    Write-Host ''
    if (($Choices -contains '2') -or ($Choices -contains '6')) {
        Write-Host '  cleanmgr i czyszczenie systemowe nie udostepniaja dokladnych statystyk plikow.' -ForegroundColor DarkGray
    }
    if ($Choices -contains '5') {
        Write-Host "  Usuniete archiwalne logi diagnostyczne: $($script:RemovedDiagnosticLogs)" -ForegroundColor Gray
    }
    if ($Choices -contains '4') {
        Write-Host "  Usuniete punkty przywracania: $($script:RemovedRestorePoints)" -ForegroundColor Gray
        Write-Host "  Utworzone punkty przywracania: $($script:CreatedRestorePoints)" -ForegroundColor Gray
    }
    if ($tracksFileStatistics) {
        $skippedSummary = Convert-LocalizedText 'Nieusuniete pliki i katalogi: {0} plikow, {1} katalogow. Szczegoly zapisano w pliku logu.'
        Write-Host ("  " + ($skippedSummary -f $script:SkippedFiles, $script:SkippedDirectories)) -ForegroundColor Gray
        Write-Host "  Usuniete pliki: $($script:RemovedItems)" -ForegroundColor Green
    }
    if ($hasMeasuredSpace) {
        Write-Host "  $(Convert-LocalizedText 'Odzyskane miejsce z mierzonych operacji (szacunek):') $(Format-ByteCount $script:FreedBytes)" -ForegroundColor Green
    }
    else {
        Write-Host "  $(Convert-LocalizedText 'Odzyskane miejsce: brak danych z wybranych operacji.')" -ForegroundColor Yellow
    }
    Add-RunLog '--- Cleanup summary ---'
    if ($tracksFileStatistics) {
        Add-RunLog "Files removed by tracked operations: $($script:RemovedItems)"
        Add-RunLog "Files not removed: $($script:SkippedFiles)"
        Add-RunLog "Directories not removed: $($script:SkippedDirectories)"
    }
    if ($hasMeasuredSpace) {
        Add-RunLog "Estimated bytes reclaimed by measured operations: $($script:FreedBytes)"
    }
    else {
        Add-RunLog 'Reclaimed space: no data reported by the selected operations.'
    }
    if ($Choices -contains '5') {
        Add-RunLog "Archived diagnostic logs removed: $($script:RemovedDiagnosticLogs)"
    }
    if ($Choices -contains '4') {
        Add-RunLog "Restore points removed: $($script:RemovedRestorePoints)"
        Add-RunLog "Restore points created: $($script:CreatedRestorePoints)"
    }
    foreach ($operationName in $OperationNames) { Add-RunLog "Operation: $operationName" }

    if ($script:SkippedDetails.Count -gt 0) {
        Add-RunLog '--- Items not removed (full paths and reasons) ---'
        foreach ($detail in $script:SkippedDetails) {
            Add-RunLog $detail
        }
    }

    [void](Save-CleanupSessionLog)
}

function Should-RunSelectedAction {
    param([Parameter(Mandatory)][string]$Prompt)
    Add-RunLog "Automatically running selected action: $Prompt"
    return $true
}

function Complete-Operation {
    Write-Rule
    if (-not $GuiPipeName) {
        Start-Sleep -Seconds 1
    }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Remove-DirectoryContents {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return
    }

    $enumerationErrors = @()
    $items = [Collections.Generic.List[IO.FileSystemInfo]]::new()
    $scanHeartbeat = [Diagnostics.Stopwatch]::StartNew()
    $scannedItems = 0
    Send-CleanupProgress -Phase 'scan' -CurrentPath $Path
    foreach ($item in Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue -ErrorVariable +enumerationErrors) {
        $items.Add($item)
        $scannedItems++
        if ($scanHeartbeat.ElapsedMilliseconds -ge 500) {
            Send-CleanupProgress -Phase 'scan' -CurrentPath $item.FullName -Completed $scannedItems
            $scanHeartbeat.Restart()
        }
    }
    $items = @($items.ToArray())
    # Runtime files extracted by the single-file GUI live in %TEMP%\.net; deleting them crashes the running app.
    $protectedRoots = @(
        (Join-Path $Path '.net'),
        $env:DOTNET_BUNDLE_EXTRACT_BASE_DIR
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.TrimEnd('\') }
    if ($protectedRoots.Count -gt 0) {
        $items = @($items | Where-Object {
            $itemPath = $_.FullName
            -not ($protectedRoots | Where-Object {
                $itemPath.Equals($_, [StringComparison]::OrdinalIgnoreCase) -or
                $itemPath.StartsWith($_ + '\', [StringComparison]::OrdinalIgnoreCase)
            })
        })
    }
    if ($items.Count -eq 0 -and $enumerationErrors.Count -eq 0) {
        Write-Host "  - $Label : brak plikow" -ForegroundColor DarkGray
        Add-RunLog "No files found: $Path"
        Complete-Operation
        return
    }

    $removed = 0
    $skipped = 0
    $bytes = 0L
    $accessErrors = 0
    $lockedErrors = 0
    foreach ($item in @($items | Where-Object {
        $_.Attributes -band [IO.FileAttributes]::ReparsePoint
    })) {
        $skipped++
        if ($item.PSIsContainer) { $script:SkippedDirectories++ } else { $script:SkippedFiles++ }
        Add-SkippedDetail -Path $item.FullName -Reason 'Reparse point was not followed or removed.'
        Add-RunLog "Skipped reparse point: $($item.FullName)"
    }

    $files = @($items | Where-Object {
        -not $_.PSIsContainer -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
    })
    $directories = @($items | Where-Object {
        $_.PSIsContainer -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
    } | Sort-Object { $_.FullName.Length } -Descending)
    $totalWorkItems = $files.Count + $directories.Count
    $processedWorkItems = 0
    $progressHeartbeat = [Diagnostics.Stopwatch]::StartNew()
    $workStopwatch = [Diagnostics.Stopwatch]::StartNew()
    if ($totalWorkItems -gt 0) {
        Send-CleanupProgress -Phase 'delete' -CurrentPath $Path -Completed 0 -Total $totalWorkItems
    }

    foreach ($item in $files) {
        try {
            Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop
            $removed++
            $bytes += [long]$item.Length
            Add-RunLog "Removed file: $($item.FullName) ($(Format-ByteCount ([long]$item.Length)))"
        }
        catch {
            $skipped++
            $script:SkippedFiles++
            Add-SkippedDetail -Path $item.FullName -Reason $_.Exception.Message
            Add-RunLog "Could not remove file: $($item.FullName) | $($_.Exception.Message)"
            if ($_.Exception -is [UnauthorizedAccessException]) {
                $accessErrors++
            }
            elseif ($_.Exception -is [IO.IOException]) {
                $lockedErrors++
            }
        }
        $processedWorkItems++
        if ($progressHeartbeat.ElapsedMilliseconds -ge 400 -or $processedWorkItems -eq $totalWorkItems) {
            $remaining = -1
            if ($processedWorkItems -ge 2 -and $processedWorkItems -lt $totalWorkItems) {
                $remaining = ($workStopwatch.Elapsed.TotalSeconds / $processedWorkItems) * ($totalWorkItems - $processedWorkItems)
            }
            Send-CleanupProgress -Phase 'delete' -CurrentPath $item.FullName -Completed $processedWorkItems -Total $totalWorkItems -RemainingSeconds $remaining
            $progressHeartbeat.Restart()
        }
    }

    foreach ($directory in $directories) {
        try {
            Remove-Item -LiteralPath $directory.FullName -Force -ErrorAction Stop
            Add-RunLog "Removed directory: $($directory.FullName)"
        }
        catch {
            $skipped++
            $script:SkippedDirectories++
            Add-SkippedDetail -Path $directory.FullName -Reason $_.Exception.Message
            Add-RunLog "Could not remove directory: $($directory.FullName) | $($_.Exception.Message)"
            if ($_.Exception -is [UnauthorizedAccessException]) {
                $accessErrors++
            }
            elseif ($_.Exception -is [IO.IOException]) {
                $lockedErrors++
            }
        }
        $processedWorkItems++
        if ($progressHeartbeat.ElapsedMilliseconds -ge 400 -or $processedWorkItems -eq $totalWorkItems) {
            $remaining = -1
            if ($processedWorkItems -ge 2 -and $processedWorkItems -lt $totalWorkItems) {
                $remaining = ($workStopwatch.Elapsed.TotalSeconds / $processedWorkItems) * ($totalWorkItems - $processedWorkItems)
            }
            Send-CleanupProgress -Phase 'delete' -CurrentPath $directory.FullName -Completed $processedWorkItems -Total $totalWorkItems -RemainingSeconds $remaining
            $progressHeartbeat.Restart()
        }
    }
    $skipped += $enumerationErrors.Count
    $script:SkippedDirectories += $enumerationErrors.Count
    foreach ($errorRecord in $enumerationErrors) {
        $errorPath = if ($errorRecord.TargetObject) { [string]$errorRecord.TargetObject } else { $Path }
        Add-SkippedDetail -Path $errorPath -Reason $errorRecord.Exception.Message
        Add-RunLog "Could not enumerate directory: $errorPath | $($errorRecord.Exception.Message)"
    }
    $script:RemovedItems += $removed
    $script:SkippedItems += $skipped
    $script:FreedBytes += $bytes
    Send-CleanupProgress -Phase 'complete' -CurrentPath $Path -Completed $totalWorkItems -Total $totalWorkItems
    $size = Format-ByteCount $bytes
    Write-Host "  + $Label : Usunieto $removed elementow, ok. $size" -ForegroundColor Green
    if ($skipped -gt 0) { Add-RunLog "Skipped $skipped item(s) under $Path (access: $accessErrors; in use: $lockedErrors)." }
    Add-RunLog "Cleanup directory summary: $Path; removed $removed file(s), $(Format-ByteCount $bytes); skipped $skipped."
    Complete-Operation
    Publish-GuiCleanupStatistics
}

function Get-BrowserCacheDirectories {
    $paths = [Collections.Generic.List[string]]::new()

    foreach ($browserRoot in @(
        (Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'),
        (Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data'),
        (Join-Path $env:LOCALAPPDATA 'Vivaldi\User Data')
    )) {
        if (Test-Path -LiteralPath $browserRoot -PathType Container) {
            foreach ($profile in Get-ChildItem -LiteralPath $browserRoot -Directory -Force -ErrorAction SilentlyContinue) {
                foreach ($cacheName in @('Cache', 'Code Cache', 'GPUCache', 'Service Worker\CacheStorage')) {
                    $paths.Add((Join-Path $profile.FullName $cacheName))
                }
            }
        }
    }

    foreach ($profileRoot in @(
        (Join-Path $env:LOCALAPPDATA 'Mozilla\Firefox\Profiles'),
        (Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles')
    )) {
        if (Test-Path -LiteralPath $profileRoot -PathType Container) {
            foreach ($profile in Get-ChildItem -LiteralPath $profileRoot -Directory -Force -ErrorAction SilentlyContinue) {
                $paths.Add((Join-Path $profile.FullName 'cache2'))
            }
        }
    }

    foreach ($discordRoot in @(
        (Join-Path $env:APPDATA 'discord'),
        (Join-Path $env:LOCALAPPDATA 'Discord')
    )) {
        foreach ($cacheName in @('Cache', 'Code Cache', 'GPUCache')) {
            $paths.Add((Join-Path $discordRoot $cacheName))
        }
    }

    foreach ($cacheRoot in @(
        (Join-Path $env:APPDATA 'Microsoft\Teams\Cache'),
        (Join-Path $env:APPDATA 'Microsoft\Teams\Code Cache'),
        (Join-Path $env:APPDATA 'Microsoft\Teams\GPUCache'),
        (Join-Path $env:APPDATA 'Slack\Cache'),
        (Join-Path $env:APPDATA 'Slack\Code Cache'),
        (Join-Path $env:APPDATA 'Slack\GPUCache'),
        (Join-Path $env:APPDATA 'Code\Cache'),
        (Join-Path $env:APPDATA 'Code\CachedData'),
        (Join-Path $env:APPDATA 'Code\Code Cache'),
        (Join-Path $env:APPDATA 'Code\GPUCache'),
        (Join-Path $env:LOCALAPPDATA 'NVIDIA\DXCache'),
        (Join-Path $env:LOCALAPPDATA 'NVIDIA\GLCache'),
        (Join-Path $env:LOCALAPPDATA 'AMD\DxCache'),
        (Join-Path $env:LOCALAPPDATA 'Intel\ShaderCache'),
        (Join-Path $env:ProgramData 'NVIDIA Corporation\NV_Cache'),
        (Join-Path $env:APPDATA 'Opera Software\Opera Stable\Cache'),
        (Join-Path $env:APPDATA 'Opera Software\Opera Stable\GPUCache'),
        (Join-Path $env:APPDATA 'Opera Software\Opera Stable\Code Cache'),
        (Join-Path $env:APPDATA 'Vivaldi\User Data\Default\Cache'),
        (Join-Path $env:APPDATA 'Vivaldi\User Data\Default\Code Cache'),
        (Join-Path $env:LOCALAPPDATA 'Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\EBWebView\Default\Cache'),
        (Join-Path $env:LOCALAPPDATA 'Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\EBWebView\Default\Code Cache'),
        (Join-Path $env:LOCALAPPDATA 'Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\EBWebView\Default\GPUCache'),
        (Join-Path $env:ProgramFiles 'Steam\appcache\httpcache'),
        (Join-Path ${env:ProgramFiles(x86)} 'Steam\appcache\httpcache')
    )) {
        $paths.Add($cacheRoot)
    }

    return @($paths.ToArray() | Sort-Object -Unique)
}

function Get-DirectoryByteSize {
    param([Parameter(Mandatory)][string]$Path)
    $enumerationErrors = @()
    $bytes = 0L
    $scannedFiles = 0
    $heartbeat = [Diagnostics.Stopwatch]::StartNew()
    Send-CleanupProgress -Phase 'scan' -CurrentPath $Path
    foreach ($file in Get-ChildItem -LiteralPath $Path -File -Force -Recurse -ErrorAction SilentlyContinue -ErrorVariable +enumerationErrors) {
        $bytes += [long]$file.Length
        $scannedFiles++
        if ($heartbeat.ElapsedMilliseconds -ge 500) {
            Send-CleanupProgress -Phase 'scan' -CurrentPath $file.FullName -Completed $scannedFiles
            $heartbeat.Restart()
        }
    }
    return [pscustomobject]@{ Bytes = $bytes; Incomplete = ($enumerationErrors.Count -gt 0) }
}

function Close-SelectedApplications {
    $processNames = @(
        'chrome', 'msedge', 'firefox', 'brave', 'opera', 'opera_gx', 'vivaldi',
        'discord', 'Teams', 'ms-teams', 'slack', 'Code', 'Spotify', 'steam'
    )
    $windows = @(Get-Process -Name $processNames -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero })
    if ($windows.Count -eq 0) {
        Add-RunLog 'No supported browser or application windows were running.'
        return
    }

    $requested = 0
    foreach ($process in $windows) {
        try {
            if ($process.CloseMainWindow()) {
                $requested++
            }
        }
        catch {
            # Process may exit between discovery and the close request.
        }
    }
    Start-Sleep -Seconds 3
    $stillRunning = @($windows | Where-Object {
        try {
            $_.Refresh()
            -not $_.HasExited
        }
        catch {
            $false
        }
    })
    Add-RunLog "Graceful close requested for $requested window(s); $($stillRunning.Count) process window(s) remained. No process was force-terminated."
    if ($stillRunning.Count -gt 0) {
        Write-Host "  Pozostawiono uruchomione okna aplikacji: $($stillRunning.Count). Nie wymuszano zamkniecia." -ForegroundColor DarkYellow
    }
}

function Invoke-SafeCleanup {
    Write-Section 'Czyszczenie plikow tymczasowych i cache'
    Add-RunLog 'Safe cleanup started.'
    if (Confirm-UserAction 'Zamknac wykryte przegladarki i aplikacje? Niezapisana praca moze zostac utracona. Zostana zamkniete tylko okna, bez wymuszania zakonczenia.') {
        Close-SelectedApplications
    }
    else {
        Add-RunLog 'Application windows were left open by user choice.'
    }

    $tempPaths = @(
        [pscustomobject]@{ Path = (Join-Path $env:windir 'Temp'); Label = 'Tymczasowe pliki Windows' },
        [pscustomobject]@{ Path = (Join-Path $env:windir 'TMP'); Label = 'Tymczasowe pliki Windows TMP' },
        [pscustomobject]@{ Path = $env:TEMP; Label = 'Tymczasowe pliki biezacego uzytkownika' },
        [pscustomobject]@{ Path = $env:TMP; Label = 'Tymczasowe pliki TMP uzytkownika' },
        [pscustomobject]@{ Path = (Join-Path $env:LOCALAPPDATA 'Temp'); Label = 'Lokalny katalog Temp uzytkownika' },
        [pscustomobject]@{ Path = (Join-Path $env:LOCALAPPDATA 'D3DSCache'); Label = 'Pamiec podreczna shaderow DirectX' }
    )
    $seenTempPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $tempPaths) {
        if ([string]::IsNullOrWhiteSpace($entry.Path) -or -not $seenTempPaths.Add($entry.Path)) {
            continue
        }
        Remove-DirectoryContents -Path $entry.Path -Label $entry.Label
    }

    Remove-DirectoryContents -Path (Join-Path $env:ProgramData 'Microsoft\Windows\WER\ReportArchive') -Label 'Archiwalne raporty bledow Windows'
    Remove-DirectoryContents -Path (Join-Path $env:ProgramData 'Microsoft\Windows\WER\ReportQueue') -Label 'Oczekujace raporty bledow Windows'

    $cachePaths = Get-BrowserCacheDirectories
    $smallCacheCount = 0
    foreach ($path in $cachePaths) {
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            continue
        }
        $size = Get-DirectoryByteSize -Path $path
        if ($size.Incomplete) {
            Add-RunLog "Cache size was incomplete and was left unchanged: $path"
            $script:SkippedDirectories++
            $script:SkippedItems++
            Add-SkippedDetail -Path $path -Reason 'Cache size could not be measured completely; directory was left unchanged.'
            continue
        }
        if ($size.Bytes -lt 100MB) {
            $smallCacheCount++
            continue
        }
        Write-Host "  Cache $([IO.Path]::GetFileName($path)): $(Format-ByteCount $size.Bytes)" -ForegroundColor Gray
        Remove-DirectoryContents -Path $path -Label "Cache aplikacji: $([IO.Path]::GetFileName($path))"
    }
    if ($smallCacheCount -gt 0) {
        Write-Host '  Pominieto pamieci podreczne mniejsze niz 100 MB.' -ForegroundColor DarkGray
        Add-RunLog "Left $smallCacheCount application cache folder(s) smaller than 100 MB unchanged."
    }

    Write-Host ''
    Write-Host 'Czyszczenie pobranych plikow Windows Update wymaga zatrzymania uslug.' -ForegroundColor Gray
    if (Should-RunSelectedAction 'Usunac pliki pobrane przez Windows Update?') {
        $serviceNames = @('wuauserv', 'bits')
        $serviceStates = @{}
        foreach ($name in $serviceNames) {
            $service = Get-Service -Name $name -ErrorAction SilentlyContinue
            if ($service) {
                $serviceStates[$name] = $service.Status
            }
        }

        try {
            foreach ($name in $serviceStates.Keys) {
                if ($serviceStates[$name] -eq 'Running') {
                    Stop-Service -Name $name -Force -ErrorAction Stop
                }
            }
            Remove-DirectoryContents -Path (Join-Path $env:windir 'SoftwareDistribution\Download') -Label 'Pobrane pliki Windows Update'
        }
        finally {
            foreach ($name in $serviceStates.Keys) {
                if ($serviceStates[$name] -eq 'Running') {
                    try {
                        if ((Get-Service -Name $name).Status -ne 'Running') {
                            Start-Service -Name $name -ErrorAction Stop
                        }
                    }
                    catch {
                        Write-Host "  Nie udalo sie ponownie uruchomic uslugi $name : $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
        }
    }

    if (Get-Command -Name Delete-DeliveryOptimizationCache -ErrorAction SilentlyContinue) {
        Delete-DeliveryOptimizationCache -Force
        Add-RunLog 'Delivery Optimization cache cleanup was invoked.'
        Write-Host '  + Usunieto cache Optymalizacji dostarczania.' -ForegroundColor Green
        Complete-Operation
    }

}

function Invoke-DismCleanup {
    Write-Section 'Koncowy etap: DISM i magazyn skladnikow'
    Add-RunLog 'DISM component-store analysis and cleanup started.'
    $dism = Join-Path $env:windir 'System32\dism.exe'
    if (-not (Test-Path -LiteralPath $dism -PathType Leaf)) {
        throw 'Nie znaleziono programu DISM.'
    }

    Write-Host 'DISM wykona kolejno analize, standardowe czyszczenie i ResetBase /Defer.' -ForegroundColor Gray
    Write-Host 'RESETBASE JEST NIEODWRACALNE:' -ForegroundColor Red
    Write-Host '  - po wykonaniu nie bedzie mozna odinstalowac obecnie zainstalowanych aktualizacji Windows;' -ForegroundColor Yellow
    Write-Host '  - nie bedzie mozna przywrocic poprzednich wersji zastapionych skladnikow;' -ForegroundColor Yellow
    Write-Host '      - Punkt przywracania nie cofnie tych zmian.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Analiza magazynu skladnikow (bez wprowadzania zmian)...' -ForegroundColor Cyan
    Send-CleanupProgress -Phase 'analyze' -CurrentPath $dism
    & $dism /Online /Cleanup-Image /AnalyzeComponentStore 2>&1 | ForEach-Object { Write-Host ([string]$_) }
    Add-RunLog "DISM AnalyzeComponentStore exit code: $LASTEXITCODE"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Analiza DISM zakonczyla sie kodem $LASTEXITCODE; dalsze kroki pominieto." -ForegroundColor Red
        return
    }

    Complete-Operation
    Write-Host ''
    Write-Host 'Standardowe czyszczenie zastapionych skladnikow...' -ForegroundColor Cyan
    Send-CleanupProgress -Phase 'analyze' -CurrentPath $dism
    & $dism /Online /Cleanup-Image /StartComponentCleanup 2>&1 | ForEach-Object { Write-Host ([string]$_) }
    Add-RunLog "DISM StartComponentCleanup exit code: $LASTEXITCODE"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Standardowe czyszczenie DISM zakonczylo sie kodem $LASTEXITCODE; ResetBase pominieto." -ForegroundColor Red
        return
    }

    Complete-Operation
    if (-not (Confirm-UserAction 'Uruchomic nieodwracalne ResetBase? Po tej operacji nie bedzie mozna odinstalowac zainstalowanych aktualizacji.')) {
        Add-RunLog 'User declined irreversible DISM ResetBase.'
        Write-Host 'ResetBase pominięto zgodnie z wyborem użytkownika.' -ForegroundColor Gray
        return
    }
    Write-Host ''
    Write-Host 'Uruchamiam ResetBase /Defer (bez mozliwosci odinstalowania aktualizacji)...' -ForegroundColor Yellow
    Send-CleanupProgress -Phase 'analyze' -CurrentPath $dism
    & $dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase /Defer 2>&1 | ForEach-Object { Write-Host ([string]$_) }
    Add-RunLog "DISM ResetBase /Defer exit code: $LASTEXITCODE"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ResetBase DISM zakonczyl sie kodem $LASTEXITCODE." -ForegroundColor Red
    }
}

function Invoke-DiskCleanup {
    Write-Section 'Wbudowane Oczyszczanie dysku'
    Add-RunLog 'Visible cleanmgr cleanup started for selected safe categories.'
    Write-Host 'Uruchamiam Oczyszczanie dysku dla tymczasowych plikow, cache shaderow, raportow bledow i logow instalacji.' -ForegroundColor Gray
    Write-Host 'Pobrane, cookies, Kosz, stare instalacje Windows i dane osobiste sa wylaczone.' -ForegroundColor Yellow
    Write-Host 'Profil cleanmgr jest tymczasowy i zostanie przywrocony po zakonczeniu.' -ForegroundColor Gray
    $cleanmgr = Join-Path $env:windir 'System32\cleanmgr.exe'
    if (-not (Test-Path -LiteralPath $cleanmgr)) {
        throw 'Nie znaleziono cleanmgr.exe.'
    }
    Send-CleanupProgress -Phase 'external' -CurrentPath $cleanmgr
    $existingCleanmgr = @(Get-Process -Name 'cleanmgr' -ErrorAction SilentlyContinue)
    if ($existingCleanmgr.Count -gt 0) {
        Write-Host (Convert-LocalizedText 'Wykryto juz uruchomione Oczyszczanie dysku. Nie uruchamiam kolejnej instancji; przelacz sie na jego okno z paska zadan i poczekaj.') -ForegroundColor Yellow
        Add-RunLog "Found $($existingCleanmgr.Count) existing cleanmgr process(es); waiting instead of starting another instance."
        foreach ($existingProcess in $existingCleanmgr) {
            Wait-CleanmgrProcess -Process $existingProcess -HeartbeatText 'Oczekiwanie na zakonczenie Oczyszczania dysku. Jesli wymaga reakcji, jego okno jest dostepne na pasku zadan.'
        }
    }

    $volumeCachesPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
    $safeCategories = @(
        'Active Setup Temp Folders',
        'BranchCache',
        'D3D Shader Cache',
        'Downloaded Program Files',
        'Memory Dump Files',
        'Setup Log Files',
        'System error memory dump files',
        'System error minidump files',
        'Temporary Files',
        'Temporary Setup Files',
        'Thumbnail Cache',
        'Windows Error Reporting Archive Files',
        'Windows Error Reporting Queue Files',
        'Windows Upgrade Log Files'
    )
    $handlers = @(Get-ChildItem -LiteralPath $volumeCachesPath -ErrorAction Stop)
    do {
        $profileId = Get-Random -Minimum 1000 -Maximum 10000
        $flagName = 'StateFlags{0:D4}' -f $profileId
        $profileInUse = $false
        foreach ($handler in $handlers) {
            if ($handler.GetValueNames() -contains $flagName) {
                $profileInUse = $true
                break
            }
        }
    } while ($profileInUse)

    $originalFlags = @{}
    try {
        foreach ($handler in $handlers) {
            $keyPath = $handler.PSPath
            $hasExistingValue = $handler.GetValueNames() -contains $flagName
            $originalFlags[$keyPath] = [pscustomobject]@{
                HadValue = $hasExistingValue
                Value = if ($hasExistingValue) { $handler.GetValue($flagName) } else { $null }
                Kind = if ($hasExistingValue) { $handler.GetValueKind($flagName) } else { $null }
            }
            $selectedValue = if ($handler.PSChildName -in $safeCategories) { 2 } else { 0 }
            New-ItemProperty -LiteralPath $keyPath -Name $flagName -Value $selectedValue -PropertyType DWord -Force -ErrorAction Stop | Out-Null
        }

        Write-Host "Czyszczenie kategorii cleanmgr (profil tymczasowy $profileId)..." -ForegroundColor Cyan
        Write-Host (Convert-LocalizedText 'Oczyszczanie dysku jest otwarte. Jesli czeka, przelacz sie na jego okno z paska zadan. Nie zamykaj tej aplikacji; czyszczenie wznowi sie po zakonczeniu cleanmgr.') -ForegroundColor Yellow
        $process = Start-Process -FilePath $cleanmgr -ArgumentList @("/sagerun:$profileId") -WindowStyle Normal -PassThru
        Wait-CleanmgrProcess -Process $process -HeartbeatText 'Oczekiwanie na zakonczenie Oczyszczania dysku. Jesli wymaga reakcji, jego okno jest dostepne na pasku zadan.'
        Add-RunLog "cleanmgr /sagerun:$profileId exit code: $($process.ExitCode)"
        if ($process.ExitCode -ne 0) {
            Write-Host "  cleanmgr /sagerun:$profileId zakonczyl sie kodem $($process.ExitCode)." -ForegroundColor Red
        }
        Complete-Operation
    }
    finally {
        foreach ($keyPath in $originalFlags.Keys) {
            $saved = $originalFlags[$keyPath]
            try {
                if ($saved.HadValue) {
                    New-ItemProperty -LiteralPath $keyPath -Name $flagName -Value $saved.Value -PropertyType $saved.Kind -Force -ErrorAction Stop | Out-Null
                }
                else {
                    Remove-ItemProperty -LiteralPath $keyPath -Name $flagName -ErrorAction Stop
                }
            }
            catch {
                Add-RunLog "Could not restore a temporary cleanmgr setting under $keyPath."
            }
        }
    }
    Write-Host '  Czyszczenie cleanmgr zakonczone.' -ForegroundColor Green
}

function Wait-CleanmgrProcess {
    param(
        [Parameter(Mandatory)][Diagnostics.Process]$Process,
        [Parameter(Mandatory)][string]$HeartbeatText
    )

    $nextHeartbeat = (Get-Date).AddSeconds(30)
    while ($true) {
        try {
            if ($Process.HasExited) {
                break
            }
            [void]$Process.WaitForExit(15000)
        }
        catch [InvalidOperationException] {
            break
        }

        if (-not $Process.HasExited -and (Get-Date) -ge $nextHeartbeat) {
            Write-Host (Convert-LocalizedText $HeartbeatText) -ForegroundColor Yellow
            $nextHeartbeat = (Get-Date).AddSeconds(30)
        }
    }
    $Process.Refresh()
}


function Invoke-DumpCleanup {
    Write-Section 'Zrzuty pamieci i awarii'
    $candidates = @(
        (Join-Path $env:windir 'MEMORY.DMP'),
        (Join-Path $env:windir 'Minidump'),
        (Join-Path $env:LOCALAPPDATA 'CrashDumps')
    )

    $dumpFiles = [Collections.Generic.List[IO.FileInfo]]::new()
    $scanHeartbeat = [Diagnostics.Stopwatch]::StartNew()
    Send-CleanupProgress -Phase 'scan' -CurrentPath ($candidates -join '; ')
    foreach ($path in $candidates) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $dumpFiles.Add((Get-Item -LiteralPath $path -Force))
        }
        elseif (Test-Path -LiteralPath $path -PathType Container) {
            foreach ($file in Get-ChildItem -LiteralPath $path -File -Force -Recurse -ErrorAction SilentlyContinue) {
                if ($scanHeartbeat.ElapsedMilliseconds -ge 500) {
                    Send-CleanupProgress -Phase 'scan' -CurrentPath $file.FullName -Completed $dumpFiles.Count
                    $scanHeartbeat.Restart()
                }
                if ($file.Extension -in @('.dmp', '.mdmp')) {
                    $dumpFiles.Add($file)
                }
            }
        }
    }

    if ($dumpFiles.Count -eq 0) {
        Write-Host 'Nie znaleziono zrzutow w typowych lokalizacjach.' -ForegroundColor DarkGray
        return
    }

    $dumpFiles = @($dumpFiles | Sort-Object FullName -Unique)
    foreach ($file in $dumpFiles) {
        $fileSize = [string]::Format($script:DisplayCulture, '{0,8:N0} MB', ($file.Length / 1MB))
        Write-Host "$fileSize  $($file.FullName)" -ForegroundColor Gray
        Add-RunLog "Found dump: $($file.FullName) ($(Format-ByteCount $file.Length))"
    }
    Write-Host 'Lista obejmuje tylko standardowe lokalizacje zrzutow systemu i aplikacji.' -ForegroundColor DarkGray
    if (-not (Confirm-UserAction 'Usunac znalezione zrzuty pamieci? Usuniecie jest trwale.')) {
        Add-RunLog 'User declined memory dump deletion.'
        return
    }

    $dumpFiles = @($dumpFiles)
    $dumpProgress = [Diagnostics.Stopwatch]::StartNew()
    $processedDumps = 0
    Send-CleanupProgress -Phase 'delete' -CurrentPath $dumpFiles[0].FullName -Completed 0 -Total $dumpFiles.Count
    foreach ($file in $dumpFiles) {
        try {
            Remove-Item -LiteralPath $file.FullName -Force -Recurse -ErrorAction Stop
            $script:RemovedItems++
            $script:FreedBytes += $file.Length
            Add-RunLog "Removed dump: $($file.FullName) ($(Format-ByteCount $file.Length))"
            Write-Host "  + Usunieto: $($file.FullName)" -ForegroundColor Green
            Publish-GuiCleanupStatistics
        }
        catch {
            $script:SkippedItems++
            $script:SkippedFiles++
            Add-SkippedDetail -Path $file.FullName -Reason $_.Exception.Message
        }
        $processedDumps++
        $remaining = -1
        if ($processedDumps -ge 2 -and $processedDumps -lt $dumpFiles.Count) {
            $remaining = ($dumpProgress.Elapsed.TotalSeconds / $processedDumps) * ($dumpFiles.Count - $processedDumps)
        }
        Send-CleanupProgress -Phase 'delete' -CurrentPath $file.FullName -Completed $processedDumps -Total $dumpFiles.Count -RemainingSeconds $remaining
    }
}

function Clear-ArchivedDiagnosticLogs {
    Write-Section 'Czyszczenie archiwalnych logow diagnostycznych'
    Write-Host 'Usuwane sa tylko logi archiwalne starsze niz 30 dni. Dzienniki zdarzen Windows i logi biezace pozostaja bez zmian.' -ForegroundColor Gray
    Add-RunLog 'Archived diagnostic log cleanup started; Windows event logs and active logs are preserved.'
    $cutoff = (Get-Date).AddDays(-30)
    $logSources = @(
        [pscustomobject]@{ Path = (Join-Path $env:windir 'Logs\CBS'); Pattern = 'CbsPersist_*.log' },
        [pscustomobject]@{ Path = (Join-Path $env:windir 'Logs\CBS'); Pattern = 'CbsPersist_*.cab' },
        [pscustomobject]@{ Path = (Join-Path $env:windir 'Logs\DISM'); Pattern = 'DismPersist_*.log' },
        [pscustomobject]@{ Path = (Join-Path $env:windir 'Panther'); Pattern = '*.log' },
        [pscustomobject]@{ Path = (Join-Path $env:APPDATA 'Microsoft\Teams\logs'); Pattern = '*.log*' },
        [pscustomobject]@{ Path = (Join-Path $env:APPDATA 'Slack\logs'); Pattern = '*.log*' },
        [pscustomobject]@{ Path = (Join-Path $env:APPDATA 'discord\logs'); Pattern = '*.log*' },
        [pscustomobject]@{ Path = (Join-Path $env:APPDATA 'Code\logs'); Pattern = '*.log*' }
    )
    $removed = 0
    $skipped = 0
    $bytes = 0L
    foreach ($source in $logSources) {
        if (-not (Test-Path -LiteralPath $source.Path -PathType Container)) { continue }
        $enumerationErrors = @()
        $files = @(Get-ChildItem -LiteralPath $source.Path -File -Force -Filter $source.Pattern -ErrorAction SilentlyContinue -ErrorVariable +enumerationErrors |
            Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Name -notin @('CBS.log', 'DISM.log', 'setupact.log', 'setuperr.log') })
        $skipped += $enumerationErrors.Count
        $script:SkippedDirectories += $enumerationErrors.Count
        foreach ($errorRecord in $enumerationErrors) {
            $errorPath = if ($errorRecord.TargetObject) { [string]$errorRecord.TargetObject } else { $source.Path }
            Add-SkippedDetail -Path $errorPath -Reason $errorRecord.Exception.Message
        }
        foreach ($file in $files) {
            try {
                Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
                $removed++
                $bytes += [long]$file.Length
                Add-RunLog "Removed archived log: $($file.FullName) ($(Format-ByteCount ([long]$file.Length)))"
            }
            catch {
                $skipped++
                $script:SkippedFiles++
                Add-SkippedDetail -Path $file.FullName -Reason $_.Exception.Message
                Add-RunLog "Could not remove archived log: $($file.FullName) | $($_.Exception.Message)"
            }
        }
    }
    $script:RemovedItems += $removed
    $script:FreedBytes += $bytes
    $script:SkippedItems += $skipped
    $script:RemovedDiagnosticLogs += $removed
    Write-Host "  + Usunieto $removed archiwalnych logow, $(Format-ByteCount $bytes)." -ForegroundColor Green
    Add-RunLog "Archived log summary: removed $removed file(s), $(Format-ByteCount $bytes); skipped $skipped. Event logs were preserved."
    Publish-GuiCleanupStatistics
}

function Invoke-RestorePointManagement {
    Write-Section 'Punkty przywracania systemu'
    try {
        $points = @(Get-CimInstance -Namespace 'root/default' -ClassName SystemRestore -ErrorAction Stop | Sort-Object SequenceNumber)
    }
    catch {
        try {
            $points = @(Get-ComputerRestorePoint -ErrorAction Stop | Sort-Object SequenceNumber)
        }
        catch {
            Write-Host "Nie mozna odczytac punktow przywracania: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host 'Sprawdz, czy Ochrona systemu jest wlaczona dla dysku systemowego.' -ForegroundColor Gray
            return
        }
    }
    if ($points.Count -eq 0) {
        Write-Host 'System nie zglasza dostepnych punktow przywracania.' -ForegroundColor DarkGray
    }
    else {
        Write-Host '  Nr       Data utworzenia         Opis' -ForegroundColor Gray
        foreach ($point in $points) {
            $created = [string]$point.CreationTime
            try {
                $created = [System.Management.ManagementDateTimeConverter]::ToDateTime($created).ToString('yyyy-MM-dd HH:mm')
            }
            catch { }
            Write-Host ('  {0,-8} {1,-23} {2}' -f $point.SequenceNumber, $created, $point.Description) -ForegroundColor White
        }
    }

    $toDelete = @()
    if ($points.Count -gt 0 -and $GuiPipeName -and $script:GuiWriter) {
        $guiPoints = @($points | ForEach-Object {
            $created = [string]$_.CreationTime
            try {
                $created = [System.Management.ManagementDateTimeConverter]::ToDateTime($created).ToString('yyyy-MM-dd HH:mm')
            }
            catch { }
            [pscustomobject]@{
                sequenceNumber = [uint32]$_.SequenceNumber
                creationTime = $created
                description = [string]$_.Description
            }
        })
        Send-GuiMessage -Type 'restorepoints' `
            -Text (Convert-LocalizedText 'Zaznacz punkty przywracania do trwalego usuniecia. Operacji nie mozna cofnac.') `
            -Data $guiPoints
        $response = Read-GuiResponse
        $requested = @($response.value | ForEach-Object { [uint32]$_ })
        $validNumbers = @($points | ForEach-Object { [uint32]$_.SequenceNumber })
        if (@($requested | Where-Object { $_ -notin $validNumbers }).Count -gt 0) {
            throw 'The GUI returned an unknown restore point selection.'
        }
        $toDelete = @($points | Where-Object { [uint32]$_.SequenceNumber -in $requested })
        Add-RunLog "Restore-point deletion selection: $($requested -join ', ')"
    }
    elseif ($points.Count -gt 0) {
        Write-Host ''
        Write-Host (Convert-LocalizedText 'Enter comma separated numbers to delete (ex. 10,11) or type ALL to delete all restore points listed above') -ForegroundColor Gray
        $selection = Read-Host 'Enter restore point numbers or "ALL" (press ENTER to cancel whole operation)'
        Add-RunLog "Restore-point deletion selection: $selection"
        if (-not [string]::IsNullOrWhiteSpace($selection)) {
            $requested = @($selection -split ',' | ForEach-Object { $_.Trim() })
            if ($requested -contains 'ALL') {
                if ($requested.Count -ne 1) {
                    Write-Host (Convert-LocalizedText 'ALL mozna podac samodzielnie. Niczego nie usunieto.') -ForegroundColor Red
                    return
                }
                $toDelete = $points
            }
            else {
                foreach ($value in $requested) {
                    if ($value -notmatch '^\d+$' -or -not ($points.SequenceNumber -contains [uint32]$value)) {
                        Write-Host "Nieprawidlowy lub nieistniejacy numer: $value. Niczego nie usunieto." -ForegroundColor Red
                        return
                    }
                }
                $toDelete = @($points | Where-Object { $requested -contains ([string]$_.SequenceNumber) })
            }
        }
    }

    if ($toDelete.Count -gt 0) {
        $script:PendingRestorePointCreation = $true
        Add-RunLog 'A new restore point will be created after restore-point deletion was selected.'
        Write-Host "Do usuniecia: $((@($toDelete | ForEach-Object { $_.SequenceNumber }) -join ', '))" -ForegroundColor Yellow
        if (-not ('RestorePointNative' -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class RestorePointNative
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr LoadLibrary(string fileName);

    [DllImport("kernel32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    private static extern IntPtr GetProcAddress(IntPtr module, string procedureName);

    [UnmanagedFunctionPointer(CallingConvention.Winapi)]
    private delegate uint RemoveRestorePointDelegate(uint sequenceNumber);

    public static uint Remove(uint sequenceNumber)
    {
        IntPtr module = LoadLibrary("SrClient.dll");
        if (module == IntPtr.Zero)
            throw new InvalidOperationException("Could not load SrClient.dll.");

        IntPtr address = GetProcAddress(module, "SRRemoveRestorePoint");
        if (address == IntPtr.Zero)
            throw new InvalidOperationException("SRRemoveRestorePoint was not found.");

        var remove = (RemoveRestorePointDelegate)Marshal.GetDelegateForFunctionPointer(
            address, typeof(RemoveRestorePointDelegate));
        return remove(sequenceNumber);
    }
}
'@
        }
        foreach ($point in $toDelete) {
            try {
                $result = [RestorePointNative]::Remove([uint32]$point.SequenceNumber)
                if ($result -eq 0) {
                    $script:RemovedRestorePoints++
                    Add-RunLog "Removed restore point $($point.SequenceNumber): $($point.Description)"
                    Write-Host "  + Usunieto punkt $($point.SequenceNumber): $($point.Description)" -ForegroundColor Green
                }
                else {
                    $failureReason = [ComponentModel.Win32Exception]::new([int]$result).Message
                    Add-RunLog "Could not remove restore point $($point.SequenceNumber) (code $result)."
                    Write-Host "  - Nie udalo sie usunac punktu $($point.SequenceNumber): $failureReason (kod $result)." -ForegroundColor Red
                    if ($result -eq 5) {
                        Write-Host '    Windows odmowil usuniecia tego punktu; moze byc chroniony lub zarzadzany przez system.' -ForegroundColor DarkYellow
                    }
                }
            }
            catch {
                Add-RunLog "Could not remove restore point $($point.SequenceNumber): $($_.Exception.GetType().Name)"
                Write-Host "  - Nie udalo sie usunac punktu $($point.SequenceNumber)." -ForegroundColor Red
            }
            Complete-Operation
            Publish-GuiCleanupStatistics
        }
    }
    elseif ($GuiPipeName -and $points.Count -gt 0) {
        Write-Host (Convert-LocalizedText 'Wybor punktow anulowany; niczego nie usunieto.') -ForegroundColor DarkGray
        Add-RunLog 'Restore-point selection cancelled; no points were removed.'
    }
}

function New-CleanupRestorePoint {
    Write-Section 'Tworzenie punktu przywracania'
    try {
        Checkpoint-Computer -Description (Convert-LocalizedText 'Punkt po zarzadzaniu punktami przywracania') -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop | Out-Null
        $script:CreatedRestorePoints++
        Add-RunLog 'Created a restore point after cleanup.'
        Write-Host 'Utworzono nowy punkt przywracania.' -ForegroundColor Green
    }
    catch {
        Add-RunLog "Could not create a restore point: $($_.Exception.Message)"
        Write-Host "Nie utworzono punktu przywracania: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host 'Windows moze ograniczac tworzenie punktow do jednego na 24 godziny.' -ForegroundColor DarkYellow
    }
    Complete-Operation
}

function Invoke-SelectedCleanupOperations {
    param([Parameter(Mandatory)][string[]]$Choices)

    $options = [ordered]@{
        '1' = 'Bezpieczne czyszczenie (Temp, cache przegladarek, WER, Windows Update)'
        '2' = 'Oczyszczanie dysku Windows (bezpieczne kategorie)'
        '3' = 'Wyszukaj i opcjonalnie usun zrzuty DMP'
        '4' = 'Zarzadzaj punktami przywracania (wybor konkretnych punktow)'
        '5' = 'Czyszczenie archiwalnych logow diagnostycznych'
        '6' = 'DISM: analiza, czyszczenie i ResetBase (blokuje odinstalowanie aktualizacji)'
    }
    $unknownChoices = @($Choices | Where-Object { $_ -notin $options.Keys })
    if ($unknownChoices.Count -gt 0) {
        throw "Nieprawidlowy wybor operacji: $($unknownChoices -join ', ')."
    }

    $Choices = @($options.Keys | Where-Object { $Choices -contains $_ })
    if ($Choices.Count -eq 0) {
        throw 'Nie wybrano zadnej operacji.'
    }

    $script:RemovedItems = 0
    $script:FreedBytes = 0
    $script:SkippedItems = 0
    $script:SkippedFiles = 0
    $script:SkippedDirectories = 0
    $script:SkippedDetails.Clear()
    $script:SessionLogPath = $null
    $script:RemovedDiagnosticLogs = 0
    $script:RemovedRestorePoints = 0
    $script:CreatedRestorePoints = 0
    $script:PendingRestorePointCreation = $false
    $script:CurrentOperationId = $null
    $script:OperationStats = [Collections.Generic.List[object]]::new()
    foreach ($choice in $Choices) {
        $script:OperationStats.Add([pscustomobject]@{
            id = [string]$choice
            label = [string](Convert-LocalizedText $options[$choice])
            bytes = [long]0
            bytesKnown = [bool]($choice -in @('1', '3', '5'))
            files = [int]0
            restorePoints = [int]0
            state = 'pending'
        })
    }
    $script:RunLog.Clear()
    $script:RunStarted = Get-Date
    $script:CleanupRunInProgress = $true
    Add-RunLog 'Cleanup run started.'
    $operationNames = @($Choices | ForEach-Object {
        '{0} - {1}' -f $_, (Convert-LocalizedText $options[$_])
    })

    Write-Host ''
    Write-Host 'Wybrane operacje:' -ForegroundColor Cyan
    foreach ($operationName in $operationNames) {
        Write-Host "  * $operationName" -ForegroundColor Green
    }
    if ($Choices -contains '6') {
        Write-Host 'UWAGA: DISM ResetBase jest nieodwracalne i blokuje odinstalowanie aktualizacji Windows.' -ForegroundColor Yellow
        Write-Host 'Punkt przywracania nie cofnie tych zmian.' -ForegroundColor Yellow
    }
    if ($Choices -contains '2') {
        Write-Host 'cleanmgr uzyje tylko bezpiecznych kategorii; dane uzytkownika, Kosz i poprzednie instalacje sa wylaczone.' -ForegroundColor Yellow
    }
    if ($Choices.Count -eq $options.Count) {
        Write-Host 'Zaznaczenie wszystkich opcji nie omija indywidualnych monitow bezpieczenstwa.' -ForegroundColor Cyan
    }

    foreach ($choice in $Choices) {
        Write-Section "Opcja $choice"
        $operation = @($script:OperationStats | Where-Object { $_.id -eq $choice })[0]
        $script:CurrentOperationId = [string]$choice
        $script:CurrentOperationBytesBase = [long]$script:FreedBytes
        $script:CurrentOperationFilesBase = [int]$script:RemovedItems
        $script:CurrentOperationRestorePointsBase = [int]$script:RemovedRestorePoints
        $operation.state = 'running'
        $beforeSystemDriveFree = if ($choice -in @('2', '6')) { Get-SystemDriveFreeBytes } else { $null }
        $beforeShadowStorage = if ($choice -eq '4') { Get-ShadowStorageUsedBytes } else { $null }
        Publish-GuiCleanupStatistics
        try {
            switch ($choice) {
                '1' { Invoke-SafeCleanup }
                '2' { Invoke-DiskCleanup }
                '3' { Invoke-DumpCleanup }
                '4' { Invoke-RestorePointManagement }
                '5' { Clear-ArchivedDiagnosticLogs }
                '6' { Invoke-DismCleanup }
            }
        }
        catch {
            Write-Host ''
            Write-Host "BLAD w opcji ${choice}: $($_.Exception.Message)" -ForegroundColor Red
            Add-RunLog "Operation $choice failed: $($_.Exception.Message)"
        }
        if ($choice -in @('2', '6') -and $null -ne $beforeSystemDriveFree) {
            $afterSystemDriveFree = Get-SystemDriveFreeBytes
            if ($null -ne $afterSystemDriveFree -and $afterSystemDriveFree -ge $beforeSystemDriveFree) {
                $measuredBytes = [long]($afterSystemDriveFree - $beforeSystemDriveFree)
                $script:FreedBytes += $measuredBytes
                $operation.bytesKnown = $true
                Add-RunLog "Measured system-drive free-space increase for operation ${choice}: $(Format-ByteCount $measuredBytes)."
            }
        }
        elseif ($choice -eq '4' -and $script:PendingRestorePointCreation -and $null -ne $beforeShadowStorage) {
            $afterShadowStorage = Get-ShadowStorageUsedBytes
            if ($null -ne $afterShadowStorage -and $afterShadowStorage -le $beforeShadowStorage) {
                $measuredBytes = [long]($beforeShadowStorage - $afterShadowStorage)
                $script:FreedBytes += $measuredBytes
                $operation.bytesKnown = $true
                Add-RunLog "Measured VSS shadow-storage reduction after restore-point removal: $(Format-ByteCount $measuredBytes)."
            }
        }
        elseif ($choice -eq '4' -and -not $script:PendingRestorePointCreation) {
            $operation.bytesKnown = $true
        }
        $operation.bytes = [long]($script:FreedBytes - $script:CurrentOperationBytesBase)
        $operation.files = [int]($script:RemovedItems - $script:CurrentOperationFilesBase)
        $operation.restorePoints = [int]($script:RemovedRestorePoints - $script:CurrentOperationRestorePointsBase)
        $operation.state = 'complete'
        $script:CurrentOperationId = $null
        Publish-GuiCleanupStatistics
        Complete-Operation
    }

    if ($script:PendingRestorePointCreation) {
        New-CleanupRestorePoint
    }

    $script:CleanupRunInProgress = $false
    Publish-GuiCleanupStatistics
    Show-CleanupSummary -OperationNames $operationNames -Choices $Choices
}

function Invoke-MainMenu {
    while ($true) {
        $selected = [Collections.Generic.HashSet[string]]::new()
        $exitSelected = $false
        $options = [ordered]@{
            '1' = 'Bezpieczne czyszczenie (Temp, cache przegladarek, WER, Windows Update)'
            '2' = 'Oczyszczanie dysku Windows (bezpieczne kategorie)'
            '3' = 'Wyszukaj i opcjonalnie usun zrzuty DMP'
            '4' = 'Zarzadzaj punktami przywracania (wybor konkretnych punktow)'
            '5' = 'Czyszczenie archiwalnych logow diagnostycznych'
            '6' = 'DISM: analiza, czyszczenie i ResetBase (blokuje odinstalowanie aktualizacji)'
        }

        $finishMenu = $false
        while (-not $finishMenu) {
            Write-Header
            Write-Host '  Wcisnij cyfre 1-6, aby wybrac warianty czyszczenia. 7 zaznacza wszystkie. 0 wybiera wyjscie; Enter je zatwierdza.' -ForegroundColor Gray
            Write-Host ''

            foreach ($key in $options.Keys) {
                $isSelected = $selected.Contains([string]$key)
                $marker = if ($isSelected) { '*' } else { ' ' }
                $color = if ($isSelected) { [ConsoleColor]::Green } elseif ($key -eq '6') { [ConsoleColor]::Yellow } else { [ConsoleColor]::White }
                Write-Host ('  [{0}] {1}  {2}' -f $marker, $key, $options[$key]) -ForegroundColor $color
            }
            $allSelected = $selected.Count -eq $options.Count
            $allMarker = if ($allSelected) { '*' } else { ' ' }
            $allColor = if ($allSelected) { [ConsoleColor]::Green } else { [ConsoleColor]::Cyan }
            Write-Host ('  [{0}] 7  ZAZNACZ WSZYSTKIE opcje (ponowne 7 odznacza wszystkie)' -f $allMarker) -ForegroundColor $allColor
            $exitMarker = if ($exitSelected) { '*' } else { ' ' }
            $exitColor = if ($exitSelected) { [ConsoleColor]::Green } else { [ConsoleColor]::White }
            Write-Host ('  [{0}] 0  Wyjdz z programu' -f $exitMarker) -ForegroundColor $exitColor
            Write-Host ''
            Write-Host 'ENTER - zatwierdz wybor' -ForegroundColor Gray

            $keyInfo = [Console]::ReadKey($true)
            $pressed = [string]$keyInfo.KeyChar
            if ($pressed -eq '0') {
                $exitSelected = $true
                $selected.Clear()
                continue
            }
            if ($pressed -eq '7') {
                $exitSelected = $false
                if ($selected.Count -eq $options.Count) {
                    $selected.Clear()
                }
                else {
                    foreach ($key in $options.Keys) {
                        [void]$selected.Add([string]$key)
                    }
                }
                continue
            }
            if ($pressed -match '^[1-6]$') {
                $exitSelected = $false
                if (-not $selected.Add($pressed)) {
                    [void]$selected.Remove($pressed)
                }
                continue
            }
            if ($keyInfo.Key -ne [ConsoleKey]::Enter) {
                continue
            }
            if ($exitSelected) {
                return
            }

            if ($selected.Count -eq 0) {
                Write-Host 'Nie wybrano zadnej operacji.' -ForegroundColor DarkYellow
                Start-Sleep -Milliseconds 900
                continue
            }

            $choices = @($options.Keys | Where-Object { $selected.Contains([string]$_) })
            Invoke-SelectedCleanupOperations -Choices $choices
            $finishMenu = $true
        }
    }
}

if (-not $IsWindows -and [Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Ten skrypt jest przeznaczony dla systemu Windows.'
}

if (-not (Test-IsAdministrator)) {
    Write-Host 'Skrypt wymaga uprawnien administratora. Otwieram okno UAC...' -ForegroundColor Yellow
    $hostExe = Join-Path $PSHOME 'powershell.exe'
    if ($PSVersionTable.PSEdition -eq 'Core') {
        $hostExe = Join-Path $PSHOME 'pwsh.exe'
    }
    try {
        $argumentList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
        if ($GuiOperations) {
            $argumentList += @('-GuiOperations', "`"$GuiOperations`"")
        }
        if ($GuiPipeName) {
            $argumentList += @('-GuiPipeName', "`"$GuiPipeName`"")
        }
        if ($InterfaceLanguage) {
            $argumentList += @('-InterfaceLanguage', $InterfaceLanguage)
        }
        Start-Process -FilePath $hostExe -Verb RunAs -ArgumentList ($argumentList -join ' ')
    }
    finally {
        Restore-ConsoleTheme
    }
    exit
}

try {
    Connect-GuiChannel
    if ($GuiOperations) {
        $guiChoices = @($GuiOperations -split ',' | ForEach-Object { $_.Trim() })
        Invoke-SelectedCleanupOperations -Choices $guiChoices
    }
    else {
        Invoke-MainMenu
    }
}
catch {
    Add-RunLog "Fatal cleanup error: $($_.Exception.ToString())"
    if ($script:GuiWriter) {
        Send-GuiMessage -Type 'error' -Text $_.Exception.Message
    }
    if ($GuiOperations -and [string]::IsNullOrWhiteSpace($script:SessionLogPath) -and $script:RunStarted) {
        [void](Save-CleanupSessionLog)
    }
    throw
}
finally {
    if (-not $GuiPipeName) {
        Write-Header
    }
    Write-Host '  Sesja zakonczyla sie.' -ForegroundColor Cyan
    if ($GuiPipeName -and $script:GuiWriter) {
        try {
            Send-GuiMessage -Type 'complete' -Text 'Cleanup finished.'
        }
        finally {
            $script:GuiWriter.Dispose()
            $script:GuiReader.Dispose()
            $script:GuiPipe.Dispose()
        }
    }
    else {
        Restore-ConsoleTheme
    }
}