@echo off
setlocal enabledelayedexpansion
:: Ustawienie koloru na starcie
color 0A

:: ---------------------------------------------------
:: INICJALIZACJA POMIARU CZASU
:: ---------------------------------------------------
powershell -NoProfile -Command "Get-Date | Export-Clixml -Path $env:TEMP\script_start.xml"

:: Ustawienia wersji i repozytorium
set "LOKALNA_WERSJA=1.1"
set "GITHUB_URL_RAW=https://raw.githubusercontent.com/piotrrgw/auto_aktualizacja_pc/main/wersja.txt"
set "GITHUB_BAT_RAW=https://raw.githubusercontent.com/piotrrgw/auto_aktualizacja_pc/main/Auto_Aktualizacja_WINDOWS.bat"
set "GITHUB_REPO_URL=https://github.com/piotrrgw/auto_aktualizacja_pc"

:: Statusy domyślne
set "STAT_WINGET=Oczekiwanie..."
set "STAT_APPS=Oczekiwanie..."
set "STAT_SYS=Oczekiwanie..."
set "STAT_DRV=Pominięto"
set "STAT_NEW_VER=Sprawdzanie..."
set "STAT_CLEANUP=Oczekiwanie..."

:: ---------------------------------------------------
:: SPRAWDZANIE UPRAWNIEŃ ADMINISTRATORA
:: ---------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ===================================================
    echo [ BŁĄD ] Brak uprawnień administratora!
    echo          Uruchom jako administrator.
    echo ===================================================
    echo.
    pause
    exit
)

echo ===================================================
echo   SKRYPT AKTUALIZACYJNY (Winget + Windows Update)
echo ===================================================
echo.

:: ---------------------------------------------------
:: WERYFIKACJA WERSJI I SELF-UPDATING
:: ---------------------------------------------------
echo [ INFO ] Sprawdzanie dostępności nowszej wersji skryptu...
curl -s "%GITHUB_URL_RAW%" > "%temp%\wersja_github.txt"
set /p ZDALNA_WERSJA=<"%temp%\wersja_github.txt"
del /q "%temp%\wersja_github.txt" >nul 2>&1

if "%ZDALNA_WERSJA%"=="" (
    set "STAT_NEW_VER=Błąd połączenia"
    echo [ INFO ] Brak połączenia z GitHubem. Przechodzę do aktualizacji systemu.
    echo.
    goto :MENU_STEROWNIKI
)

if not "%LOKALNA_WERSJA%"=="%ZDALNA_WERSJA%" (
    color 0E
    echo ===================================================
    echo [ UWAGA ] Znaleziono nową wersję skryptu (v%ZDALNA_WERSJA%).
    echo [ TRWA ] Autoupdate. Pobieranie nowej wersji...
    echo ===================================================
    curl -s "%GITHUB_BAT_RAW%" > "%temp%\update.bat"
    
    :: Mechanizm podmieniania samego siebie w locie
    echo @echo off > "%temp%\swap.bat"
    echo timeout /t 2 /nobreak ^>nul >> "%temp%\swap.bat"
    echo copy /Y "%temp%\update.bat" "%~f0" ^>nul >> "%temp%\swap.bat"
    echo start "" "%~f0" >> "%temp%\swap.bat"
    echo del "%temp%\update.bat" >> "%temp%\swap.bat"
    echo del "%%~f0" >> "%temp%\swap.bat"
    
    start "" "%temp%\swap.bat"
    exit
) else (
    set "STAT_NEW_VER=Aktualna (v%LOKALNA_WERSJA%)"
    echo [ OK ] Posiadasz najnowszą wersję skryptu.
    echo.
)

:MENU_STEROWNIKI
color 0A
echo ===================================================
echo  [ KONFIGURACJA ] AKTUALIZACJA STEROWNIKÓW
echo ===================================================
echo Czy chcesz aktualizować również sterowniki?
echo [ 1 ] TAK (Pełna aktualizacja [APLIKACJE + SYSTEM + STEROWNIKI])
echo [ 2 ] NIE (Tylko system - bezpieczniej [APLIKACJE + SYSTEM])
echo ===================================================
echo.
choice /c 12 /n /m "Wybór: "

if errorlevel 2 (
    set "INSTALUJ_STEROWNIKI=NIE"
    set "STAT_DRV=Pominięto"
    echo [ INFO ] Wybrano aktualizację BEZ sterowników.
) else (
    set "INSTALUJ_STEROWNIKI=TAK"
    set "STAT_DRV=Zainstalowano"
    echo [ INFO ] Wybrano pełną aktualizację.
)
echo.

:: --- KROK 0: WINGET ---
color 0A
echo ===================================================
echo  [ INFO ] WERYFIKACJA ŚRODOWISKA WINGET
echo ===================================================
powershell -NoProfile -Command "if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { exit 1 } else { exit 0 }"
if %errorlevel% equ 0 (
    set "STAT_WINGET=OK (Zainstalowany)"
) else (
    echo [ TRWA ] Instalacja Winget...
    powershell -NoProfile -Command "$url='https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'; Invoke-WebRequest -Uri $url -OutFile \"$env:TEMP\winget.msixbundle\"; Add-AppxPackage -Path \"$env:TEMP\winget.msixbundle\""
    set "STAT_WINGET=Zainstalowano teraz"
)
echo [ OK ] Status: %STAT_WINGET%
echo.

:: --- KROK 1: APKI ---
color 0A
echo ===================================================
echo  [ 1 / 3 ] AKTUALIZACJA APLIKACJI (WINGET)
echo ===================================================
winget source update >nul
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --silent
set "STAT_APPS=Zakończono"
echo [ OK ] Proces aktualizacji aplikacji zakończony.
echo.

:: --- KROK 2: WINDOWS UPDATE ---
color 0A
echo ===================================================
echo  [ 2 / 3 ] AKTUALIZACJA SYSTEMU WINDOWS
echo ===================================================
echo [ TRWA ] Inicjalizacja Windows Update...
if "%INSTALUJ_STEROWNIKI%"=="NIE" (
    set "PS_CMD=Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotCategory 'Drivers'"
) else (
    set "PS_CMD=Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot"
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null; Install-Module -Name PSWindowsUpdate -Force | Out-Null }; Import-Module PSWindowsUpdate; Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d -Confirm:$false -ErrorAction SilentlyContinue | Out-Null; %PS_CMD%"
set "STAT_SYS=OK"
echo [ OK ] Aktualizacja systemu zakończona.
echo.

:: --- KROK 3: SPRZĄTANIE ---
color 0A
echo ===================================================
echo  [ 3 / 3 ] OPTYMALIZACJA I CZYSZCZENIE
echo ===================================================
echo [ TRWA ] Czyszczenie plików tymczasowych...
del /q /f /s "%TEMP%\*" >nul 2>&1
echo [ TRWA ] Opróżnianie kosza...
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"
set "STAT_CLEANUP=OK"
echo [ OK ] Sprzątanie systemu zakończone.
echo.

:: --- FINALIZACJA ---
color 0A
echo ===================================================
echo  [ OK ] ZAKOŃCZONO WSZYSTKIE PROCESY
echo ===================================================
echo.
timeout /t 30

:: Raport graficzny
powershell -WindowStyle Hidden -Command "$start = Import-Clixml -Path \"$env:TEMP\script_start.xml\" -ErrorAction SilentlyContinue; $diff = (Get-Date) - $start; $timeStr = \"$($diff.Minutes) min. $($diff.Seconds) sek.\"; $msg = \"RAPORT AKTUALIZACJI PC`n====================================`n`n- Nowa wersja skryptu: %STAT_NEW_VER%`n- Środowisko Winget: %STAT_WINGET%`n- Aktualizacja aplikacji: %STAT_APPS%`n- Aktualizacja systemu: %STAT_SYS%`n- Aktualizacja sterowników: %STAT_DRV%`n- Sprzątanie systemu: %STAT_CLEANUP%`n`n====================================`n ŁĄCZNY CZAS: $timeStr`n====================================`n`nZalecane ponowne uruchomienie komputera.\"; Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($msg, 'Podsumowanie', 'OK', [System.Windows.Forms.MessageBoxIcon]::Information); Remove-Item -Path \"$env:TEMP\script_start.xml\" -ErrorAction SilentlyContinue"

:: Współautorzy: Gemini, Piotr M 🚂, Thundo
:: Wersja aplikacji: v1.1