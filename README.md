# ⚓ Stary Człowiek i Morze (SCIM)

**SCIM** to gra typu *top-down survival auto-shooter* inspirowana mechanikami *Vampire Survivors*, tworzona w silniku **Godot 4**. Gracz steruje łodzią starego rybaka, która automatycznie atakuje najbliższych morskich wrogów. Cel gry to przetrwanie fali trwającej określony czas.

---

## 🛠️ Specyfikacja Techniczna
- **Silnik:** Godot 4.6 (Forward+ / GDScript)
- **Platformy docelowe:** Web (HTML5) + PC (Windows)
- **Architektura:** Pełna separacja skryptów (`scripts/`) od scen wizualnych (`scenes/`).

---

## 📊 Aktualny Status Projektu: Koniec Dnia 4
Faza *Core Loop* (Główna pętla rozgrywki) została w pełni zamknięta pod kątem programistycznym. Projekt jest stabilny i przygotowany pod wdrożenie pełnej progresji RPG.

### 💻 Systemy zakodowane przez Mateusza (100% DONE):
- **Sterowanie i fizyka:** Płynny ruch WASD łodzi z uwzględnieniem wektorów przyspieszenia i tarcia wody.
- **Auto-atak:** Automatyczne namierzanie najbliższej meduzy i wystrzał harpuna (zablokowany Friendly Fire).
- **Object Pooling:** Optymalizacja pamięci – gra obraca w pętli stałą pulą 20 harpunów, eliminując użycie obciążającego procesor `queue_free()`.
- **Game Feel & Juice:** Dodano matematyczne bujanie łodzi na falach (`sin/cos`), efekty cząsteczek przy śmierci meduz oraz płynne wygaszanie ekranu Game Over przez `Tween`.
- **HUD:** Dynamiczne odświeżanie paska zdrowia oraz w pełni responsywny licznik dostępnej w puli amunicji.

### 🎨 Oczekujące assety od Stanisława (W TRAKCIE):
- **Wizualny pasek zdrowia:** Podmiana szarego prostokąta na dedykowany `TextureProgressBar`.
- **Dzień 5 (D5):** Przygotowanie grafiki i sceny dla nowego, szybkiego wroga (`Barracuda.tscn`) oraz ostylowanie wyskakujących cyferek obrażeń (*Damage Numbers*).
- **Dzień 6 (D6):** Przygotowanie grafik Rekina oraz Plastikowych Śmieci (przeszkoda wodna) oraz złożenie interfejsu ekranu ulepszeń (*Level-up UI*).

---

## 🚀 Jak uruchomić projekt lokalnie?
1. Sklonuj to repozytorium na swój dysk.
2. Otwórz program **Godot Engine 4** (wersja 4.6 lub nowsza).
3. Kliknij **Import** i wskaż plik `project.godot` w folderze głównym.
4. Uruchom główną scenę (`main.tscn`) za pomocą klawisza **F5**.
