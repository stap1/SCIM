# Architektoniczny Blueprint

## Ocena stanu technicznego

Projekt SCIM jest zdrowy architektonicznie: `GameState` pozostaje jedynym zrodlem prawdy o sesji, HUD jest read-only, wrogowie dziedzicza z `EnemyBase`, balans zyje w `GameConfig`, a logika zalezna od sceny jest wydzielana do czystych funkcji. To dobra baza - cztery z pieciu zgloszen QA da sie rozwiazac punktowo, bez naruszania tych zasad.

Mapa zgloszen po analizie kodu (stan faktyczny, nie domysly):

| # | Zgloszenie QA | Stan faktyczny w kodzie | Charakter poprawki |
|---|---|---|---|
| 1 | Brak menu pauzy | Brak. Pauze ustawiaja tylko `level_up`/`game_over` przez `get_tree().paused`. Flaga `GameState.is_paused` jest CZYTANA przez systemy, ale nigdzie nie ustawiana na `true`. | Nowa scena + skrypt |
| 2 | HUD wykracza poza scene | HUD jest poprawnie w `CanvasLayer` (nie w swiecie). Wezly prawej kolumny (HealthBar/XPBar/LevelLabel) maja absolutne offsety x ~820-1120 i domyslne kotwice lewy-gora. Brak sekcji `[display]`/stretch. | Kotwice + stretch |
| 3 | Specjalne ulepszenia w zwyklym level upie | Pule SA rozdzielone (`available_ids` ⊂ `UPGRADES`, `milestone_ids` ⊂ `MILESTONE_UPGRADES`). Wyciek nie reprodukuje sie. Izolacja jest jednak UMOWNA, a galaz milestone nie ma zabezpieczenia anty-softlock. | Hardening + test |
| 4 | Brak telegrafu ataku bossa | Maszyna stanow ma faze `TELEGRAPH` i `_flash_telegraph`, ale efekt jest subtelny i IGNORUJE ustawienie dostepnosci `reduce_flashing`. | Wzmocnienie efektu |
| 5 | Boss to statyczny obraz | `motor_boat.gd` nigdy nie ustawia `rotation`. | Plynny obrot `lerp_angle` |

## Podejscie do refaktoryzacji

- **Native-first.** Pauza wylacznie przez `get_tree().paused` + `process_mode = ALWAYS`; zadnych wlasnych petli wstrzymujacych.
- **Jeden wlasciciel pauzy.** Menu pauzy pauzuje TYLKO w aktywnej rozgrywce; gdy drzewo jest juz wstrzymane przez inny ekran (np. wybor ulepszenia) lub trwa game over, klawisz jest ignorowany. Eliminuje to konflikt dwoch wlascicieli `get_tree().paused`.
- **Responsywne UI przez kotwice, nie pozycje.** Elementy HUD przyklejone do wlasciwej krawedzi ekranu + tryb stretch `canvas_items` dla niezaleznosci od rozdzielczosci (wazne dla buildu web).
- **Izolacja przez strukture, nie przez konwencje.** Dystrybucja nagrod liczona jedna funkcja `_roll_choices`, z jednym zabezpieczeniem anty-softlock dla obu galezi i testem gwarantujacym rozlacznosc pul.
- **Czytelnosc i dostepnosc.** Telegraf bossa wyrazny, ale respektujacy `reduce_flashing`. Obrot bossa laczy sie z telegrafem: w fazie wind-up boss widocznie celuje w zablokowana pozycje.
- **Zero magic numbers.** Wszystkie nowe liczby laduja w `GameConfig` (balans) lub jako nazwane `const` warstwy UI.

### Nowe stale w `GameConfig`

```gdscript
# --- Mini-boss: telegraf i obrot (Code Review QA #4, #5) ---
## Ile pulsow rozblysku pokazac w czasie wind-upu (czytelny telegraf szarzy).
const MINIBOSS_TELEGRAPH_PULSES: int = 3
## Barwa rozblysku telegrafu (biel kontrastuje z czerwonym kadlubem bossa).
const MINIBOSS_TELEGRAPH_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
## Szybkosc wygladzania obrotu bossa (waga lerp_angle skalowana czasem klatki).
const MINIBOSS_TURN_SPEED: float = 6.0
```

---

# Code Review i Poprawki

## QA #1 - Menu pauzy (wyjscie + restart)

### Diagnoza
W `Main.tscn` sa tylko `HUD`, `LevelUp`, `GameOver`. Pauzy uzytkownika brak. Co istotne, `GameState.is_paused` jest czytana przez `enemy`/`xp_orb`/`motor_boat`/`boat`, lecz nigdy nie ustawiana na `true` - czyli dzis jest to martwa flaga. Menu pauzy bedzie pierwszym miejscem, ktore nada jej sens, obok natywnej pauzy drzewa.

### Rozwiazanie - hierarchia wezlow (minimalistyczna, ergonomiczna)

```
PauseMenu            (CanvasLayer, layer = 10, process_mode = ALWAYS)
└── Dimmer           (ColorRect, anchors_preset = Full Rect, color = 0,0,0,0.6,
│                     mouse_filter = STOP  # blokuje klikniecia w gre pod spodem)
    └── Center       (CenterContainer, anchors_preset = Full Rect)
        └── Menu     (VBoxContainer, separation = 16, alignment = center)
            ├── Title         (Label, "PAUZA", horizontal_alignment = center)
            ├── ResumeButton  (Button, "Wznow",       min_size = 260x48)
            ├── RestartButton (Button, "Restart",     min_size = 260x48)
            └── MenuButton    (Button, "Menu glowne", min_size = 260x48)
```

Zasady designu: jedna pionowa kolumna na przyciemnionym tle, duzy odstep, fokus startowy na "Wznow" (nawigacja klawiatura/pad od razu dziala), brak ozdobnikow. Wszystko skalowalne (kontenery + kotwice), wiec nie wymaga poprawek przy zmianie rozdzielczosci.

#### `scenes/ui/pause_menu.tscn` (szkielet)

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/pause_menu.gd" id="1_pause"]

[node name="PauseMenu" type="CanvasLayer"]
layer = 10
process_mode = 3            ; PROCESS_MODE_ALWAYS - dziala mimo get_tree().paused
script = ExtResource("1_pause")

[node name="Dimmer" type="ColorRect" parent="."]
anchors_preset = 15        ; Full Rect
color = Color(0, 0, 0, 0.6)
mouse_filter = 0           ; STOP - lapie klikniecia, gra pod spodem ich nie dostaje

[node name="Center" type="CenterContainer" parent="Dimmer"]
anchors_preset = 15

[node name="Menu" type="VBoxContainer" parent="Dimmer/Center"]
theme_override_constants/separation = 16

[node name="Title" type="Label" parent="Dimmer/Center/Menu"]
text = "PAUZA"
horizontal_alignment = 1

[node name="ResumeButton" type="Button" parent="Dimmer/Center/Menu"]
custom_minimum_size = Vector2(260, 48)
text = "Wznow"

[node name="RestartButton" type="Button" parent="Dimmer/Center/Menu"]
custom_minimum_size = Vector2(260, 48)
text = "Restart"

[node name="MenuButton" type="Button" parent="Dimmer/Center/Menu"]
custom_minimum_size = Vector2(260, 48)
text = "Menu glowne"
```

> `Main.tscn`: dodaj instancje `PauseMenu` jako ostatnie dziecko `Main` (rysuje sie nad HUD/LevelUp dzieki `layer = 10`).

#### Akcja wejscia `pause` (`project.godot`, sekcja `[input]`)

```
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"physical_keycode":4194305,...)   ; Esc
, Object(InputEventKey,"physical_keycode":80,...)                  ; P
]
}
```

> Dedykowana akcja (zamiast wbudowanego `ui_cancel`) jest spojna z Input Map z reszty projektu i pozwala dolozyc przycisk dotykowy w buildzie mobilnym.

#### `scripts/ui/pause_menu.gd`

```gdscript
extends CanvasLayer

## Menu pauzy. Pauza realizowana natywnie: get_tree().paused = true wstrzymuje cale
## drzewo, a ten wezel ma process_mode = ALWAYS, wiec menu i jego przyciski dzialaja
## mimo wstrzymania reszty gry.
##
## Wzorzec "jeden wlasciciel pauzy": menu otwiera pauze TYLKO w aktywnej rozgrywce.
## Gdy drzewo jest juz wstrzymane przez inny ekran (wybor ulepszenia) albo trwa game
## over, klawisz pauzy jest ignorowany. Zapobiega to konfliktowi dwoch niezaleznych
## wlascicieli flagi get_tree().paused.

@onready var _dimmer: Control = $Dimmer
@onready var _resume_button: Button = $Dimmer/Center/Menu/ResumeButton
@onready var _restart_button: Button = $Dimmer/Center/Menu/RestartButton
@onready var _menu_button: Button = $Dimmer/Center/Menu/MenuButton

## Czy to menu jest aktualnym wlascicielem pauzy. Chroni przed "przejeciem" pauzy
## zalozonej przez inny ekran (np. wznowienie gry w trakcie wyboru ulepszenia).
var _is_open: bool = false

func _ready() -> void:
	# Pewnik na wypadek braku ustawienia w .tscn - menu musi dzialac przy pauzie.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dimmer.hide()
	_resume_button.pressed.connect(resume)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)

## Obsluga klawisza pauzy. _unhandled_input dziala dla wezlow ALWAYS takze przy
## get_tree().paused, a uruchamia sie dopiero gdy zdarzenia nie skonsumowal zaden Control.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle()
		get_viewport().set_input_as_handled()

## Przelacza pauze z poszanowaniem wlasnosci (patrz docstring klasy).
func _toggle() -> void:
	if GameState.is_game_over:
		return                      # po smierci pauza nie ma sensu (jest ekran wynikow)
	if _is_open:
		resume()
	elif not get_tree().paused:
		_open()
	# else: drzewo wstrzymane przez inny ekran - swiadomie ignorujemy.

## Otwiera menu i wstrzymuje rozgrywke.
func _open() -> void:
	_is_open = true
	GameState.is_paused = true      # spojnosc dla systemow czytajacych te flage
	get_tree().paused = true
	_dimmer.show()
	_resume_button.grab_focus()     # ergonomia: od razu nawigacja klawiatura/pad

## Wznawia rozgrywke. Publiczne - podpiete pod przycisk "Wznow" oraz klawisz pauzy.
func resume() -> void:
	_is_open = false
	GameState.is_paused = false
	get_tree().paused = false
	_dimmer.hide()

func _on_restart_pressed() -> void:
	_leave_session()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	_leave_session()
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)

## Wspolne sprzatanie przed opuszczeniem rozgrywki: zdejmij pauze i zresetuj sesje,
## by nowa gra (restart/menu) startowala z czystym GameState.
func _leave_session() -> void:
	_is_open = false
	GameState.is_paused = false
	get_tree().paused = false
	GameState.reset()
```

---

## QA #2 - HUD wykracza poza scene

### Diagnoza
HUD jest poprawnie osadzony w `CanvasLayer` (przestrzen ekranu, niezalezna od kamery), wiec to NIE jest problem "w swiecie zamiast w UI". Przyczyna jest dwojaka:

1. **Kotwice.** Wezly prawej kolumny (`HealthBar`, dodane `LevelLabel` i `XPBar`) maja domyslne kotwice lewy-gora (0,0) i absolutne offsety `x ~820-1120`. Pozycjonuja sie wiec pikselami od lewej krawedzi. Przy viewportcie wezszym niz ~1120 px (zmiana okna, canvas web) wychodza poza ekran.
2. **Brak trybu stretch.** W `project.godot` nie ma sekcji `[display]`, wiec uzywany jest domyslny viewport bez skalowania - UI nie dostosowuje sie do rozmiaru okna.

### Rozwiazanie A - kotwice do wlasciwej krawedzi (poprawka punktowa)

Prawa kolumna przyklejona do PRAWEJ krawedzi (`anchor_left = anchor_right = 1.0`) z offsetami ujemnymi, ostrzezenie bossa wysrodkowane. Wartosci dobrane tak, by zachowac dotychczasowy wyglad przy 1152x648, ale juz responsywnie.

```
; --- prawa kolumna: przyklejona do prawej krawedzi, 32 px marginesu, 300 px szer. ---
[node name="HealthBar" type="ProgressBar" parent="."]
anchor_left = 1.0
anchor_right = 1.0
offset_left = -332.0
offset_top = 16.0
offset_right = -32.0
offset_bottom = 46.0
show_percentage = false
; (style/fill bez zmian)

[node name="LevelLabel" type="Label" parent="."]
anchor_left = 1.0
anchor_right = 1.0
offset_left = -332.0
offset_top = 50.0
offset_right = -32.0
offset_bottom = 78.0
horizontal_alignment = 2          ; do prawej

[node name="XPBar" type="ProgressBar" parent="."]
anchor_left = 1.0
anchor_right = 1.0
offset_left = -332.0
offset_top = 82.0
offset_right = -32.0
offset_bottom = 100.0
show_percentage = false

; --- ostrzezenie bossa: wysrodkowane w poziomie ---
[node name="BossWarning" type="Label" parent="."]
anchor_left = 0.5
anchor_right = 0.5
offset_left = -275.0
offset_top = 90.0
offset_right = 275.0
offset_bottom = 150.0
horizontal_alignment = 1
```

> Lewa kolumna (`TimeLabel`, `ScoreLabel`, `AmmoIcon`, `AmmoLabel`) zostaje na kotwicy lewy-gora - jej male offsety (x ~20-320) sa bezpieczne. Dla porzadku mozna ustawic jawnie `anchor_* = 0`.

### Rozwiazanie B - niezaleznosc od rozdzielczosci (`project.godot`)

```
[display]

window/size/viewport_width=1152
window/size/viewport_height=648
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

`canvas_items` + `expand` skaluja cale UI razem z oknem i pokazuja wiecej swiata na szerszych ekranach, zamiast ucinac HUD. Rozwiazania A i B sa komplementarne: A naprawia logiczne rozmieszczenie, B - skalowanie.

---

## QA #3 - Specjalne ulepszenia w zwyklym level upie

### Diagnoza (stan faktyczny)
W obecnym kodzie pule SA juz rozdzielone:
- `Upgrades.available_ids()` iteruje wylacznie `UPGRADES` (6 zwyklych),
- `Upgrades.milestone_ids()` iteruje wylacznie `MILESTONE_UPGRADES` (`extra_harpoon`, `piercing`),
- `level_up._on_level_up` wybiera pule przez `is_milestone_level`.

Wyciek z zgloszenia nie reprodukuje sie na aktualnym `level_up.gd`. Sa jednak trzy realne luki, ktore warto domknac, bo dzis izolacja jest UMOWNA (dwa slowniki, ktore przypadkiem sie nie pokrywaja), a nie wymuszona:

1. **Brak gwarancji rozlacznosci.** Nic nie pilnuje, by ktos w przyszlosci nie wpisal tego samego id do obu slownikow.
2. **Latentny softlock.** Galaz milestone NIE ma zabezpieczenia `is_empty()` (ma je tylko galaz zwykla). Gdyby `milestone_ids()` kiedys wrocila pusto, gra zapauzuje sie bez wybieralnej karty.
3. **Brak tasowania milestone.** Opcje milestone podawane sa w stalej kolejnosci (dzis dziala, bo sa dwie i obie sie miesza, ale to przypadek).

### Rozwiazanie - izolacja strukturalna + jeden anty-softlock

Cala dystrybucja liczona jest jedna funkcja, z jednym zabezpieczeniem pustej puli dla OBU galezi. Uogolniamy `pick_three` do `pick_n`.

```gdscript
# scripts/ui/level_up.gd

## Ile kart pokazac na ekranie zwyklym i milestone (na wypadek rozszerzenia katalogow).
const REGULAR_CHOICES: int = 3
const MILESTONE_CHOICES: int = 3

func _on_level_up(new_level: int) -> void:
	_current_ids = _roll_choices(new_level)
	# Jedno wspolne zabezpieczenie anty-softlock dla obu typow level-upu:
	# pusta oferta (wszystko wyczerpane) - nie pauzuj, by nie zablokowac gry.
	if _current_ids.is_empty():
		return
	_present_cards()
	get_tree().paused = true
	_flash()

## Dobiera oferte kart dla danego poziomu. Na poziomach milestone (co
## GameConfig.MILESTONE_LEVEL_INTERVAL) zwraca WYLACZNIE pule milestone, w przeciwnym
## razie WYLACZNIE pule zwykla. Pule pochodza z rozlacznych katalogow Upgrades -
## to strukturalnie gwarantuje, ze specjalne ulepszenia nie trafia do zwyklego
## losowania i odwrotnie.
##
## @param level - numer osiagnietego poziomu.
## @return - lista id ulepszen do pokazania (moze byc pusta, gdy pula wyczerpana).
func _roll_choices(level: int) -> Array[String]:
	if is_milestone_level(level, GameConfig.MILESTONE_LEVEL_INTERVAL):
		return pick_n(Upgrades.milestone_ids(), randi(), MILESTONE_CHOICES)
	return pick_n(Upgrades.available_ids(), randi(), REGULAR_CHOICES)

## Czysta funkcja: n unikalnych opcji z puli, deterministycznie wg seeda
## (tasowanie Fisher-Yates). Uogolnienie dotychczasowego pick_three.
##
## @param pool     - pula id do wyboru.
## @param rng_seed - ziarno RNG (determinizm = testowalnosc).
## @param count    - ile opcji zwrocic (mniej, gdy pula krotsza).
static func pick_n(pool: Array[String], rng_seed: int, count: int) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var copy: Array[String] = pool.duplicate()
	for i in range(copy.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy.slice(0, count)
```

### Gwarancja rozlacznosci - test regresji

```gdscript
# test/test_upgrade_pools_disjoint.gd
extends GutTest

## Strukturalna gwarancja izolacji pul: zaden id nie moze byc jednoczesnie zwyklym
## ulepszeniem i power-upem milestone. To wlasnie ta rozlacznosc sprawia, ze
## specjalne ulepszenia nigdy nie pojawia sie w zwyklym level upie (QA #3).
func test_regular_and_milestone_pools_are_disjoint() -> void:
	for id in Upgrades.UPGRADES:
		assert_false(Upgrades.MILESTONE_UPGRADES.has(id),
			"id %s nie moze byc w obu pulach naraz" % id)

func test_available_ids_never_contains_milestone() -> void:
	GameState.reset()
	for id in Upgrades.available_ids():
		assert_false(Upgrades.MILESTONE_UPGRADES.has(id),
			"zwykla pula losowania nie moze zawierac power-upu milestone")
```

---

## QA #4 - Brak telegrafu ataku bossa

### Diagnoza
Maszyna stanow bossa ma juz faze `TELEGRAPH` (wind-up) i metode `_flash_telegraph`, ale: (a) efekt to jedno subtelne rozjasnienie, malo czytelne; (b) metoda IGNORUJE ustawienie dostepnosci `reduce_flashing`, podczas gdy reszta gry (level-up flash, shake) je respektuje.

### Rozwiazanie - wyrazny, pulsujacy telegraf z poszanowaniem dostepnosci

Telegraf modyfikuje `modulate` SPRITE'A (nie wezla bossa), wracajac do zapamietanej barwy bazowej (czerwony kadlub). Przy wlaczonym `reduce_flashing` - pojedyncze lagodne rozjasnienie zamiast migotania.

```gdscript
# scripts/systems/motor_boat.gd

## Barwa bazowa sprite'a bossa (czerwony kadlub), zapamietana, by telegraf
## mial dokad wrocic po rozblysku.
var _base_modulate: Color = Color.WHITE

func _ready() -> void:
	super._ready()
	var sprite := get_node_or_null("Sprite2D")
	if sprite:
		_base_modulate = sprite.modulate
	# ... reszta _ready (hp_bar, timer) bez zmian ...

## Wizualny telegraf wind-upu: pulsujace rozjasnienie sprite'a, by gracz jednoznacznie
## odczytal nadchodzaca szarze. Respektuje dostepnosc: przy wlaczonym "reduce flashing"
## telegraf jest pojedynczy i lagodny (bez migotania).
func _flash_telegraph() -> void:
	var sprite := get_node_or_null("Sprite2D")
	if sprite == null:
		return
	var tween := create_tween()
	if SettingsStore.should_flash(SettingsStore.reduce_flashing):
		# Pelny telegraf: kilka pulsow bieli rownomiernie w czasie wind-upu.
		var half := telegraph_duration / float(GameConfig.MINIBOSS_TELEGRAPH_PULSES * 2)
		for _i in GameConfig.MINIBOSS_TELEGRAPH_PULSES:
			tween.tween_property(sprite, "modulate", GameConfig.MINIBOSS_TELEGRAPH_COLOR, half)
			tween.tween_property(sprite, "modulate", _base_modulate, half)
	else:
		# Wariant dostepny: jedno lagodne rozjasnienie tam i z powrotem.
		var half := telegraph_duration * 0.5
		tween.tween_property(sprite, "modulate", GameConfig.MINIBOSS_TELEGRAPH_COLOR, half)
		tween.tween_property(sprite, "modulate", _base_modulate, half)
```

> Telegraf wzmacnia dodatkowo obrot z QA #5: w fazie wind-up boss jednoczesnie blyska i widocznie celuje w zablokowana pozycje - podwojny, czytelny sygnal.

---

## QA #5 - Mini-boss jako statyczny obraz (plynny obrot)

### Diagnoza
`motor_boat._physics_process` ustawia `velocity` i wola `move_and_slide`, ale NIGDY nie zmienia `rotation`. Sprite (`lodz.svg`, ta sama tekstura co gracz) wskazuje gore, wiec korekta katu to `+ PI/2` - identycznie jak w `boat.gd`.

### Rozwiazanie - obrot przez `lerp_angle` (najkrotsza droga, bez przeskoku)

`lerp_angle` interpoluje katy najkrotsza droga i poprawnie obsluguje owijanie przez `2*PI`, wiec nie ma sztucznego "przeskoku". Waga skalowana czasem klatki daje wygladzanie wykladnicze (plynne dojscie do celu). Cel obrotu zalezy od fazy: w `TRACK` boss patrzy na zywego gracza, w `TELEGRAPH`/`CHARGE` - na ZABLOKOWANA pozycje szarzy (obrot staje sie czescia telegrafu).

```gdscript
# scripts/systems/motor_boat.gd

## Pozycja szarzy zablokowana na poczatku telegrafu. Boss celuje w nia juz w wind-upie
## (czesc telegrafu) i tam natrze - dzieki temu szarza jest do unikniecia: gracz, ktory
## odejdzie po rozpoczeciu telegrafu, nie zostanie trafiony.
var _charge_target: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if GameState.is_paused or GameState.is_game_over:
		return
	_face_aim(delta)                 # obrot dziala w KAZDEJ fazie (sledzenie i szarza)
	if is_locked(phase):             # telegraf/szarza: pozycja sterowana Tweenem/stop
		return
	if not acquire_target():
		return
	velocity = (target.global_position - global_position).normalized() * track_speed
	move_and_slide()

## Plynnie obraca bossa ku aktualnemu celowi. Tekstura lodzi wskazuje gore, stad +PI/2.
func _face_aim(delta: float) -> void:
	var aim: Vector2 = _aim_position()
	if aim.is_equal_approx(global_position):
		return                       # brak sensownego kierunku - nie obracaj
	var desired: float = (aim - global_position).angle() + PI / 2.0
	rotation = aim_rotation(rotation, desired, GameConfig.MINIBOSS_TURN_SPEED, delta)

## Punkt, w ktory boss ma patrzec: w trakcie telegrafu/szarzy - zablokowana pozycja
## szarzy; w fazie sledzenia - zywy gracz (lub wlasna pozycja, gdy gracza brak).
func _aim_position() -> Vector2:
	if is_locked(phase):
		return _charge_target
	if target != null and is_instance_valid(target):
		return target.global_position
	return global_position

## Czysta funkcja: plynny obrot ku zadanemu katowi przez lerp_angle. Interpolacja
## najkrotsza droga (poprawne owijanie 2*PI), waga przyciecia w [0,1] - brak przeskoku
## nawet przy duzym delta. Zwraca nowy kat w radianach.
##
## @param current    - biezacy kat (rad).
## @param target     - docelowy kat (rad).
## @param turn_speed - szybkosc obrotu (1/s); wieksza = szybsze dojscie.
## @param delta      - czas klatki (s).
static func aim_rotation(current: float, target: float, turn_speed: float, delta: float) -> float:
	return lerp_angle(current, target, clampf(turn_speed * delta, 0.0, 1.0))
```

Spiecie z istniejaca maszyna stanow (zablokowanie celu w wind-upie):

```gdscript
func _begin_telegraph() -> void:
	phase = Phase.TELEGRAPH
	_charge_target = target.global_position   # ZABLOKUJ cel - aim i szarza w to samo miejsce
	charge_telegraph.emit(telegraph_duration)
	_flash_telegraph()
	var tween := create_tween()
	tween.tween_interval(telegraph_duration)
	tween.tween_callback(_begin_charge)

func _begin_charge() -> void:
	if is_dying:
		phase = Phase.TRACK
		return
	phase = Phase.CHARGE
	# Szarza w zablokowana pozycje (a nie biezaca pozycje gracza) - dlatego do unikniecia.
	var tween := create_tween()
	tween.tween_property(self, "global_position", _charge_target, charge_duration)
	tween.tween_callback(_end_charge)
```

### Test regresji (czysta funkcja obrotu)

```gdscript
# test/test_boss_rotation.gd
extends GutTest
const MotorBoatScript := preload("res://scripts/systems/motor_boat.gd")

func test_aim_rotation_moves_toward_target() -> void:
	var r := MotorBoatScript.aim_rotation(0.0, PI / 2.0, 6.0, 0.1)
	assert_gt(r, 0.0, "obrot rusza ku celowi")
	assert_lt(r, PI / 2.0, "ale go nie przeskakuje w jednej klatce")

func test_aim_rotation_shortest_path_no_wrap_jump() -> void:
	# Z 170 do -170 stopni: najkrotsza droga przez 180, nie przez 0.
	var from := deg_to_rad(170.0)
	var to := deg_to_rad(-170.0)
	var r := MotorBoatScript.aim_rotation(from, to, 6.0, 0.1)
	assert_gt(absf(r), deg_to_rad(170.0), "obrot idzie 'na zewnatrz' (przez 180), bez przeskoku przez zero")
```

---

# Checklista Wdrozeniowa

Kolejnosc od najnizszego ryzyka (czyste funkcje, dane) do integracji UI i logiki bossa. Po kazdym kroku: `tools/run_checks.ps1` zielone (import + GUT + smoke + error-scan).

### Etap 0 - Konfiguracja i stale
- [ ] Dodaj do `GameConfig`: `MINIBOSS_TELEGRAPH_PULSES`, `MINIBOSS_TELEGRAPH_COLOR`, `MINIBOSS_TURN_SPEED`.
- [ ] Dodaj akcje `pause` (Esc + P) w `project.godot` sekcja `[input]`.
- [ ] Dodaj sekcje `[display]` (viewport 1152x648, stretch `canvas_items`, aspect `expand`).

### Etap 1 - QA #3: izolacja pul (najmniej ryzykowne, czysta logika)
- [ ] Wprowadz `pick_n` w `level_up.gd`; przepnij stary `pick_three` (lub testy) na `pick_n(..., 3)`.
- [ ] Dodaj `_roll_choices(level)` i przebuduj `_on_level_up` z JEDNYM zabezpieczeniem `is_empty()`.
- [ ] Dodaj `test/test_upgrade_pools_disjoint.gd` (rozlacznosc pul + brak milestone w `available_ids`).
- [ ] Uruchom testy.

### Etap 2 - QA #5: obrot bossa (czysta funkcja + integracja)
- [ ] Dodaj czysta `aim_rotation` + `test/test_boss_rotation.gd`.
- [ ] Dodaj pola `_charge_target`, `_base_modulate`; zablokuj cel w `_begin_telegraph`, uzyj go w `_begin_charge`.
- [ ] Dodaj `_face_aim`/`_aim_position`; zmien sygnature `_physics_process(_delta)` na `delta` i wywolaj obrot.
- [ ] Uruchom testy (sprawdz, ze istniejacy `test_boss_telegraph.gd` dalej zielony).

### Etap 3 - QA #4: telegraf wizualny (zalezny od Etapu 2 - wspolny `_charge_target`)
- [ ] Zapamietaj `_base_modulate` w `_ready`.
- [ ] Przebuduj `_flash_telegraph` na pulsujacy, z galezia `reduce_flashing`.
- [ ] Wizualna weryfikacja: telegraf czytelny; przy wlaczonym "reduce flashing" brak migotania.

### Etap 4 - QA #2: kotwice HUD (UI)
- [ ] Przekotwicz `HealthBar`, `LevelLabel`, `XPBar` do prawej krawedzi; `BossWarning` do srodka.
- [ ] (Opcjonalnie, dla porzadku) jawne `anchor_* = 0` dla lewej kolumny.
- [ ] Test okna: zmniejsz okno / zmien proporcje - HUD zostaje na ekranie.

### Etap 5 - QA #1: menu pauzy (integracja UI + sterowanie)
- [ ] Utworz `scenes/ui/pause_menu.tscn` wg hierarchii (CanvasLayer ALWAYS -> Dimmer -> Center -> VBox -> przyciski).
- [ ] Utworz `scripts/ui/pause_menu.gd` (wzorzec "jeden wlasciciel pauzy", `ScenePaths.MAIN_MENU`).
- [ ] Dodaj instancje `PauseMenu` jako ostatnie dziecko `Main.tscn`.
- [ ] Testy zachowania: pauza w aktywnej grze TAK; w trakcie level-upu/po game over - klawisz ignorowany; Wznow/Restart/Menu dzialaja; fokus startowy na "Wznow".

### Etap 6 - Domkniecie
- [ ] `tools/run_checks.ps1` zielone w calosci.
- [ ] Smoke wizualny calej petli: start -> pauza -> wznow -> level-up (zwykly i co 5) -> boss (telegraf + obrot) -> restart z menu pauzy.
- [ ] Aktualizacja `AUDIT.md` (powiazania: QA #4 rozszerza P2.8, QA #3 hardening systemu ulepszen).
