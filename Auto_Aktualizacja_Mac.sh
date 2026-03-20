#!/bin/zsh

# Wersja skryptu: v1.0
# Autorzy: Piotr M 🚂 & Gemini

# Kolory dla lepszej czytelnosci
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}   SKRYPT AKTUALIZACYJNY MACOS (Homebrew + Apple)  ${NC}"
echo -e "${GREEN}===================================================${NC}\n"

# 1. Sprawdzanie uprawnien (sudo)
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[ BLAD ] Uruchom skrypt z sudo (sudo ./nazwa_skryptu.sh)${NC}"
   exit 1
fi

# 2. Sprawdzanie i aktualizacja Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}[ INFO ] Homebrew nie jest zainstalowany. Instalowanie...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}[ OK ] Homebrew jest gotowy.${NC}"
fi

echo -e "\n${GREEN}[ 1 / 2 ] AKTUALIZACJA APLIKACJI (Homebrew)${NC}"
brew update
brew upgrade
brew cu --all --yes --cleanup # Wymaga rozszerzenia 'brew-cask-upgrade' dla apek graficznych
brew cleanup
echo -e "${GREEN}[ OK ] Aplikacje zaktualizowane.${NC}\n"

# 3. Aktualizacja systemu macOS
echo -e "${GREEN}[ 2 / 2 ] AKTUALIZACJA SYSTEMU APPLE${NC}"
echo -e "${YELLOW}[ TRWA ] Sprawdzanie dostepnych aktualizacji systemowych...${NC}"
softwareupdate -i -a --verbose
echo -e "${GREEN}[ OK ] Proces aktualizacji systemu zakonczony.${NC}\n"

echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}   [ OK ] ZAKONCZONO WSZYSTKIE PROCESY             ${NC}"
echo -e "${GREEN}===================================================${NC}"

# Powiadomienie systemowe (odpowiednik MessageBox)
osascript -e 'display notification "Wszystkie aplikacje i system zostały zaktualizowane." with title "Auto Aktualizacja Mac" sound name "Glass"'