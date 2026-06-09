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
| ✅ P1.2 | ~~`max_level` ulepszeń + filtr `pick_three`~~ **WYKONANE** - `max_level` per ulepszenie, `available_ids()` filtruje wyczerpane, reset na `session_reset`, anty-softlock | E4 | PROG | #6 |
| ✅ P1.3 | ~~`GameConfig` (jedno źródło balansu)~~ **WYKONANE** - autoload tylko-`const` (`scripts/globals/game_config.gd`), pierwszy w kolejce; `START_HEALTH`→`PLAYER_MAX_HP` + rozsiane literały (gracz/harpun/wróg/boss/XP/spawn) czytają z GameConfig; test wiringu `test_game_config.gd` (re-hardcode = oblany test) | E1 | PROG | #3 |
| ✅ P1.4 | ~~`EnemyBase` (usuń duplikację enemy↔boss)~~ **WYKONANE** - `class_name EnemyBase extends CharacterBody2D` (`scripts/systems/enemy_base.gd`); wspólne `health`/`is_dying`/`target`/`set_target`/`take_damage`/`die`/grupa `enemies` + haki `_on_health_changed`/`_on_death`; `enemy.gd` i `motor_boat.gd` dziedziczą, bazowe HP/score z GameConfig w `_init()`; guard `is_dying` jako regresja #2 w `test_enemy_base.gd` | E3 | PROG | #1 #6 |
| ✅ P1.5 | ~~Neutralny `SettingsStore`/accessibility (usuń coupling gameplay/audio→UI)~~ **WYKONANE** - autoload `scripts/globals/settings_store.gd` (po GameState, przed AudioManager) jest jedynym właścicielem trwałości (ConfigFile) + czystych funkcji (`slider_to_db`/`should_apply_shake`/`should_flash`/`save_settings`/`load_settings`) + `apply_saved()`/`apply_bus()`; `boat.gd`/`audio_manager.gd`/`level_up.gd` czytają z `SettingsStore` zamiast `preload`ować skrypt ekranu UI; `settings.gd` tylko buduje UI i deleguje; strażnik regresji w `test_settings_store.gd` (źródła gameplay/audio nie zawierają `scripts/ui/settings.gd`) | E5 E6 | PROG | #1 #6 |
| ✅ P1.6 | ~~Czytelność stanu: rozdz. sesja/ustawienia + reset + usunięcie `eco_score`~~ **WYKONANE** - `GameState` trzyma WYŁĄCZNIE stan sesji; ustawienia gracza (`session_length`/`reduce_shake`/`reduce_flashing`) przeniesione do `SettingsStore` (`session_length_min` + accessibility); martwy `eco_score` usunięty; jednostka sesji ujednolicona - setting w minutach + czysta funkcja `SettingsStore.session_seconds()` (jeden punkt konwersji min→s, koniec magicznego `*60` w `main.gd`); strażnik w `test_state_separation.gd` (pola ustawień nieobecne w GameState, obecne w SettingsStore) | E1 E7 | PROG | #1 #6 |

**P2 - jakość / rozszerzalność / UX**
| # | Zadanie | Etap | Właśc. | Prio |
|---|---|---|---|---|
| ✅ P2.1 | ~~Odchudzić `boat.gd` (amunicja event-driven, jedna ścieżka damage)~~ **WYKONANE** - licznik amunicji event-driven: `harpoon_pool` emituje `ammo_changed(available, total)` (harpun emituje `availability_changed` na fire/deactivate, pula re-emituje), HUD słucha i odświeża `AmmoLabel` (koniec pollingu 60×/s w `boat._process`; boat nie sięga już do puli/`ammo_ui`); jedna ścieżka damage - tylko polling Hurtboxa w `_physics_process` (usunięty `body_entered`/`_on_hurtbox_body_entered`); strażnik `test_ammo_event_driven.gd` | E2 | PROG | #1 #4 |
| ✅ P2.2 | ~~Input Map (mobile)~~ **WYKONANE** - sekcja `[input]` w `project.godot` z akcjami `move_up/down/left/right` (WSAD + strzałki, `physical_keycode` = niezależne od układu klawiatury); `boat.get_input_direction()` czyta akcje przez `Input.is_action_pressed` + czysta funkcja `direction_from_input(right,left,down,up)` (testowalna bez Input); umożliwia remap i sterowanie mobilne (przyciski dotykowe emitują te akcje); strażnik `test_input_map.gd` (akcje istnieją + bindy WSAD/strzałki + boat bez `is_key_pressed`) | E2 | PROG | #6 |
| ✅ P2.3 | ~~Data-driven `apply()` ulepszeń~~ **WYKONANE** - rejestr efektów `_effects` (id→Callable) budowany w `_ready` (`_build_effects`); `apply()` to generyczny dispatch (`_effects[id].call()`) - usunięte dwa twarde `match id` (zwykłe + milestone); zwykłe liczą poziom, milestone nie (kumulacja bez limitu); efekty rozbite na metody `_effect_*` (każda z własnym guardem); helpery `has_effect`/`effect_ids`; strażnik `test_upgrades_data_driven.gd` (katalog↔rejestr spójne, brak `match id`) | E4 | PROG | #6 |
| ✅ P2.4 | ~~Per-wróg `contact_damage`~~ **WYKONANE** - `contact_damage` jako `@export` w `EnemyBase` (baza `GameConfig.ENEMY_CONTACT_DAMAGE`; mini-boss nadpisuje `MINIBOSS_CONTACT_DAMAGE`=25 w `_init`); `boat._physics_process` czyta obrażenia z trafionego wroga przez `contact_damage_of(enemy)` (fallback `damage_per_hit`), `try_take_enemy_hit(damage)` parametryzowane; `_enemy_in_hurtbox()`→`_first_enemy_in_hurtbox()` (zwraca węzeł); obrażenia nadal WYŁĄCZNIE przez GameState + cooldown i-frames; strażnik `test_contact_damage.gd` | E2 E3 | PROG | #6 |
| ✅ P2.5 | ~~Pasek XP + poziom na HUD (wiring)~~ **WYKONANE** - `XPBar` (ProgressBar) + `LevelLabel` w `hud.tscn`; `hud.gd` read-only słucha `xp_changed`/`level_up` (jak health/time/score) + synchronizacja w `_ready`; czyste funkcje `xp_bar_values(xp, xp_to_next)` (pełny pasek na maksie, bez dzielenia przez zero) i `level_text(level)`; `GameState.reset()` inicjalizuje `xp_to_next = xp_threshold(level)` + emituje `xp_changed` (sensowna skala paska od startu); strażnik `test_hud_xp.gd` | E5 | PROG (+G styl) | #6 |
| ✅ P2.6 | ~~Pokrycie testów: `game_over` kontroler, `scores`, `should_end_session`~~ **WYKONANE** - wydzielone czyste funkcje + testy: `main.should_end_session(time, limit_sec)` (`test_session_end.gd`); `game_over.is_new_record(score, best)` + `best_text(best, is_record)` + smoke/wiring sceny (`test_game_over_controller.gd`); `scores.format_scores(top)` + smoke sceny (`test_scores_screen.gd`); +10 testów | E8 | PROG | #2 |
| ✅ P2.7 | ~~Wpięcie muzyki (`play_music`/`crossfade` na boss_incoming)~~ **WYKONANE** - `AudioManager` podpina muzykę pod sygnały GameState: `session_reset`→`play_music(MUSIC.gameplay)` (start sesji), `boss_incoming`→`crossfade_to(MUSIC.boss, 1.5)` (obok SFX boss_spawn); katalog `MUSIC` (placeholdery OGG, graceful fallback); `current_music_track` (intencja) ustawiany zawsze - testowalne bez plików audio; strażnik `test_music_wiring.gd` | E6 | PROG (←S3) | #1 |
| ✅ P2.8 | ~~Boss: maszyna stanów + telegraf szarży (logika)~~ **WYKONANE** - `enum Phase { TRACK, TELEGRAPH, CHARGE }`; `_on_charge` (timer) startuje od fazy TELEGRAPH (wind-up `MINIBOSS_TELEGRAPH_DURATION`=0.6s) zamiast od razu szarżować, dopiero potem CHARGE (Tween) -> TRACK; sygnał `charge_telegraph(duration)` + placeholder błysku (`_flash_telegraph`) pod pełny efekt G4; czysta funkcja `is_locked(phase)` (ruch śledzący tylko w TRACK); guard re-entry (`phase != TRACK`) i `is_dying`; strażnik `test_boss_telegraph.gd` | E3 | PROG (+G4) | #1 #6 |
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
- **Najważniejszy dług:** (1) ✅ orby XP (P0.1), (2) ✅ error-scan CI (P0.2), (3) ✅ warstwy kolizji (P1.1), (4) ✅ `max_level` (P1.2) - **wszystkie 4 zamknięte**. Dodatkowo ✅ `GameConfig` (P1.3), ✅ `EnemyBase` (P1.4), ✅ `SettingsStore` (P1.5) i ✅ czytelność stanu (P1.6). **Całe P1 zamknięte** - pozostaje P2/P3.
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
