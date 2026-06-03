#!/bin/zsh

# --- KONFIGURACJA ---
LOKALNA_WERSJA="1.1"
GITHUB_URL_RAW="https://raw.githubusercontent.com/piotrrgw/auto_aktualizacja_pc/main/wersja.txt"

# Kolory
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Start pomiaru czasu
START_TIME=$(date +%s)

clear
echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}   SKRYPT AKTUALIZACYJNY MACOS (Brew + Apple)      ${NC}"
echo -e "${GREEN}===================================================${NC}\n"

# 1. Sprawdzanie wersji
echo -e "[ INFO ] Sprawdzanie aktualnosci skryptu..."
ZDALNA_WERSJA=$(curl -s "$GITHUB_URL_RAW")

if [[ -n "$ZDALNA_WERSJA" && "$LOKALNA_WERSJA" != "$ZDALNA_WERSJA" ]]; then
    echo -e "${YELLOW}[ UWAGA ] Dostepna nowa wersja: $ZDALNA_WERSJA (Lokalna: $LOKALNA_WERSJA)${NC}\n"
fi

# 2. Wybor zakresu
echo -e "Co chcesz zaktualizowac?"
echo -e "[ 1 ] Wszystko (Aplikacje + System)"
echo -e "[ 2 ] Tylko system Apple"
echo -e "==================================================="
read -k 1 "WYBOR? "
echo -e "\n"

# 3. Proces Homebrew (BEZ SUDO)
if [[ "$WYBOR" == "1" ]]; then
    echo -e "${GREEN}[ 1 / 2 ] AKTUALIZACJA APLIKACJI (Homebrew)${NC}"
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}[ INFO ] Instalowanie Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    brew update
    brew upgrade
    brew cleanup
    STAT_BREW="OK"
    echo -e "${GREEN}[ OK ] Aplikacje zaktualizowane.${NC}\n"
else
    STAT_BREW="Pominieto"
fi

# 4. Proces Systemowy (Z SUDO)
echo -e "${GREEN}[ 2 / 2 ] AKTUALIZACJA SYSTEMU APPLE${NC}"
echo -e "${YELLOW}[ INFO ] Moze byc wymagane haslo administratora...${NC}"
sudo softwareupdate -i -a --verbose
STAT_SYS="OK"
echo -e "${GREEN}[ OK ] Proces systemowy zakonczony.${NC}\n"

# Koniec pomiaru czasu
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# 5. Raport koncowy
echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}   [ OK ] ZAKONCZONO WSZYSTKIE PROCESY             ${NC}"
echo -e "${GREEN}===================================================${NC}"

# Wyswietlenie graficznego okna raportu na macOS
REPORT="RAPORT AKTUALIZACJI MAC\n======================\n\n- Homebrew: $STAT_BREW\n- System Apple: $STAT_SYS\n\nCZAS PRACY: $MINUTES min. $SECONDS sek.\n======================\n\nZalecane ponowne uruchomienie."

osascript -e "display dialog \"$REPORT\" with title \"Podsumowanie\" buttons {\"OK\"} default button \"OK\" with icon note"

# Footer: Piotr M 🚂 & Gemini | Wersja: v1.1