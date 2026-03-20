# Auto Aktualizacja PC 🚂

Profesjonalny skrypt wsadowy (`.bat`) do kompleksowej automatyzacji konserwacji systemów Windows 10 oraz 11. Skrypt łączy potęgę menedżera pakietów **Winget** oraz modułu **PSWindowsUpdate**, aby utrzymać Twój komputer w najwyższej kondycji.

## 🌟 Kluczowe Funkcje

* **Inteligentne Sprawdzanie Wersji:** Przy każdym uruchomieniu skrypt sprawdza na GitHubie, czy dostępna jest nowsza wersja kodu. Jeśli tak – otrzymasz wybór: kontynuacja lub przejście do repozytorium.
* **Auto-Instalacja Środowiska:** Jeśli Twój system nie posiada narzędzia `winget` lub modułu `PSWindowsUpdate`, skrypt sam je pobierze i skonfiguruje.
* **Pełna Aktualizacja Softu:** Bezoobsługowo aktualizuje wszystkie aplikacje zainstalowane przez Winget (np. przeglądarki, odtwarzacze, narzędzia).
* **Głęboka Aktualizacja Systemu i Sterowników:** Dzięki wykorzystaniu PowerShell, skrypt wyszukuje i instaluje nie tylko łatki bezpieczeństwa, ale również **opcjonalne sterowniki urządzeń**.
* **Pomiar Czasu Pracy:** Po zakończeniu dowiesz się dokładnie, ile minut i sekund zajęła cała operacja.
* **Interaktywne Podsumowanie:** Po zamknięciu konsoli wyświetlane jest natywne okno systemowe z raportem wykonanych czynności.

## 🚀 Jak używać?

1.  Pobierz plik `Auto_Aktualizacja_PC.bat`.
2.  Uruchom plik **jako Administrator** (prawy przycisk myszy -> Uruchom jako administrator).
3.  Wybierz opcję w menu (jeśli pojawi się nowa wersja) i obserwuj postęp w zielonej konsoli.
4.  Po zakończeniu odczekaj 30 sekund lub naciśnij dowolny klawisz, aby zobaczyć podsumowanie.

## 🛠️ Wymagania Techniczne

* **System:** Windows 10 lub Windows 11.
* **Uprawnienia:** Skrypt wymaga uprawnień administracyjnych do instalacji sterowników i aplikacji.
* **Internet:** Niezbędny do pobierania aktualizacji i weryfikacji wersji na GitHub.

## 📊 Standardy i Zgodność

* **Dostępność:** Skrypt i jego komunikaty są zgodne z wytycznymi **EAA** i **WCAG** (obsługa przez czytniki ekranu, natywne okna dialogowe).
* **Responsywność:** Konsola i komunikaty przygotowane pod kątem czytelności na małych ekranach.

---
**Autorzy:** [Piotr M 🚂](https://github.com/piotrrgw) & Gemini AI  
**Wersja aplikacji:** v1.1