# SCIM - Specyfikacja techniczna audio (dla Mateusza)

**Stan na:** 2026-06-21 (po rundzie narracja/UI/balans). Zastępuje nieaktualne fragmenty `ASSETS_SFX.md` w części "stan". Właściciel audio: **Mateusz Olech**.

Dokument = kontrakt z kodem (`scripts/systems/audio_manager.gd`) + lista assetów do nagrania/pozyskania.

---

## 1. Konwencje techniczne (twarde wymogi)

- **Format docelowy: OGG Vorbis.** Web-friendly (CLAUDE.md: brak MP4/wideo, brak wątków). WAV tylko jako placeholder do konwersji.
- **Kanały:** SFX = **mono**; muzyka i ambient = **stereo**.
- **Próbkowanie:** 44.1 kHz. Vorbis q: SFX ~q5, muzyka/ambient ~q6.
- **Pętle:** muzyka i ambient **bezszwowe** (seamless, bez kliknięć/ciszy na złączeniu). W imporcie Godota zaznaczyć **Loop**. SFX = one-shoty (bez pętli).
- **Normalizacja:** SFX szczyt ≈ -3 dBFS; muzyka/ambient ≈ -14 LUFS zintegrowane, spójnie między utworami.
- **Ścieżki:** `res://audio/sfx/`, `res://audio/music/`, `res://audio/ambient/`.
- **Busy** (`default_bus_layout.tres`): `Master` → `Music`, `SFX`, `Ambient`. Głośność Music/SFX steruje gracz (suwaki w Ustawieniach + panel w pauzie). AudioManager kieruje każdy dźwięk na właściwy bus.

## 2. Kontrakt z kodem

- **Klucze SFX = `AudioManager.SFX_PATHS`.** Podpinasz plik OGG pod istniejący klucz (ten sam string). Pusty string lub brak pliku = graceful fallback (cisza, bez crasha).
- **Klawisz maszyny do pisania** gra przez dedykowany odtwarzacz (`play_typewriter_key`, throttling + jitter pitchu) - nie obciąża puli 16 SFX.
- **Dźwięk zbierania XP z combo** (jeśli powstanie) ma używać `play_sfx_pitched` (rosnący pitch serii) - patrz `xp_pickup`.
- **Muzyka:** `AudioManager.MUSIC` (menu/gameplay/boss/gameover). Crossfade na bossie (`crossfade_to`). Głośność busa Music nienaruszana przez crossfade (steruje nią gracz).

---

## 3. Stan obecny audio (co jest, co placeholder, co brak)

### SFX (`audio/sfx/`)
| Klucz (kod) | Plik | Stan | Uwaga |
|---|---|---|---|
| `harpoon_shot` | harpoon_shot.ogg | OK | strzał harpuna (co ~0.8 s) |
| `hit` | hit.ogg | OK | harpun trafia wroga |
| `enemy_death` | enemy_death.**wav** | **do konwersji na OGG** | jedyny WAV w SFX |
| `boss_spawn` | enemy_spawn.ogg (reuse) | **placeholder** | reużywa dźwięku spawnu; brak własnego cue bossa |
| `player_hit` | player_hit.ogg | OK | gracz dostaje obrażenia |
| `level_up` | level_up.ogg | OK | awans poziomu |
| `ui_click` | ui_click.ogg | OK | klik w UI |
| `heal` | heal.ogg | OK | zebranie deski leczniczej |
| `xp_pickup` | "" (pusty) | **brak** | zbieranie orba XP - cichy; docelowo z combo-pitch |
| `typewriter_key` | typewriter_key.ogg | OK (CC0) | klawisz maszyny (narracja) - dziś dodany |
| `typewriter_bell` | typewriter_bell.ogg | OK (CC0) | dzwonek karetki na końcu kwestii - dziś dodany |
| `port_siren` | port_siren.ogg | OK (CC0) | syrena na start gry (po odliczaniu) - dziś dodany |

### Muzyka (`audio/music/`)
| Klucz | Plik | Stan |
|---|---|---|
| `menu` | music_menu.ogg | OK |
| `gameplay` | music_game.ogg | OK |
| `boss` | music_boss.ogg | OK |
| `gameover` | music_gameover.ogg | OK (wariant porażki ekranu końca) |
| (zwycięstwo) | - | **BRAK** - ekran WYGRANA reużywa `music_menu` jako placeholder |

### Ambient (`audio/ambient/`)
| Plik | Stan | Uwaga |
|---|---|---|
| ambient_sea.ogg | OK | szum morza; gra w menu (przyciszony) |

---

## 4. Lista możliwych / potrzebnych assetów dźwiękowych

Priorytety: **[P1]** wyraźna luka feedbacku/klimatu · **[P2]** zauważalne ulepszenie · **[P3]** kosmetyka/przyszłość.

### 4a. Do uzupełnienia istniejących luk
- **[P1] Utwór ZWYCIĘSTWA** (`music_victory.ogg`, stereo, loop lub krótki sting) - ekran WYGRANA ma inny nastrój niż porażka; teraz pożycza muzykę menu. Po dodaniu: dopiąć klucz w `MUSIC` i `_on_game_over` (wariant `won`).
- **[P1] `xp_pickup`** - krótki, miękki "blip" zbierania orba; ma dobrze brzmieć w serii (combo podnosi pitch). Bardzo częsty - musi nie męczyć.
- **[P2] `enemy_death` → OGG** - konwersja istniejącego WAV.
- **[P2] Dedykowany cue bossa** (`boss_spawn` / `boss_incoming`) - groźny róg/silnik motorówki zamiast reużytego spawnu. Pasuje do kwestii "Silnik na horyzoncie...".

### 4b. Warianty per typ wroga (głębia)
- **[P2]** Osobne dźwięki śmierci/trafienia: **meduza** (mokry "plop"), **barakuda** (szybki chlust), **rekin** (cięższy plusk). Kod ma już `enemy_type` - łatwo podpiąć warianty.
- **[P3]** Dźwięk szarży / telegrafu mini-bossa (narastający warkot silnika w wind-upie).

### 4c. Klimat / ambient (morze Santiago)
- **[P2]** Warstwy ambientu w grze: fale, wiatr, skrzypienie łodzi, mewy (sporadycznie). Teraz ambient gra tylko w menu - można dodać subtelny w rozgrywce.
- **[P3]** Pluski przy ruchu łodzi / dziobie tnącym wodę.

### 4d. Narracja (Santiago)
- Kwestie protagonisty są tekstem z efektem maszyny do pisania (klawisz + dzwonek) - **VO nie jest wymagane**.
- **[P3] Opcjonalne VO** dla kluczowych kwestii (intro, pierwszy rekin, boss) - jeśli kiedyś, to PL, ton zmęczonej determinacji. Architektura na to gotowa (dialogi sygnałowe).

### 4e. UI / eventy (kosmetyka)
- **[P3]** Dźwięk najechania/zmiany focusu w menu (teraz jest tylko klik wyboru) - drobny "tick" przy nawigacji klawiaturą.
- **[P3]** Cue eventów spawnu (rojenie meduz "Morze nie znosi pustki", rajd barakud) - krótki sygnał ostrzegawczy. Eventy są data-driven (`enemy_spawner.SPAWN_EVENTS`).
- **[P3]** Dźwięk pojawienia się deski leczniczej (subtelny "drewniany" plusk).

---

## 5. Jak podpiąć nowy plik (skrót dla Mateusza)
1. Wyeksportuj OGG wg konwencji (sekcja 1), wrzuć do `audio/sfx|music|ambient/`.
2. SFX: użyj **istniejącego klucza** z tabeli (sekcja 3) lub poproś o nowy klucz w `SFX_PATHS`.
3. Muzyka/ambient: zaznacz **Loop** w imporcie Godota.
4. Odpal `tools/run_checks.ps1` - `--import` wciągnie plik, testy `test_audio.gd`/`test_music_wiring.gd` pilnują wpięcia.
