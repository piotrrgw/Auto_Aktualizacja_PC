@echo off
color 0A

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

echo [1/3] Odswiezanie list repozytoriow (winget)...
winget source update
echo.

echo [2/3] Rozpoczynam bezobslugowa aktualizacje aplikacji...
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --silent
echo.

echo [3/3] Wyszukiwanie dostepnych aktualizacji Windows...
echo (To moze potrwac od kilkunastu sekund do kilku minut...)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$Session = New-Object -ComObject Microsoft.Update.Session; $Searcher = $Session.CreateUpdateSearcher(); $Result = $Searcher.Search('IsInstalled=0 and Type=''Software'' and IsHidden=0'); if ($Result.Updates.Count -eq 0) { Write-Host 'Brak nowych aktualizacji.' } else { Write-Host 'Znaleziono:' -ForegroundColor Yellow; foreach($u in $Result.Updates){ Write-Host (' - ' + $u.Title) } }"
echo.

echo Rozpoczynam instalacje Windows Update w tle...
UsoClient.exe ScanInstallWait
echo.

echo ===================================================
echo                     ZAKONCZONO
echo ===================================================
pause