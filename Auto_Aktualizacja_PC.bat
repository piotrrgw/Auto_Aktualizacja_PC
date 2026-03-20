@echo off
color 0A

:: ---------------------------------------------------
:: INICJALIZACJA POMIARU CZASU
:: ---------------------------------------------------
powershell -NoProfile -Command "Get-Date | Export-Clixml -Path $env:TEMP\script_start.xml"

:: Ustawienia wersji i repozytorium
set "LOKALNA_WERSJA=1.1"
set "GITHUB_URL_RAW=https://raw.githubusercontent.com/piotrrgw/auto_aktualizacja_pc/main/wersja.txt"
set "GITHUB_REPO_URL=https://github.com/piotrrgw/auto_aktualizacja_pc"

:: ---------------------------------------------------
:: SPRAWDZANIE UPRAWNIEN ADMINISTRATORA
:: ---------------------------------------------------
net session >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ===================================================
    echo [ BLAD ] Brak uprawnien administratora!
    echo          Kliknij ten plik prawym przyciskiem myszy
    echo          i wybierz "Uruchom jako administrator".
    echo ===================================================
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
    echo [ INFO ] Brak polaczenia z GitHubem lub bledny link.
    goto :START_PROCESU
)

if "%LOKALNA_WERSJA%"=="%ZDALNA_WERSJA%" (
    echo [ OK ] Posiadasz najnowsza wersje skryptu ^(%LOKALNA_WERSJA%^).
    goto :START_PROCESU
)

:: Sekcja jesli wykryto nowsza wersje
color 0E
echo.
echo ===================================================
echo [ UWAGA ] DOSTEPNA JEST NOWA WERSJA SKRYPTU!
echo ===================================================
echo Wersja lokalna: %LOKALNA_WERSJA%
echo Wersja zdalna:  %ZDALNA_WERSJA%
echo.
echo Co chcesz zrobic?
echo [ 1 ] Kontynuuj aktualizacje przy uzyciu obecnej wersji
echo [ 2 ] Otworz GitHuba i pobierz nowa wersje (zamyka skrypt)
echo ===================================================
echo.

choice /c 12 /n /m "Wybierz opcje [1,2]: "

if errorlevel 2 (
    start %GITHUB_REPO_URL%
    exit
)
color 0A
echo [ INFO ] Kontynuowanie pracy z wersja %LOKALNA_WERSJA%...

:START_PROCESU
echo.

:: ---------------------------------------------------
:: KROK 0: WERYFIKACJA SRODOWISKA WINGET
:: ---------------------------------------------------
echo ===================================================
echo  [ INFO ] WERYFIKACJA SRODOWISKA WINGET
echo ===================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Write-Host '[ TRWA ] Pobieranie i instalacja Winget (AppInstaller)...' -ForegroundColor Cyan; $url = 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'; $dest = \"$env:TEMP\winget.msixbundle\"; Invoke-WebRequest -Uri $url -OutFile $dest; Add-AppxPackage -Path $dest; Write-Host '[ OK ] Winget zostal pomyslnie zainstalowany.' -ForegroundColor Green } else { Write-Host '[ OK ] Winget jest zainstalowany i gotowy do dzialania.' -ForegroundColor Green }"
color 0A
echo.

:: ---------------------------------------------------
:: KROK 1: ODSWIEZANIE REPOZYTORIOW
:: ---------------------------------------------------
echo ===================================================
echo  [ 1 / 3 ] ODSWIEZANIE LIST REPOZYTORIOW (WINGET)
echo ===================================================
echo [ TRWA ] Pobieranie najnowszych informacji o pakietach...
winget source update
color 0A
echo [ OK ] Repozytoria zostaly zaktualizowane.
echo.

:: ---------------------------------------------------
:: KROK 2: AKTUALIZACJA APLIKACJI
:: ---------------------------------------------------
echo ===================================================
echo  [ 2 / 3 ] BEZOBSLUGOWA AKTUALIZACJA APLIKACJI
echo ===================================================
echo [ TRWA ] Instalacja dostepnych aktualizacji programow...
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --silent
color 0A
echo [ OK ] Proces aktualizacji aplikacji zakonczony.
echo.

:: ---------------------------------------------------
:: KROK 3: AKTUALIZACJA WINDOWS I STEROWNIKOW
:: ---------------------------------------------------
echo ===================================================
echo  [ 3 / 3 ] AKTUALIZACJA WINDOWS I STEROWNIKOW
echo ===================================================
echo [ INFO ] (Pierwsze uruchomienie moze potrwac dluzej ze wzgledu na instalacje odpowiednich modulow)
echo [ TRWA ] Inicjalizacja modulu PSWindowsUpdate i instalacja pakietow...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) { Write-Host '[ TRWA ] Instalacja modulu PSWindowsUpdate...' -ForegroundColor Cyan; Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null; Install-Module -Name PSWindowsUpdate -Force | Out-Null }; Import-Module PSWindowsUpdate; Write-Host '[ TRWA ] Wyszukiwanie i instalowanie aktualizacji (w tym sterownikow)...' -ForegroundColor Cyan; Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d -Confirm:$false -ErrorAction SilentlyContinue | Out-Null; Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot; Write-Host '[ OK ] Aktualizacja systemu zakonczona.' -ForegroundColor Green"
color 0A
echo.

:: ---------------------------------------------------
:: PODSUMOWANIE I ZAKONCZENIE
:: ---------------------------------------------------
echo ===================================================
echo  [ OK ] ZAKONCZONO WSZYSTKIE PROCESY
echo ===================================================
echo Okno zamknie sie automatycznie za 30 sekund...
timeout /t 30

:: Obliczenie czasu, wyswietlenie czytelnego okna z podsumowaniem i usuniecie pliku z czasem startu
powershell -WindowStyle Hidden -Command "$start = Import-Clixml -Path \"$env:TEMP\script_start.xml\" -ErrorAction SilentlyContinue; if ($start) { $diff = (Get-Date) - $start; $timeStr = '{0} min. {1} sek.' -f $diff.Minutes, $diff.Seconds } else { $timeStr = 'nieznany (blad pomiaru)' }; $msg = \"Proces aktualizacji zostal pomyslnie zakonczony.`n`nZaktualizowano:`n- Aplikacje zewnetrzne (Winget)`n- Pakiety systemu i opcjonalne sterowniki (Windows Update)`n`nCzas trwania aktualizacji: $timeStr`n`nW celu ukonczenia konfiguracji niektorych urzadzen zalecane jest ponowne uruchomienie komputera w wolnej chwili.\"; Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show($msg, 'Podsumowanie aktualizacji', 'OK', [System.Windows.Forms.MessageBoxIcon]::Information); Remove-Item -Path \"$env:TEMP\script_start.xml\" -ErrorAction SilentlyContinue"

:: Wersja aplikacji: v1.1
:: Piotr M 🚂 & Gemini