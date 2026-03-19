@echo off
color 0A

:: Ustawienia wersji skryptu (do weryfikacji z GitHubem)
set "LOKALNA_WERSJA=1.0"
set "GITHUB_URL=https://raw.githubusercontent.com/piotrrgw/auto_aktualizacja_pc/main/wersja.txt"

:: Sprawdzenie uprawnien administratora
net session >nul 2>&1
if errorlevel 1 (
    color 0C
    echo ===================================================
    echo [BLAD] Brak uprawnien administratora!
    echo Kliknij ten plik prawym przyciskiem myszy i wybierz:
    echo "Uruchom jako administrator".
    echo ===================================================
    pause
    exit
)

echo ===================================================
echo     Skrypt Aktualizacyjny (Winget + Windows Update)
echo ===================================================
echo.

:: ---------------------------------------------------
:: SPRAWDZANIE AKTUALIZACJI SKRYPTU NA GITHUB
:: ---------------------------------------------------
echo Sprawdzanie dostepnosci nowszej wersji skryptu...
curl -s "%GITHUB_URL%" > "%temp%\wersja_github.txt"
set /p ZDALNA_WERSJA=<"%temp%\wersja_github.txt"
del /q "%temp%\wersja_github.txt" >nul 2>&1

if "%ZDALNA_WERSJA%"=="" (
    echo [INFO] Brak polaczenia z GitHubem lub bledny link.
) else if not "%LOKALNA_WERSJA%"=="%ZDALNA_WERSJA%" (
    color 0E
    echo.
    echo ===================================================
    echo [UWAGA] DOSTEPNA JEST NOWA WERSJA SKRYPTU!
    echo ===================================================
    echo Wersja lokalna: %LOKALNA_WERSJA%
    echo Wersja zdalna:  %ZDALNA_WERSJA%
    echo.
    echo Pobierz najnowsza wersje z repozytorium na GitHubie.
    echo ===================================================
    echo.
    pause
    color 0A
) else (
    echo [OK] Posiadasz najnowsza wersje skryptu ^(%LOKALNA_WERSJA%^).
)
echo.

:: ---------------------------------------------------
:: KROK 1: ODSWIEZANIE REPOZYTORIOW
:: ---------------------------------------------------
echo.
echo ===================================================
echo  [ 1 / 3 ] ODSWIEZANIE LIST REPOZYTORIOW (WINGET)
echo ===================================================
echo.
winget source update
echo.

:: ---------------------------------------------------
:: KROK 2: AKTUALIZACJA APLIKACJI
:: ---------------------------------------------------
echo.
echo ===================================================
echo  [ 2 / 3 ] BEZOBSLUGOWA AKTUALIZACJA APLIKACJI
echo ===================================================
echo.
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --silent
echo.

:: ---------------------------------------------------
:: KROK 3: WYSZUKIWANIE AKTUALIZACJI WINDOWS
:: ---------------------------------------------------
echo.
echo ===================================================
echo  [ 3 / 3 ] WYSZUKIWANIE AKTUALIZACJI WINDOWS
echo ===================================================
echo (To moze potrwac od kilkunastu sekund do kilku minut...)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$Session = New-Object -ComObject Microsoft.Update.Session; $Searcher = $Session.CreateUpdateSearcher(); $Result = $Searcher.Search('IsInstalled=0 and Type=''Software'' and IsHidden=0'); if ($Result.Updates.Count -eq 0) { Write-Host 'Brak nowych aktualizacji.' } else { Write-Host 'Znaleziono nastepujace pakiety:' -ForegroundColor Yellow; foreach($u in $Result.Updates){ Write-Host (' - ' + $u.Title) } }"
echo.

:: ---------------------------------------------------
:: KROK 4: INSTALACJA WINDOWS UPDATE W TLE
:: ---------------------------------------------------
echo.
echo ===================================================
echo    URUCHAMIANIE INSTALACJI WINDOWS UPDATE W TLE
echo ===================================================
echo.
UsoClient.exe ScanInstallWait
echo.

echo ===================================================
echo                     ZAKONCZONO
echo ===================================================
pause