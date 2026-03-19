# Auto Aktualizacja PC

Skrypt wsadowy (`.bat`) przeznaczony dla systemów Windows 10 i Windows 11, automatyzujący proces aktualizacji zainstalowanych programów oraz samego systemu operacyjnego.

## Funkcje skryptu

1. **Weryfikacja wersji:** Sprawdza na GitHubie, czy dostępna jest nowsza wersja samego skryptu.
2. **Odświeżanie repozytoriów:** Pobiera najnowsze listy pakietów z repozytoriów `winget`.
3. **Aktualizacja aplikacji:** Bezobsługowo i cicho aktualizuje wszystkie programy wspierane przez Menedżera pakietów systemu Windows (`winget`).
4. **Aktualizacja systemu:** Wyszukuje i instaluje aktualizacje Windows Update w tle przy użyciu natywnego narzędzia `UsoClient.exe`.

## Wymagania

* System operacyjny Windows 10 lub Windows 11.
* Aktywne połączenie z internetem.
* **Uprawnienia administratora** (skrypt weryfikuje je przy starcie i poprosi o ich nadanie w przypadku braku).

## Instalacja i uruchomienie

1. Pobierz plik `Auto_Aktualizacja_PC.bat` na swój komputer.
2. Kliknij plik prawym przyciskiem myszy i wybierz **Uruchom jako administrator**.
3. Reszta procesu przebiega automatycznie, a po jej zakończeniu skrypt zaczeka na wciśnięcie dowolnego klawisza przed zamknięciem okna.

## Mechanizm wersji (Informacja techniczna)

Skrypt weryfikuje swoją aktualność, sprawdzając zawartość pliku `wersja.txt` w głównym katalogu tego repozytorium. Jeśli numer pobrany z pliku tekstowego na GitHubie różni się od zmiennej `LOKALNA_WERSJA` zapisanej wewnątrz pliku `.bat`, użytkownik otrzyma powiadomienie w konsoli o dostępności nowej wersji do pobrania.

---
*Autorzy: Gemini oraz Piotr M 🚂*