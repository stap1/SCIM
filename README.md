# ⚓ Stary Człowiek i Morze (SCIM)

**SCIM** to gra typu *top-down survival auto-shooter* inspirowana *Vampire Survivors*, tworzona w silniku **Godot 4** (GDScript, statyczne typowanie). Sterujesz łodzią starego rybaka, która automatycznie atakuje najbliższych morskich wrogów harpunem. Przetrwaj falę, zbieraj XP, wybieraj ulepszenia i pokonaj mini-bossa - motorówkę kłusownika.

---

## 🎮 Sterowanie
- **Ruch:** WSAD lub strzałki.
- **Atak:** automatyczny (harpun celuje w najbliższego wroga w zasięgu).
- **Awans:** zbieraj orby XP - po awansie wybierz 1 z 3 kart ulepszeń.
- Menu i ekrany obsługiwane myszką.

## ✨ Mechaniki
- 3 typy wrogów (meduza, barakuda, rekin) + mini-boss z szarżą i paskiem HP.
- Krzywa trudności rosnąca z czasem.
- 6 ulepszeń (szybszy atak, zasięg, kadłub, prędkość, magnes XP, podwójny harpun).
- HUD (czas/HP/wynik/amunicja), ekran wyników z high scores (top 5), ustawienia.
- Accessibility: ograniczenie trzęsienia ekranu i migania.

---

## 🛠️ Specyfikacja techniczna
- **Silnik:** Godot 4.6 (Forward+ / GDScript).
- **Platformy docelowe:** Web (HTML5) + PC (Windows).
- **Architektura:** `GameState` jako jedyne źródło prawdy o stanie sesji; sceny luźno powiązane przez sygnały i grupy; logika testowalna wydzielona do czystych funkcji.
- **Testy:** GUT (Godot Unit Test) w `res://test/`.

---

## 🚀 Jak uruchomić lokalnie
1. Sklonuj repozytorium.
2. Otwórz **Godot 4.6** -> Import -> wskaż `project.godot`.
3. Uruchom (**F5**). Scena startowa: `scenes/MainMenu.tscn`.

## ✅ Testy (headless)
Z katalogu projektu:
```
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://test -gexit
```

## 📦 Budowanie
1. W edytorze: **Project -> Export**. Jeśli brak szablonów: **Editor -> Manage Export Templates -> Download**.
2. Presety w `export_presets.cfg`: **Web** (HTML5) i **Windows Desktop**.
3. Web: upewnij się, że audio jest w **OGG** (mniejszy rozmiar; WAV też działa).
4. Eksport z linii poleceń, np.: `godot --headless --export-release "Web" builds/web/index.html`.

## 🔗 Linki
- itch.io: _(placeholder - link po wdrożeniu)_

---

Projekt edukacyjny prowadzony metodą TDD (Stanisław + Mateusz).
