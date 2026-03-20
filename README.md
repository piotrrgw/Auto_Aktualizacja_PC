# Auto Aktualizacja PC 🚂

Profesjonalny skrypt wsadowy (`.bat`) do kompleksowej automatyzacji konserwacji systemów Windows 10 oraz 11. Skrypt łączy potęgę menedżera pakietów **Winget** oraz modułu **PSWindowsUpdate**, aby utrzymać Twój komputer w najwyższej kondycji za pomocą jednego kliknięcia.

## 🌟 Kluczowe Funkcje

* **Inteligentna Weryfikacja Wersji:** Skrypt automatycznie sprawdza na GitHubie, czy dostępna jest nowsza wersja kodu. Masz wybór: kontynuować pracę lub przejść do repozytorium, by pobrać aktualizację.
* **Konfigurowalna Aktualizacja Sterowników:** Przed startem decydujesz, czy chcesz zaktualizować tylko system i aplikacje, czy również sterowniki urządzeń (opcja dla zaawansowanych).
* **Auto-Instalacja Środowiska:** Jeśli Twój system nie posiada narzędzia `winget` lub modułu `PSWindowsUpdate`, skrypt sam je bezpiecznie pobierze i skonfiguruje.
* **Pełna Aktualizacja Aplikacji:** Bezoobsługowo aktualizuje wszystkie programy wspierane przez Winget (przeglądarki, narzędzia, odtwarzacze).
* **Zaawansowane Windows Update:** Wykorzystuje PowerShell do instalacji poprawek systemowych oraz sterowników z kanału Microsoft Update.
* **Profesjonalny Raport Końcowy:** Po zakończeniu pracy wyświetlane jest natywne okno systemowe z podsumowaniem statusu każdego kroku oraz dokładnym czasem trwania operacji.

## 🚀 Jak używać?

1.  Pobierz plik `Auto_Aktualizacja_PC.bat`.
2.  Uruchom plik **jako Administrator** (wymagane do instalacji sterowników i łatek systemowych).
3.  Postępuj zgodnie z instrukcjami w zielonej konsoli (wybór wersji i zakresu aktualizacji).
4.  Po zakończeniu przejrzyj raport i zamknij okno.

## 🛠️ Specyfikacja Techniczna

* **System:** Windows 10 / 11
* **Język:** Batch + PowerShell
* **Zgodność:** Skrypt jest zgodny z wytycznymi **EAA** i **WCAG** (czytelność, standardowe okna komunikatów).
* **Optymalizacja:** Przygotowany do wyświetlania na ekranach o różnej rozdzielczości (responsywność konsoli).

## 📊 Statusy Raportu

W oknie podsumowania znajdziesz następujące informacje:
- **Nowa wersja skryptu:** Czy używasz najnowszego kodu.
- **Środowisko Winget:** Status gotowości menedżera pakietów.
- **Aktualizacja aplikacji:** Czy proces Winget zakończył się sukcesem.
- **Aktualizacja systemu:** Status instalacji łatek Windows.
- **Aktualizacja sterowników:** Informacja o wykonaniu lub pominięciu tego kroku.

---
**Autorzy:** [Piotr M 🚂](https://github.com/piotrrgw) & Gemini AI  
**Wersja aplikacji:** v1.1  
**Ostatnia aktualizacja:** 20.03.2026