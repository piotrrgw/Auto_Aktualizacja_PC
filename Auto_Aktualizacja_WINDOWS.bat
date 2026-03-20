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
set "GITHUB_REPO_URL=https://github.com/piotrrgw/auto_aktualizacja_pc"

:: Statusy domyslne
set "STAT_WINGET=Oczekiwanie..."
set "STAT_APPS=Oczekiwanie..."
set "STAT_SYS=Oczekiwanie..."
set "STAT_DRV=Pominieto"
set "STAT_NEW_VER=Sprawdzanie..."

:: ---------------------------------------------------
:: SPRAWDZANIE UPRAWNIEN ADMINISTRATORA
:: ---------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ===================================================
    echo [ BLAD ] Brak uprawnien administratora!
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
:: WERYFIKACJA WERSJI SKRYPTU NA GITHUB
:: ---------------------------------------------------
echo [ INFO ] Sprawdzanie dostepnosci nowszej wersji skryptu...
curl -s "%GITHUB_URL_RAW%" > "%temp%\wersja_github.txt"
set /p ZDALNA_WERSJA=<"%temp%\wersja_github.txt"
del /q "%temp%\wersja_github.txt" >nul 2>&1

if "%ZDALNA_WERSJA%"=="" (
    set "STAT_NEW_VER=Blad polaczenia"
    echo [ INFO ] Brak polaczenia z GitHubem.
    echo.
    goto :MENU_STEROWNIKI
)

if "%LOKALNA_WERSJA%"=="%ZDALNA_WERSJA%" (
    set "STAT_NEW_VER=Aktualna (v%LOKALNA_WERSJA%)"
    echo [ OK ] Posiadasz najnowsza wersje skryptu.
    echo.
    goto :MENU_STEROWNIKI
)

set "STAT_NEW_VER=Dostepna v%ZDALNA_WERSJA%"
color 0E
echo ===================================================
echo [ UWAGA ] DOSTEPNA JEST NOWA WERSJA SKRYPTU! (v%ZDALNA_WERSJA%)
echo ===================================================
echo [ 1 ] Kontynuuj aktualizacje (obecna wersja)
echo [ 2 ] Otworz GitHuba i zakoncz
echo ===================================================
echo.
choice /c 12 /n /m "Wybor: "
if errorlevel 2 (
    start %GITHUB_REPO_URL%
    exit
)
color 0A
echo [ INFO ] Kontynuowanie pracy z wersja %LOKALNA_WERSJA%...
echo.

:MENU_STEROWNIKI
color 0A
echo ===================================================
echo  [ KONFIGURACJA ] AKTUALIZACJA STEROWNIKOW
echo ===================================================
echo Czy chcesz aktualizowac rowniez sterowniki?
echo [ 1 ] TAK (Pelna aktualizacja [APLIKACJE + SYSTEM + STEROWNIKI])
echo [ 2 ] NIE (Tylko system - bezpieczniej [APLIKACJE + SYSTEM])
echo ===================================================
echo.
choice /c 12 /n /m "Wybor: "

if errorlevel 2 (
    set "INSTALUJ_STEROWNIKI=NIE"
    set "STAT_DRV=Pominieto"
    echo [ INFO ] Wybrano aktualizacje BEZ sterownikow.
) else (
    set "INSTALUJ_STEROWNIKI=TAK"
    set "STAT_DRV=Zainstalowano"
    echo [ INFO ] Wybrano pelna aktualizacje.
)
echo.

:: --- KROK 0: WINGET ---
color 0A
echo ===================================================
echo  [ INFO ] WERYFIKACJA SRODOWISKA WINGET
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
echo  [ 1 / 2 ] AKTUALIZACJA APLIKACJI (WINGET)
echo ===================================================
winget source update >nul
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --silent
set "STAT_APPS=Zakonczono"
echo [ OK ] Proces aktualizacji aplikacji zakonczony.
echo.

:: --- KROK 2: WINDOWS UPDATE ---
color 0A
echo ===================================================
echo  [ 2 / 2 ] AKTUALIZACJA SYSTEMU WINDOWS
echo ===================================================
echo [ TRWA ] Inicjalizacja Windows Update...
if "%INSTALUJ_STEROWNIKI%"=="NIE" (
    set "PS_CMD=Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotCategory 'Drivers'"
) else (
    set "PS_CMD=Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot"
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null; Install-Module -Name PSWindowsUpdate -Force | Out-Null }; Import-Module PSWindowsUpdate; Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d -Confirm:$false -ErrorAction SilentlyContinue | Out-Null; %PS_CMD%"
set "STAT_SYS=OK"
echo [ OK ] Aktualizacja systemu zakonczona.
echo.

:: --- FINALIZACJA ---
color 0A
echo ===================================================
echo  [ OK ] ZAKONCZONO WSZYSTKIE PROCESY
echo ===================================================
echo.
timeout /t 30

:: Raport graficzny (poprawiona skladnia)
powershell -WindowStyle Hidden -Command "$start = Import-Clixml -Path \"$env:TEMP\script_start.xml\" -ErrorAction SilentlyContinue; $diff = (Get-Date) - $start; $timeStr = \"$($diff.Minutes) min. $($diff.Seconds) sek.\"; $msg = \"RAPORT AKTUALIZACJI PC`n====================================`n`n- Nowa wersja skryptu: %STAT_NEW_VER%`n- Srodowisko Winget: %STAT_WINGET%`n- Aktualizacja aplikacji: %STAT_APPS%`n- Aktualizacja systemu: %STAT_SYS%`n- Aktualizacja sterownikow: %STAT_DRV%`n`n====================================`n LACZNY CZAS: $timeStr`n====================================`n`nZalecane ponowne uruchomienie komputera.\"; Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($msg, 'Podsumowanie', 'OK', [System.Windows.Forms.MessageBoxIcon]::Information); Remove-Item -Path \"$env:TEMP\script_start.xml\" -ErrorAction SilentlyContinue"

:: Footer: Piotr M 🚂 & Gemini | Wersja aplikacji: v1.1