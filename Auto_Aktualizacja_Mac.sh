#!/bin/zsh

# --- KONFIGURACJA ---
LOKALNA_WERSJA="1.1"
GITHUB_URL_RAW="https://raw.githubusercontent.com/piotrrgw/auto_aktualizacja_pc/main/wersja.txt"
GITHUB_SH_RAW="https://raw.githubusercontent.com/piotrrgw/auto_aktualizacja_pc/main/Auto_Aktualizacja_Mac.sh"

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

# 1. Sprawdzanie wersji i Self-Updating
echo -e "[ INFO ] Sprawdzanie aktualności skryptu..."
ZDALNA_WERSJA=$(curl -s "$GITHUB_URL_RAW")

if [[ -n "$ZDALNA_WERSJA" && "$LOKALNA_WERSJA" != "$ZDALNA_WERSJA" ]]; then
    echo -e "${YELLOW}[ UWAGA ] Trwa pobieranie nowej wersji skryptu ($ZDALNA_WERSJA)...${NC}\n"
    curl -s "$GITHUB_SH_RAW" > "$0"
    chmod +x "$0"
    exec "$0" "$@" # Przeładowanie skryptu w locie
fi

# 2. Wybór zakresu
echo -e "Co chcesz zaktualizować?"
echo -e "[ 1 ] Wszystko (Aplikacje + System + Sprzątanie)"
echo -e "[ 2 ] Tylko system Apple"
echo -e "==================================================="
read -k 1 "WYBOR? "
echo -e "\n\n"

# 3. Proces Homebrew (BEZ SUDO)
if [[ "$WYBOR" == "1" ]]; then
    echo -e "${GREEN}[ 1 / 3 ] AKTUALIZACJA APLIKACJI (Homebrew)${NC}"
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}[ INFO ] Instalowanie Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    brew update
    brew upgrade
    STAT_BREW="Zaktualizowano"
    echo -e "${GREEN}[ OK ] Aplikacje zaktualizowane.${NC}\n"
else
    STAT_BREW="Pominięto"
fi

# 4. Proces Systemowy (Z SUDO)
echo -e "${GREEN}[ 2 / 3 ] AKTUALIZACJA SYSTEMU APPLE${NC}"
echo -e "${YELLOW}[ INFO ] Może być wymagane hasło administratora...${NC}"
sudo softwareupdate -i -a --verbose
STAT_SYS="Zaktualizowano"
echo -e "${GREEN}[ OK ] Proces systemowy zakończony.${NC}\n"

# 5. Oczyszczanie systemu (Cleanup)
echo -e "${GREEN}[ 3 / 3 ] OPTYMALIZACJA I CZYSZCZENIE${NC}"
if [[ "$WYBOR" == "1" && command -v brew &> /dev/null ]]; then
    echo -e "${YELLOW}[ INFO ] Czyszczenie pamięci podręcznej Homebrew...${NC}"
    brew cleanup
fi
echo -e "${YELLOW}[ INFO ] Opróżnianie kosza systemowego...${NC}"
rm -rf ~/.Trash/*
STAT_CLN="Zakończono"
echo -e "${GREEN}[ OK ] Czyszczenie zakończone.${NC}\n"

# Koniec pomiaru czasu
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# 6. Raport końcowy
echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}   [ OK ] ZAKOŃCZONO WSZYSTKIE PROCESY             ${NC}"
echo -e "${GREEN}===================================================${NC}"

# Wyświetlenie graficznego okna raportu na macOS
REPORT="RAPORT AKTUALIZACJI MAC\n======================\n\n- Homebrew: $STAT_BREW\n- System Apple: $STAT_SYS\n- Sprzątanie systemu: $STAT_CLN\n\nCZAS PRACY: $MINUTES min. $SECONDS sek.\n======================\n\nZalecane ponowne uruchomienie."

osascript -e "display dialog \"$REPORT\" with title \"Podsumowanie\" buttons {\"OK\"} default button \"OK\" with icon note"

# Współautorzy: Gemini, Piotr M 🚂, Thundo
# Wersja aplikacji: v1.1