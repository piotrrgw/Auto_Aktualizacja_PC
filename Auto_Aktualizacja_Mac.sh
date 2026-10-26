#!/bin/zsh

# ==============================================================================
#   SKRYPT AKTUALIZACYJNY MACOS (Homebrew + Mac App Store + Apple Software)
#   Autor: Piotr M 🚂 & Gemini
# ==============================================================================

# --- KONFIGURACJA ---
LOKALNA_WERSJA="1.2"
GITHUB_URL_RAW="https://raw.githubusercontent.com/piotrrgw/auto_aktualizacja_pc/main/wersja_mac.txt"
GITHUB_REPO_URL="https://github.com/piotrrgw/auto_aktualizacja_pc"

# Kolory terminala
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Zmienne procesowe
SUDO_KEEP_ALIVE_PID=""
CAFF_PID=""

# Funkcja czyszcząca procesy w tle przy wyjściu (Ctrl+C / EXIT / błąd)
cleanup() {
    [[ -n "$SUDO_KEEP_ALIVE_PID" ]] && kill "$SUDO_KEEP_ALIVE_PID" 2>/dev/null
    [[ -n "$CAFF_PID" ]] && kill "$CAFF_PID" 2>/dev/null
}
trap cleanup EXIT INT TERM

# Inicjalizacja Homebrew w PATH (dla Apple Silicon oraz procesorów Intel)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

autoload -Uz is-at-least

# ------------------------------------------------------------------------------
# 1. OBSŁUGA ARGUMENTÓW WIERSZA POLECEŃ (CLI FLAGS)
# ------------------------------------------------------------------------------
CLI_MODE=false
WYBOR=""

pokaz_pomoc() {
    printf "${GREEN}Uzycie: ./Auto_Aktualizacja_Mac.sh [OPCJA]${NC}\n\n"
    printf "Dostepne opcje:\n"
    printf "  -a, --all      Pelna aktualizacja (Homebrew + Mac App Store + System)\n"
    printf "  -p, --apps     Tylko aplikacje (Homebrew + Mac App Store)\n"
    printf "  -s, --system   Tylko system Apple (softwareupdate)\n"
    printf "  -h, --help     Wyswietla te pomoc\n\n"
    printf "Uruchomienie bez parametrow wlacza menu interaktywne.\n"
    exit 0
}

case "$1" in
    --all|-a)
        WYBOR="1"
        CLI_MODE=true
        ;;
    --apps|-p)
        WYBOR="2"
        CLI_MODE=true
        ;;
    --system|-s)
        WYBOR="3"
        CLI_MODE=true
        ;;
    --help|-h)
        pokaz_pomoc
        ;;
    "")
        # Tryb interaktywny
        ;;
    *)
        printf "${RED}[ BLAD ] Nieznana opcja: %s${NC}\n\n" "$1"
        pokaz_pomoc
        ;;
esac

if [[ "$CLI_MODE" == false ]]; then
    clear
fi

printf "${GREEN}===================================================${NC}\n"
printf "${GREEN}   SKRYPT AKTUALIZACYJNY MACOS (Brew + Apple)      ${NC}\n"
printf "${GREEN}   Wersja: v%s                                     ${NC}\n" "$LOKALNA_WERSJA"
printf "${GREEN}===================================================${NC}\n\n"

# ------------------------------------------------------------------------------
# 2. SPRAWDZANIE AKTUALNOSCI SKRYPTU NA GITHUBIE
# ------------------------------------------------------------------------------
printf "${CYAN}[ INFO ] Sprawdzanie aktualnosci skryptu...${NC}\n"
ZDALNA_WERSJA=$(curl -fsSL --connect-timeout 4 --max-time 6 "$GITHUB_URL_RAW" 2>/dev/null | tr -d '\r\n[:space:]')

if [[ -n "$ZDALNA_WERSJA" ]]; then
    if ! is-at-least "$ZDALNA_WERSJA" "$LOKALNA_WERSJA"; then
        printf "${YELLOW}===================================================${NC}\n"
        printf "${YELLOW}[ UWAGA ] Dostepna jest nowa wersja skryptu: v%s (obecna: v%s)${NC}\n" "$ZDALNA_WERSJA" "$LOKALNA_WERSJA"
        printf "${YELLOW}===================================================${NC}\n"
        if [[ "$CLI_MODE" == false ]]; then
            printf "  [ 1 ] Kontynuuj prace z biezaca wersja\n"
            printf "  [ 2 ] Otworz GitHub w przegladarce i zakoncz\n"
            printf "Wybierz opcje [1/2]: "
            read -k 1 VER_ACTION
            printf "\n\n"
            if [[ "$VER_ACTION" == "2" ]]; then
                open "$GITHUB_REPO_URL"
                exit 0
            fi
        fi
    else
        printf "${GREEN}[ OK ] Posiadasz najnowsza wersje skryptu (v%s).${NC}\n\n" "$LOKALNA_WERSJA"
    fi
else
    printf "${YELLOW}[ INFO ] Brak polaczenia z GitHubem lub brak pliku wersji.${NC}\n\n"
fi

# ------------------------------------------------------------------------------
# 3. INTERAKTYWNE MENU (Gdy brak argumentow CLI)
# ------------------------------------------------------------------------------
if [[ "$CLI_MODE" == false ]]; then
    printf "Wybierz zakres aktualizacji:\n"
    printf "  [ 1 ] Pelna aktualizacja (Aplikacje + System Apple)\n"
    printf "  [ 2 ] Tylko aplikacje (Homebrew + Mac App Store)\n"
    printf "  [ 3 ] Tylko system Apple (softwareupdate)\n"
    printf "  [ 4 ] Wyjscie\n"
    printf "===================================================\n"

    while true; do
        printf "Twoj wybor [1-4]: "
        read -k 1 WYBOR
        printf "\n"
        case "$WYBOR" in
            1|2|3|4) break ;;
            *) printf "${YELLOW}Niepoprawny wybor! Wpisz 1, 2, 3 lub 4.${NC}\n" ;;
        esac
    done

    if [[ "$WYBOR" == "4" ]]; then
        printf "${YELLOW}[ INFO ] Przerwano na zyczenie uzytkownika.${NC}\n"
        exit 0
    fi
fi

# ------------------------------------------------------------------------------
# 4. WERYFIKACJA ZASILANIA (BATERIA VS ZASILACZ)
# ------------------------------------------------------------------------------
sprawdz_zasilanie() {
    local batt_output
    batt_output=$(pmset -g batt 2>/dev/null)
    if echo "$batt_output" | grep -q "InternalBattery"; then
        local percent
        percent=$(echo "$batt_output" | grep -Eo "[0-9]{1,3}%" | head -n1 | tr -d "%")
        if echo "$batt_output" | grep -q "Battery Power"; then
            if [[ -n "$percent" && "$percent" -lt 50 ]]; then
                printf "\n${YELLOW}===================================================${NC}\n"
                printf "${YELLOW}[ OSTRZEZENIE ] Niski poziom baterii: %s%%!${NC}\n" "$percent"
                printf "${YELLOW}Aktualizacja systemu przy niskim stanie baterii bez${NC}\n"
                printf "${YELLOW}ladowarki moze uszkodzic system w razie rozladowania.${NC}\n"
                printf "${YELLOW}Zalecane podlaczenie zasilacza (MagSafe / USB-C).${NC}\n"
                printf "${YELLOW}===================================================${NC}\n"
                if [[ "$CLI_MODE" == false ]]; then
                    printf "Czy na pewno chcesz kontynuowac na baterii? [t/N]: "
                    read -k 1 CONT_BATT
                    printf "\n\n"
                    if [[ ! "$CONT_BATT" =~ ^[tTyY]$ ]]; then
                        printf "${RED}[ ANULOWANO ] Podlacz zasilacz i sprobuj ponownie.${NC}\n"
                        exit 1
                    fi
                fi
            else
                printf "${CYAN}[ INFO ] Zasilanie z baterii (%s%%).${NC}\n" "$percent"
            fi
        else
            printf "${GREEN}[ INFO ] Zasilacz sieciowy podlaczony (Bateria: %s%%).${NC}\n" "$percent"
        fi
    fi
}

if [[ "$WYBOR" == "1" || "$WYBOR" == "3" ]]; then
    sprawdz_zasilanie
fi

# ------------------------------------------------------------------------------
# 5. OCHRONA PRZED UŚPIENIEM (caffeinate) & START POMIARU CZASU
# ------------------------------------------------------------------------------
START_TIME=$(date +%s)
STAT_BREW="Pominieto"
STAT_MAS="Pominieto"
STAT_SYS="Pominieto"
REBOOT_REQUIRED=false

# Aktywacja ochrony przed uśpieniem ekranu i systemu w trakcie trwania skryptu
caffeinate -dims -w $$ &
CAFF_PID=$!
printf "${CYAN}[ INFO ] Aktywowano ochrone przed uspieniem komputera (caffeinate).${NC}\n"

# ------------------------------------------------------------------------------
# 6. UZYSKANIE I PODTRZYMANIE UPRAWNIEN SUDO
# ------------------------------------------------------------------------------
if [[ "$WYBOR" == "1" || "$WYBOR" == "3" ]]; then
    printf "\n${YELLOW}[ INFO ] Aktualizacja systemu wymaga uprawnien administratora.${NC}\n"
    printf "Podaj haslo (jesli zostaniesz o nie poproszony):\n"
    if sudo -v; then
        # Pętla odświeżająca token sudo co 60 sekund w tle
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        SUDO_KEEP_ALIVE_PID=$!
    else
        printf "${RED}[ BLAD ] Nie udalo sie uzyskac uprawnien sudo. Pomijanie aktualizacji systemu.${NC}\n"
        STAT_SYS="Blad autoryzacji"
    fi
fi

# ------------------------------------------------------------------------------
# 7. PROCES HOMEBREW + MAC APP STORE
# ------------------------------------------------------------------------------
if [[ "$WYBOR" == "1" || "$WYBOR" == "2" ]]; then
    printf "\n${BLUE}===================================================${NC}\n"
    printf "${BLUE}   [ 1 ] AKTUALIZACJA APLIKACJI (Homebrew)         ${NC}\n"
    printf "${BLUE}===================================================${NC}\n"

    # Sprawdzenie obecności Homebrew
    if ! command -v brew &> /dev/null; then
        printf "${YELLOW}[ INFO ] Homebrew nie zostal znaleziony w systemie.${NC}\n"
        if [[ "$CLI_MODE" == false ]]; then
            printf "Czy chcesz zainstalowac Homebrew automatycznie? [t/N]: "
            read -k 1 INST_BREW
            printf "\n"
        else
            INST_BREW="N"
        fi

        if [[ "$INST_BREW" =~ ^[tTyY]$ ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [[ -x "/opt/homebrew/bin/brew" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x "/usr/local/bin/brew" ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        fi
    fi

    if command -v brew &> /dev/null; then
        printf "${CYAN}[ TRWA ] Pobieranie bazy pakietow (brew update)...${NC}\n"
        brew update

        printf "\n${CYAN}[ TRWA ] Aktualizowanie formul i programow Cask (brew upgrade --greedy)...${NC}\n"
        if brew upgrade --greedy; then
            printf "\n${CYAN}[ TRWA ] Czyszczenie starych wersji i cache (brew cleanup)...${NC}\n"
            brew cleanup -s
            STAT_BREW="OK"
            printf "${GREEN}[ OK ] Aktualizacja Homebrew zakonczona pomyslnie.${NC}\n"
        else
            STAT_BREW="Ostrzezenie / Blad"
            printf "${YELLOW}[ UWAGA ] Czesc pakietow Homebrew mogla nie zostac zaktualizowana.${NC}\n"
        fi
    else
        STAT_BREW="Brak Homebrew"
        printf "${YELLOW}[ POMINIETO ] Brak Homebrew w systemie.${NC}\n"
    fi

    # Obsługa Mac App Store (narzędzie mas)
    printf "\n${BLUE}---------------------------------------------------${NC}\n"
    printf "${BLUE}   AKTUALIZACJA PROGRAMOW Z MAC APP STORE          ${NC}\n"
    printf "${BLUE}---------------------------------------------------${NC}\n"
    if command -v mas &> /dev/null; then
        OUTDATED_MAS=$(mas outdated 2>/dev/null)
        if [[ -n "$OUTDATED_MAS" ]]; then
            printf "${CYAN}[ INFO ] Wykryto aktualizacje w App Store:\n%s${NC}\n\n" "$OUTDATED_MAS"
            printf "${CYAN}[ TRWA ] Aktualizowanie aplikacji z App Store...${NC}\n"
            if mas upgrade; then
                STAT_MAS="OK"
                printf "${GREEN}[ OK ] Aplikacje z Mac App Store zaktualizowane.${NC}\n"
            else
                STAT_MAS="Blad"
                printf "${RED}[ BLAD ] Wystapil problem z aktualizacja App Store.${NC}\n"
            fi
        else
            STAT_MAS="Brak (Najnowsze)"
            printf "${GREEN}[ OK ] Wszystkie aplikacje z Mac App Store sa aktualne.${NC}\n"
        fi
    else
        STAT_MAS="Brak mas-cli"
        printf "${YELLOW}[ INFO ] Narzedzie 'mas' nie jest zainstalowane.${NC}\n"
        printf "       (Zainstaluj przez: 'brew install mas', aby obslugiwac App Store)\n"
    fi
fi

# ------------------------------------------------------------------------------
# 8. PROCES SYSTEMOWY APPLE (softwareupdate)
# ------------------------------------------------------------------------------
if [[ ("$WYBOR" == "1" || "$WYBOR" == "3") && "$STAT_SYS" != "Blad autoryzacji" ]]; then
    printf "\n${BLUE}===================================================${NC}\n"
    printf "${BLUE}   [ 2 ] AKTUALIZACJA SYSTEMU OPERACYJNEGO APPLE   ${NC}\n"
    printf "${BLUE}===================================================${NC}\n"
    printf "${CYAN}[ TRWA ] Wyszukiwanie i instalowanie aktualizacji macOS...${NC}\n"

    SW_LOG=$(sudo softwareupdate -i -a --verbose 2>&1 | tee /dev/tty)
    SW_STATUS=$?

    if [[ $SW_STATUS -eq 0 ]]; then
        STAT_SYS="OK"
        if echo "$SW_LOG" | grep -qi "restart"; then
            REBOOT_REQUIRED=true
        fi
        printf "${GREEN}[ OK ] Proces aktualizacji systemu Apple zakonczony.${NC}\n"
    else
        STAT_SYS="Blad / Anulowano"
        printf "${RED}[ BLAD ] softwareupdate zakonczyl sie kodem bledu: %s${NC}\n" "$SW_STATUS"
    fi
fi

# ------------------------------------------------------------------------------
# 9. PODSUMOWANIE I RAPORT
# ------------------------------------------------------------------------------
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

if [[ "$REBOOT_REQUIRED" == true ]]; then
    REBOOT_INFO="WYMAGANY (Zrestartuj komputer)"
else
    REBOOT_INFO="Niewymagany"
fi

printf "\n${GREEN}===================================================${NC}\n"
printf "${GREEN}   [ OK ] ZAKONCZONO WSZYSTKIE WYBRANE PROCESY     ${NC}\n"
printf "${GREEN}===================================================${NC}\n"
printf " Podsumowanie:\n"
printf "   - Homebrew:       %s\n" "$STAT_BREW"
printf "   - Mac App Store:  %s\n" "$STAT_MAS"
printf "   - System Apple:   %s\n" "$STAT_SYS"
printf "   - Czas trwania:   %d min. %d sek.\n" "$MINUTES" "$SECONDS"
printf "   - Status restartu:%s\n" "$REBOOT_INFO"
printf "${GREEN}===================================================${NC}\n\n"

# Powiadomienie systemowe (Banner)
osascript -e "display notification \"Czas: ${MINUTES}m ${SECONDS}s | Restart: ${REBOOT_INFO}\" with title \"Aktualizacja Maca\" subtitle \"Procesy zakonczone\"" 2>/dev/null || true

# Okno modalne z podsumowaniem (automatycznie zamyka się po 90 sekundach)
REPORT_TEXT="RAPORT AKTUALIZACJI MAC\n==============================\n• Homebrew: $STAT_BREW\n• Mac App Store: $STAT_MAS\n• System Apple: $STAT_SYS\n\nCzas pracy: ${MINUTES} min. ${SECONDS} sek.\nRestart: $REBOOT_INFO\n=============================="

osascript -e "display dialog \"$REPORT_TEXT\" with title \"Podsumowanie Aktualizacji\" buttons {\"OK\"} default button \"OK\" with icon note giving up after 90" 2>/dev/null || true

# Footer: Piotr M 🚂 & Gemini | Wersja: v1.2