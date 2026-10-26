@echo off
setlocal enabledelayedexpansion
:: Ustawienie koloru na starcie
color 0A

:: ---------------------------------------------------
:: SPRAWDZANIE UPRAWNIEN ADMINISTRATORA I MONIT UAC
:: ---------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    color 0E
    echo ===================================================
    echo [ INFO ] Wymagane uprawnienia administratora.
    echo [ INFO ] Wywolywanie monitu autoryzacji [UAC]...
    echo ===================================================
    set "CURRENT_BAT=%~f0"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process cmd.exe -ArgumentList '/c', $env:CURRENT_BAT -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
    if errorlevel 1 (
        color 0C
        echo.
        echo ===================================================
        echo [ BLAD ] Nie udzielono uprawnien administratora!
        echo          Uruchom skrypt jako administrator.
        echo ===================================================
        echo.
        pause
    )
    exit /b
)
cd /d "%~dp0"

:: ---------------------------------------------------
:: INICJALIZACJA POMIARU CZASU
:: ---------------------------------------------------
powershell -NoProfile -Command "Get-Date | Export-Clixml -Path $env:TEMP\script_start.xml"

:: Ustawienia wersji i repozytorium
set "LOKALNA_WERSJA=1.2"
set "GITHUB_URL_RAW=https://raw.githubusercontent.com/piotrrgw/auto_aktualizacja_pc/main/wersja.txt"
set "GITHUB_REPO_URL=https://github.com/piotrrgw/auto_aktualizacja_pc"

:: Statusy domyslne
set "STAT_RESTORE=Pominieto"
set "STAT_WINGET=Oczekiwanie..."
set "STAT_APPS=Oczekiwanie..."
set "STAT_WSL=Pominieto"
set "STAT_SYS=Oczekiwanie..."
set "STAT_DRV=Pominieto"
set "STAT_CLEANUP=Pominieto"
set "STAT_NEW_VER=Sprawdzanie..."

echo ===================================================
echo   SKRYPT AKTUALIZACYJNY (Winget + Windows Update)
echo ===================================================
echo.

:: ---------------------------------------------------
:: WERYFIKACJA WERSJI SKRYPTU NA GITHUB
:: ---------------------------------------------------
echo [ INFO ] Sprawdzanie dostepnosci nowszej wersji skryptu...
set "ZDALNA_WERSJA="
curl -s "%GITHUB_URL_RAW%" > "%temp%\wersja_github.txt"
if exist "%temp%\wersja_github.txt" (
    set /p ZDALNA_WERSJA=<"%temp%\wersja_github.txt"
    del /q "%temp%\wersja_github.txt" >nul 2>&1
)

if "%ZDALNA_WERSJA%"=="" (
    set "STAT_NEW_VER=Blad polaczenia"
    echo [ INFO ] Brak polaczenia z GitHubem.
    echo.
    goto :MENU_OPCJE
)

if "%LOKALNA_WERSJA%"=="%ZDALNA_WERSJA%" (
    set "STAT_NEW_VER=Aktualna v%LOKALNA_WERSJA%"
    echo [ OK ] Posiadasz najnowsza wersje skryptu.
    echo.
    goto :MENU_OPCJE
)

set "STAT_NEW_VER=Dostepna v%ZDALNA_WERSJA%"
color 0E
echo ===================================================
echo [ UWAGA ] DOSTEPNA JEST NOWA WERSJA SKRYPTU! v%ZDALNA_WERSJA%
echo ===================================================
echo [ 1 ] Kontynuuj aktualizacje [obecna wersja]
echo [ 2 ] Otworz GitHuba i zakoncz
echo ===================================================
echo.
choice /c 12 /n /m "Wybor: "
if errorlevel 2 (
    start %GITHUB_REPO_URL%
    exit /b
)
color 0A
echo [ INFO ] Kontynuowanie pracy z wersja %LOKALNA_WERSJA%...
echo.

:MENU_OPCJE
color 0A
echo ===================================================
echo  [ KONFIGURACJA ] WYBOR OPCJI PRACY SKRYPTU
echo ===================================================
echo [ 1 / 2 ] Czy chcesz aktualizowac rowniez sterowniki?
echo [ 1 ] TAK [Pelna aktualizacja: Aplikacje + System + Sterowniki]
echo [ 2 ] NIE [Tylko system - bezpieczniej: Aplikacje + System]
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
    echo [ INFO ] Wybrano pelna aktualizacje ze sterownikami.
)
echo.

echo ===================================================
echo [ 2 / 2 ] Czy po aktualizacji wykonac czyszczenie systemu?
echo         [Oproznienie Kosza, Temp, pamiec Winget, DISM]
echo [ 1 ] TAK [Zalecane - zwolnij miejsce na dysku]
echo [ 2 ] NIE [Pomin czyszczenie]
echo ===================================================
echo.
choice /c 12 /n /m "Wybor: "

if errorlevel 2 (
    set "WYKONAJ_CZYSZCZENIE=NIE"
    set "STAT_CLEANUP=Pominieto"
    echo [ INFO ] Czyszczenie systemu zostanie pominiete.
) else (
    set "WYKONAJ_CZYSZCZENIE=TAK"
    set "STAT_CLEANUP=Oczekuje"
    echo [ INFO ] Czyszczenie systemu zostanie wykonane na koncu.
)
echo.

:: --- KROK 1: PUNKT PRZYWRACANIA ---
color 0A
echo ===================================================
echo  [ 1 / 5 ] TWORZENIE PUNKTU PRZYWRACANIA SYSTEMU
echo ===================================================
echo [ TRWA ] Tworzenie punktu przywracania [limit czasu: 5 minut]...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; $timeoutSec = 300; $job = Start-Job -ScriptBlock { Checkpoint-Computer -Description 'Przed Auto Aktualizacja PC' -RestorePointType 'APPLICATION_INSTALL' -ErrorAction Stop }; $elapsed = 0; while (($job.State -eq 'Running') -and ($elapsed -lt $timeoutSec)) { Start-Sleep -Seconds 5; $elapsed += 5 }; if ($job.State -eq 'Running') { Stop-Job $job -ErrorAction SilentlyContinue; Remove-Job $job -Force -ErrorAction SilentlyContinue; exit 2 }; if ($job.State -eq 'Completed') { Remove-Job $job -Force -ErrorAction SilentlyContinue; exit 0 } else { Remove-Job $job -Force -ErrorAction SilentlyContinue; exit 1 }"
if !errorlevel! equ 0 (
    set "STAT_RESTORE=Utworzono"
    echo [ OK ] Punkt przywracania zostal pomyslnie utworzony.
) else if !errorlevel! equ 2 (
    set "STAT_RESTORE=Pominieto - limit 5 min"
    echo [ OSTRZEZENIE ] Przekroczono limit czasu 5 minut [usluga VSS nie odpowiedziala].
    echo                Punkt przywracania pominiety, kontynuowanie pracy...
) else (
    set "STAT_RESTORE=Pominieto / Brak ochrony"
    echo [ INFO ] Punkt przywracania pominiety [ochrona systemu moze byc wylaczona].
)
echo.

:: --- KROK 2: WINGET ---
color 0A
echo ===================================================
echo  [ 2 / 5 ] AKTUALIZACJA APLIKACJI [WINGET]
echo ===================================================
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    set "STAT_WINGET=OK - Zainstalowany"
) else (
    echo [ TRWA ] Instalacja Winget...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; try { $url='https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'; Invoke-WebRequest -Uri $url -OutFile \"$env:TEMP\winget.msixbundle\" -ErrorAction Stop; Add-AppxPackage -Path \"$env:TEMP\winget.msixbundle\" -ErrorAction Stop; Remove-Item \"$env:TEMP\winget.msixbundle\" -ErrorAction SilentlyContinue; exit 0 } catch { exit 1 }"
    if !errorlevel! equ 0 (
        set "STAT_WINGET=Zainstalowano teraz"
    ) else (
        set "STAT_WINGET=Blad instalacji"
        echo [ OSTRZEZENIE ] Nie udalo sie zainstalowac Winget.
    )
)

if "!STAT_WINGET!"=="Blad instalacji" (
    set "STAT_APPS=Pominieto - brak Winget"
    echo [ POMINIETO ] Brak dostepnego srodowiska Winget.
) else (
    echo [ TRWA ] Odswiezanie zrodel pakietow Winget...
    winget source update >nul 2>&1
    echo [ TRWA ] Aktualizowanie aplikacji...
    winget upgrade --all --accept-package-agreements --accept-source-agreements --silent
    if !errorlevel! equ 0 (
        set "STAT_APPS=Zaktualizowano"
    ) else if !errorlevel! equ -1978335189 (
        set "STAT_APPS=Brak aktualizacji"
    ) else if !errorlevel! equ 2316632085 (
        set "STAT_APPS=Brak aktualizacji"
    ) else (
        set "STAT_APPS=Zakonczono"
    )
    echo [ OK ] Proces aktualizacji aplikacji zakonczony.
)
echo.

:: --- KROK 3: WSL (WINDOWS SUBSYSTEM FOR LINUX) ---
color 0A
echo ===================================================
echo  [ 3 / 5 ] AKTUALIZACJA PODSYSTEMU WSL [LINUX]
echo ===================================================
where wsl >nul 2>&1
if %errorlevel% equ 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=0; while ((Get-Process msiexec -ErrorAction SilentlyContinue) -and ($c -lt 8)) { Start-Sleep -Seconds 1; $c++ }"
    echo [ TRWA ] Aktualizacja jadra podsystemu WSL...
    wsl --update
    if !errorlevel! equ 0 (
        set "STAT_WSL=Zaktualizowano"
        echo [ OK ] Podsystem WSL jest aktualny.
    ) else (
        set "STAT_WSL=Zakonczono"
        echo [ INFO ] Zakonczono sprawdzanie WSL.
    )
) else (
    set "STAT_WSL=Niezainstalowany"
    echo [ INFO ] Podsystem WSL nie jest zainstalowany.
)
echo.

:: --- KROK 4: WINDOWS UPDATE ---
color 0A
echo ===================================================
echo  [ 4 / 5 ] AKTUALIZACJA SYSTEMU WINDOWS
echo ===================================================
echo [ TRWA ] Inicjalizacja Windows Update...
if "%INSTALUJ_STEROWNIKI%"=="NIE" (
    set "PS_CMD=Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotCategory 'Drivers'"
) else (
    set "PS_CMD=Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot"
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null; Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue; Install-Module -Name PSWindowsUpdate -Force | Out-Null }; Import-Module PSWindowsUpdate; Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d -Confirm:$false -ErrorAction SilentlyContinue | Out-Null; %PS_CMD%; exit 0 } catch { exit 1 }"
if !errorlevel! equ 0 (
    set "STAT_SYS=OK"
) else (
    set "STAT_SYS=Blad aktualizacji"
)
echo.
echo [ OK ] Aktualizacja systemu zakonczona.
echo.

:: --- KROK 5: CZYSZCZENIE SYSTEMU I DYSKU ---
color 0A
echo ===================================================
echo  [ 5 / 5 ] CZYSZCZENIE I OPTYMALIZACJA DYSKU
echo ===================================================
if "%WYKONAJ_CZYSZCZENIE%"=="TAK" (
    echo [ TRWA ] Oproznianie Kosza...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"

    echo [ TRWA ] Czyszczenie pamieci podrecznej DNS...
    ipconfig /flushdns >nul 2>&1

    echo [ TRWA ] Czyszczenie plikow tymczasowych...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'script_start.xml' } | ForEach-Object { try { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop } catch {} }"

    echo [ TRWA ] Oczyszczanie bazy komponentow Windows [DISM]...
    echo          To moze potrwac od 3 do 10 minut w zaleznosci od dysku...
    dism.exe /online /Cleanup-Image /StartComponentCleanup

    set "STAT_CLEANUP=Wykonano"
    echo [ OK ] Czyszczenie systemu zakonczone pomyslnie.
) else (
    set "STAT_CLEANUP=Pominieto"
    echo [ INFO ] Czyszczenie systemu zostalo pominiete.
)
echo.

:: --- FINALIZACJA ---
color 0A
echo ===================================================
echo  [ OK ] ZAKONCZONO WSZYSTKIE PROCESY
echo ===================================================
echo.
echo Za chwile wyswietli sie okno z podsumowaniem...
timeout /t 5 >nul

:: Raport graficzny z wykrywaniem potrzeby restartu
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "Add-Type -AssemblyName System.Windows.Forms; $start = Import-Clixml -Path \"$env:TEMP\script_start.xml\" -ErrorAction SilentlyContinue; $diff = if ($start) { (Get-Date) - $start } else { [TimeSpan]::Zero }; $timeStr = \"$($diff.Minutes) min. $($diff.Seconds) sek.\"; $isReboot = $false; try { Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue; $s = Get-WURebootStatus -Silent -ErrorAction SilentlyContinue; if ($s) { $isReboot = [bool]$s.RebootRequired } } catch {}; if (-not $isReboot) { if ((Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending')) { $isReboot = $true } }; if ($isReboot) { 'REBOOT_REQUIRED' | Out-File -FilePath \"$env:TEMP\reboot_status.txt\" -Encoding ascii }; $rebootMsg = if ($isReboot) { 'TAK (Wymagany restart systemu!)' } else { 'NIE' }; $icon = if ($isReboot) { [System.Windows.Forms.MessageBoxIcon]::Warning } else { [System.Windows.Forms.MessageBoxIcon]::Information }; $rebootAdvice = if ($isReboot) { 'Zalecane PONOWNE URUCHOMIENIE komputera.' } else { 'Ponowne uruchomienie nie jest wymagane.' }; $msg = \"RAPORT AKTUALIZACJI PC`n====================================`n`n- Nowa wersja skryptu: %STAT_NEW_VER%`n- Punkt przywracania: %STAT_RESTORE%`n- Srodowisko Winget: %STAT_WINGET%`n- Aktualizacja aplikacji: %STAT_APPS%`n- Aktualizacja WSL: %STAT_WSL%`n- Aktualizacja systemu: %STAT_SYS%`n- Aktualizacja sterownikow: %STAT_DRV%`n- Czyszczenie systemu: %STAT_CLEANUP%`n- Wymagany restart: $rebootMsg`n`n====================================`n LACZNY CZAS: $timeStr`n====================================`n`n$rebootAdvice\"; [System.Windows.Forms.MessageBox]::Show($msg, 'Podsumowanie aktualizacji', 'OK', $icon); Remove-Item -Path \"$env:TEMP\script_start.xml\" -ErrorAction SilentlyContinue"

:: Inteligentny monit o restart na zyczenie
if exist "%temp%\reboot_status.txt" (
    del /q "%temp%\reboot_status.txt" >nul 2>&1
    color 0E
    echo ===================================================
    echo  [ UWAGA ] SYSTEM WYMAGA PONOWNEGO URUCHOMIENIA!
    echo ===================================================
    echo Czy chcesz zrestartowac komputer teraz?
    echo [ 1 ] TAK [Restart za 60 sekund - czas na zapisanie pracy]
    echo [ 2 ] NIE [Zrestartuje pozniej recznie]
    echo ===================================================
    echo.
    choice /c 12 /n /m "Wybor: "
    if errorlevel 2 (
        echo [ INFO ] Restart odlozony na pozniej. Pamietaj o ponownym uruchomieniu!
    ) else (
        echo [ INFO ] Inicjalizacja restartu za 60 sekund...
        shutdown /r /t 60 /c "Automatyczny restart po aktualizacji systemu Windows."
        echo [ INFO ] Mozesz anulowac restart poleceniem: shutdown /a
    )
    echo.
)

color 0A
echo ===================================================
echo  Nacisnij dowolny klawisz, aby zamknac to okno...
echo ===================================================
pause >nul

:: Footer: Piotr M 🚂 & Gemini | Wersja aplikacji: v1.2
