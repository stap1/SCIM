# SCIM - Audyt techniczny

**Rola:** Principal Software Architect · **Data:** 2026-06-08 · **Zakres:** autorski kod logiki (`scripts/`, `shaders/`, `test/`) + dokumentacja `.md`
**Baza odniesienia:** HYBRYDA (decyzja operatora) - kod as-built jest bazą; wybrane wzorce z `SCIM_TECH_SPEC.md` wdrażamy per-przypadek; resztę spec aktualizujemy do as-built. Bez refaktoru działającego kodu na siłę.
**Status projektu w chwili audytu:** kompletny (kroki 1-22), web-build działa, **87 testów GUT zielonych**, 4 testy regresji aktywne. Zero błędów krytycznych.

---

## 0. Metodyka

Priorytety audytu (malejąco): **#1** Clean Code/czytelność · **#2** dokumentacja w kodzie · **#3** zgodność implementacja↔`.md` · **#4** wydajność (setki obiektów + Web) · **#5** bezpieczeństwo/błędy · **#6** rozszerzalność.

Zignorowano (poza zakresem): `.godot/`, `assets/`, `art/`, `audio/`, `addons/gut/`, pliki `.uid`/`.import`.

Metryki: ~1421 linii logiki (20 plików `.gd`) + 19 linii shadera; ~844 linii testów (25 plików).

---

## 1. Cross-reference dokumentacja ↔ kod

**Kluczowe ustalenie:** `SCIM_TECH_SPEC.md` (oznaczony "kontrakt v1.0") opisuje **inną architekturę** niż zbudowano. Implementacja konsekwentnie podąża za `SCIM-blueprint.md` / `CLAUDE.md`. Rozstrzygnięcie hybrydowe:

| Wzorzec z TECH_SPEC | Werdykt |
|---|---|
| `GameConfig` (jedno źródło balansu) | ✅ wdrożyć |
| `EnemyBase` (class_name, dziedziczenie) | ✅ wdrożyć |
| Nazwane warstwy kolizji | ✅ wdrożyć |
| `max_level` ulepszeń | ✅ wdrożyć |
| Audio OGG | ✅ wdrożyć |
| Input Map (zamiast sztywnych klawiszy) | ✅ wdrożyć |
| `EventBus` (osobny autoload) | ❌ odrzucić - sygnały na GameState + grupy wystarczają |
| `player_hp`/`damage_player`, `reset_state`, score/s, `.tres` upgrade'y, eco/Trash | ❌ zaktualizować spec do as-built |

---

## 2. Wyniki per moduł

### E1 - Rdzeń stanu (`game_state.gd`)
- 🟢 Jedyne źródło prawdy; statyczne typowanie; guard one-shot `game_over`; `while` w `add_xp` (wiele awansów); `xp_threshold` czysta+testowana; brak kosztu per-klatka.
- 🔴 Kruchy kontrakt `reset()` (mieszane pola sesja/ustawienia → `eco_score` nieresetowany); martwy `eco_score`; brak `GameConfig` (rozsiany balans); niespójna jednostka `session_length` (minuty vs spec sekundy).
- → AI: rozdzielić stan sesja/ustawienia + docstring `reset()`; usunąć `eco_score`; wydzielić `GameConfig`; ujednolicić jednostkę.

### E2 - Pętla bojowa (`boat.gd`, `harpoon.gd`, `harpoon_pool.gd`, `auto_attacker.gd`)
- 🟢 Pooling poprawny (deaktywacja, brak GC spike); `find_nearest` czysta+testowana z `is_instance_valid`; i-frames/cooldown; null-guardy; auto-atak wydzielony do `AutoAttacker`.
- 🔴 `boat.gd` to god-object (~8 odpowiedzialności); **nienazwane warstwy kolizji** (magic numbers w 5 scenach); polling UI amunicji w `_process` (60×/s); podwójna ścieżka kontakt-damage; sztywne klawisze (brak Input Map/mobile); stały `contact_damage` (ignoruje typ wroga); martwa gałąź `get_parent()` w harpunie.
- → AI: nazwane warstwy; Input Map; odchudzić `boat.gd` (amunicja event-driven, jedna ścieżka damage); per-wróg contact_damage; sprzątanie.

### E3 - Wrogowie i spawn (`enemy.gd`, `motor_boat.gd`, `enemy_spawner.gd`, `xp_orb.gd`)
- 🟢 Wydajność ograniczona (cap 30 + `mask=0` → `move_and_slide` bez kolizji); trudność data-driven (`difficulty_curve` + `current_tier` czysta); czysty przepływ śmierci (particle do current_scene).
- 🔴 **Orby XP bez capa/lifetime/cleanupu** → kumulacja per-klatka w długiej sesji (spec §16 wprost ostrzega); **duplikacja `enemy.gd`↔`motor_boat.gd`** (brak `EnemyBase`); boss bez telegrafu szarży; podwójna ścieżka zbierania orba.
- → AI: cap/lifetime orbów (PRIORYTET); `EnemyBase`; telegraf bossa; jedna ścieżka zbierania.

### E4 - Progresja / upgrade'y (`upgrades.gd`, `level_up.gd`)
- 🟢 `apply_*` czyste+testowane; `pick_three` czysta (Fisher-Yates, deterministyczna); karty z jedynego źródła `Upgrades.UPGRADES`; węzły przez grupy.
- 🔴 Dodanie ulepszenia = 3 miejsca (nie w pełni data-driven); **brak `max_level`** → nieograniczone stackowanie (degeneracja `faster_attack`→0); `pick_three` nie filtruje wyczerpanych.
- → AI: `max_level` + filtr; data-driven `apply()` (effect_type/value).

### E5 - UI / ekrany (`hud.gd`, `main_menu.gd`, `settings.gd`, `game_over.gd`, `scores.gd`)
- 🟢 **HUD wzorowo read-only** (CLAUDE #2, regresja #4); pauza poprawna (`ALWAYS`, odpauzowanie przed reload); defensywne `get_node_or_null`; `game_over` z pełnymi statystykami + count-up.
- 🔴 Duplikat formatu czasu (`format_time`/`_format_time`); rozsiane magic-stringi ścieżek scen; funkcje accessibility w skrypcie ekranu UI (gameplay→UI coupling); **brak paska XP/poziomu na HUD**.
- → AI: pasek XP/poziom; neutralny moduł accessibility/persystencji; `const` ścieżek scen; dedup czasu.

### E6 - Audio i persystencja (`audio_manager.gd`, `highscores.gd`, persystencja `settings.gd`)
- 🟢 **Obsługa błędów wzorowa** (graceful fallback SFX, `_bus_or_master`, obsługa braku pliku - lepsza niż litera spec); SFX pool round-robin; `insert_score` czysta+testowana; `user://`→IndexedDB.
- 🔴 Audio **WAV, nie OGG** (web/rozmiar); coupling system→skrypt ekranu UI (persystencja w `settings.gd`); niewpięta muzyka (`play_music`/`crossfade` martwe); `highscores.get_top` bez walidacji typu wczytanych danych.
- → AI: OGG; neutralny `SettingsStore`; dokończyć/wyciąć muzykę; walidacja `is Array`.

### E7 - Efekty / polish / orkiestracja (`death_burst.gd`, `water.gdshader`, `main.gd`)
- 🟢 **Wzorowo web-friendly** (CPUParticles2D, tani shader, brak Thread/MP4, auto-free particli); `main.gd` cienki (wiring w scenie); regresja #4 utrzymana (`add_time`).
- 🟡 `main._ready` częściowy/over-defensive reset (vs `GameState.reset()` wywołującego); magic number 1.5s w `death_burst`.
- → AI: ujednolicić reset; drobne porządki.

### E8 - Architektura testów (`test/*`)
- 🟢 87 testów; **4 testy regresji obecne i nienaruszone**; doskonałe testy czystych funkcji; dobre wzorce GUT (`watch_signals`, `add_child_autofree`, `wait_physics_frames`, `before_each` reset).
- 🔴 **Smoke płytkie** - `is_instance_valid` zawsze prawdziwe; runtime `SCRIPT ERROR` NIE oblewa testu (error-scan poza CI); luki pokrycia (`scores`, kontroler `game_over`, koniec sesji).
- → AI: twardy error-scan w CI; pokrycie kontrolerów; wydzielić `should_end_session`.

---

## 3. Podział właścicielski (klucz: GFX→Stanisław, SFX→Mateusz, reszta→programowanie)

### 🎨 GFX - Stanisław
- **G1** Docelowe sprite'y: barracuda, shark, mini-boss MotorBoat, orb XP (dziś placeholdery: meduza+modulate / `lodz.svg` / `icon.svg`).
- **G2** Ikony kart ulepszeń.
- **G3** Docelowy art wody (prawdziwy noise/tekstura w shaderze).
- **G4** Wizualny telegraf szarży bossa (błysk/reflektor).

### 🔊 SFX - Mateusz
- **S1** Konwersja `audio/sfx/*.wav` → OGG (web).
- **S2** Brakujące SFX: hit, level_up, game_over, boss_spawn (dziś ciche placeholdery).
- **S3** Muzyka: menu/gra + boss theme (pod `crossfade`).

### 💻 Programowanie - cała reszta (backlog poniżej).

---

## 4. Backlog priorytetyzowany

**P0 - stabilność / realny defekt**
| # | Zadanie | Etap | Właśc. | Prio (#) |
|---|---|---|---|---|
| ✅ P0.1 | ~~Cap/lifetime orbów XP~~ **WYKONANE** - `xp_orb.lifetime` (12 s, niezebrane orby znikają) + test | E3 | PROG | #4 #5 |
| ✅ P0.2 | ~~Twardy error-scan w CI~~ **WYKONANE** - `tools/run_checks.ps1` (lokalnie) + `.github/workflows/ci.yml` (GUT + grep runtime errors, fail na `SCRIPT ERROR`) | E8 | PROG | #5 |

**P1 - wysoka wartość (hybryda + balans + czytelność)**
| # | Zadanie | Etap | Właśc. | Prio |
|---|---|---|---|---|
| ✅ P1.1 | ~~Nazwane warstwy kolizji~~ **WYKONANE** - `[layer_names]` (player/enemy/harpoon/pickup) + harpun/orb na własnych warstwach + strażniki testowe | E2 | PROG | #1 #4 |
| P1.2 | `max_level` ulepszeń + filtr `pick_three` | E4 | PROG | #6 |
| P1.3 | `GameConfig` (jedno źródło balansu) | E1 | PROG | #3 |
| P1.4 | `EnemyBase` (usuń duplikację enemy↔boss) | E3 | PROG | #1 #6 |
| P1.5 | Neutralny `SettingsStore`/accessibility (usuń coupling gameplay/audio→UI) | E5 E6 | PROG | #1 #6 |
| P1.6 | Czytelność stanu: rozdz. sesja/ustawienia + reset + usunięcie `eco_score` | E1 E7 | PROG | #1 #6 |

**P2 - jakość / rozszerzalność / UX**
| # | Zadanie | Etap | Właśc. | Prio |
|---|---|---|---|---|
| P2.1 | Odchudzić `boat.gd` (amunicja event-driven, jedna ścieżka damage) | E2 | PROG | #1 #4 |
| P2.2 | Input Map (mobile) | E2 | PROG | #6 |
| P2.3 | Data-driven `apply()` ulepszeń | E4 | PROG | #6 |
| P2.4 | Per-wróg `contact_damage` | E2 E3 | PROG | #6 |
| P2.5 | Pasek XP + poziom na HUD (wiring) | E5 | PROG (+G styl) | #6 |
| P2.6 | Pokrycie testów: `game_over` kontroler, `scores`, `should_end_session` | E8 | PROG | #2 |
| P2.7 | Wpięcie muzyki (`play_music`/`crossfade` na boss_incoming) | E6 | PROG (←S3) | #1 |
| P2.8 | Boss: maszyna stanów + telegraf szarży (logika) | E3 | PROG (+G4) | #1 #6 |
| P2.9 | Walidacja wczytanych high scores (`is Array`) | E6 | PROG | #5 |

**P3 - kosmetyka / dokumentacja**
| # | Zadanie | Etap | Właśc. | Prio |
|---|---|---|---|---|
| P3.1 | Porządki: martwa gałąź harpuna, dual-collect orba, dedup `format_time`, `const` ścieżek scen, `death_burst` lifetime | E2 E5 E7 | PROG | #1 |
| P3.2 | Aktualizacja `SCIM_TECH_SPEC.md` do as-built (brak EventBus/eco/Trash, health API, dict upgrade'y, OGG-plan) | wszystkie | PROG-doc | #2 #3 |
| P3.3 | Drobne liczby: pool 20→30, SFX pool 8→16 | E2 E6 | PROG | #3 |

---

## 5. Werdykt

- **Stan ogólny: zdrowy.** Kompletny, działający, web-build OK, 87 testów + 4 regresje zielone. **Zero błędów krytycznych.**
- **Najmocniejsze:** rdzeń `GameState` (single source), HUD read-only, pooling/targeting, obsługa błędów audio/persystencji (lepsza niż spec), warstwa efektów web-friendly, dyscyplina czystych funkcji + testów.
- **Najważniejszy dług:** (1) ✅ kumulacja orbów XP (P0.1), (2) ✅ error-scan w CI (P0.2), (3) ✅ nienazwane warstwy kolizji (P1.1), (4) brak `max_level` (P1.2 - następne). Pozostaje P1.2-P1.6 + P2/P3.
- **Dokumentacja:** pogodzić TECH_SPEC z rzeczywistością (wdrożyć GameConfig/EnemyBase/named-layers/max_level/OGG/InputMap; resztę zaktualizować do as-built; EventBus odrzucić).
- **Kolejność prac:** P0 → P1 → P2 → P3, każda zmiana z testem, utrzymać 4 testy regresji, po każdej GUT + error-scan zielone.

---

## 6. Testy regresji (NIE usuwać przez cały projekt)

| # | Pilnuje | Plik(i) |
|---|---|---|
| 1 | Wskaźnik głównej sceny (= MainMenu od kroku 20) | `test_project_config.gd` |
| 2 | Guard `is_dying` (enemy + boss) | `test_enemy_death_guard.gd`, `test_boss.gd` |
| 3 | `game_over` emitowany dokładnie raz | `test_game_over_once.gd`, `test_game_over.gd` |
| 4 | Brak liczenia czasu w HUD (czas tylko w `main.add_time`) | `test_hud_no_time_increment.gd` |

---

*Audyt 9-etapowy (E0-E9). Dokument żywy - aktualizować przy realizacji backlogu (oznaczać pozycje jako wykonane, dopisywać nowe długi).*
