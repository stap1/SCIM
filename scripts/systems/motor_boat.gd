extends EnemyBase

# Mini-boss "Motorowka klusownika". Maszyna stanow:
#   TRACK (sledzi gracza) -> TELEGRAPH (wind-up, ostrzezenie) -> CHARGE (szarza Tweenem) -> TRACK.
# Telegraf daje graczowi czas na unik; sygnal charge_telegraph pozwala podpiac wizualny blysk (G4).
# Wspolna logika (health/is_dying/die/take_damage/set_target/grupa) w EnemyBase.

enum Phase { TRACK, TELEGRAPH, CHARGE }

signal boss_defeated(position: Vector2)
# Emitowany na poczatku wind-upu - nasluch (np. blysk/reflektor) ma 'duration' na reakcje.
signal charge_telegraph(duration: float)

# Eksporty specyficzne dla bossa (track_speed zamiast speed, parametry szarzy).
@export var track_speed: float = GameConfig.MINIBOSS_TRACK_SPEED
@export var charge_interval: float = GameConfig.MINIBOSS_CHARGE_INTERVAL
@export var charge_duration: float = GameConfig.MINIBOSS_CHARGE_DURATION
@export var telegraph_duration: float = GameConfig.MINIBOSS_TELEGRAPH_DURATION

var phase: int = Phase.TRACK
var _charge_timer: Timer
## Barwa bazowa sprite'a bossa (czerwony kadlub), zapamietana w _ready, by telegraf
## mial dokad wrocic po rozblysku.
var _base_modulate: Color = Color.WHITE
## Pozycja szarzy zablokowana na poczatku telegrafu. Boss celuje w nia juz w wind-upie
## (obrot staje sie czescia telegrafu) i tam natrze - dlatego szarza jest do unikniecia:
## gracz, ktory odejdzie po rozpoczeciu telegrafu, nie zostanie trafiony.
var _charge_target: Vector2 = Vector2.ZERO

@onready var hp_bar: ProgressBar = get_node_or_null("BarAnchor/HpBar")
## Kotwica paska HP - kontr-rotowana, by pasek trzymal sie poziomo nad bossem (nie obracal sie z cialem).
@onready var _bar_anchor: Node2D = get_node_or_null("BarAnchor")
## Wizualny telegraf szarzy (G4): additywny stozek, dziecko ciala - obraca sie z bossem,
## wiec celuje tam, gdzie natrze. Ukryty poza wind-upem.
@onready var _telegraph: Sprite2D = get_node_or_null("Telegraph")

func _init() -> void:
	# Wartosci startowe bossa z GameConfig (jedyne zrodlo balansu).
	max_health = GameConfig.MINIBOSS_HP
	kill_score = GameConfig.MINIBOSS_SCORE
	contact_damage = GameConfig.MINIBOSS_CONTACT_DAMAGE

func _ready() -> void:
	super._ready()
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = health
	var sprite := get_node_or_null("Sprite2D")
	if sprite:
		_base_modulate = sprite.modulate
	if _telegraph:
		_telegraph.visible = false
	_start_idle_bob()

	_charge_timer = Timer.new()
	_charge_timer.wait_time = charge_interval
	_charge_timer.autostart = true
	_charge_timer.timeout.connect(_on_charge)
	add_child(_charge_timer)

	# Kilwater bossa: motorowka to LODZ - jako jedyny wrog zostawia piane (jak gracz).
	WakeTrail.attach_to(self, track_speed)

func _physics_process(delta: float) -> void:
	if GameState.is_paused or GameState.is_game_over:
		return
	tick_slow(delta) # status spowolnienia dziala na sledzenie (szarza-Tween zostaje skokiem)
	_face_aim(delta) # obrot dziala w KAZDEJ fazie (sledzenie i szarza)
	if _bar_anchor != null:
		_bar_anchor.global_rotation = 0.0  # pasek HP poziomo, nie obraca sie z bossem
	# Swobodny ruch (sledzenie) tylko w fazie TRACK; telegraf zatrzymuje, szarza steruje Tweenem.
	if is_locked(phase):
		return
	if not acquire_target():
		return
	velocity = (target.global_position - global_position).normalized() * track_speed * slow_multiplier()
	move_and_slide()

## Plynnie obraca bossa ku aktualnemu celowi. Tekstura lodzi wskazuje gore, stad +PI/2
## (ta sama konwencja co gracz w boat.gd).
func _face_aim(delta: float) -> void:
	var aim: Vector2 = _aim_position()
	if aim.is_equal_approx(global_position):
		return # brak sensownego kierunku - nie obracaj
	var desired: float = (aim - global_position).angle() + PI / 2.0
	rotation = aim_rotation(rotation, desired, GameConfig.MINIBOSS_TURN_SPEED, delta)

## Punkt, w ktory boss ma patrzec: w telegrafie/szarzy - zablokowana pozycja szarzy;
## w fazie sledzenia - zywy gracz (lub wlasna pozycja, gdy gracza brak).
func _aim_position() -> Vector2:
	if is_locked(phase):
		return _charge_target
	if target != null and is_instance_valid(target):
		return target.global_position
	return global_position

# Timer co charge_interval: rozpocznij sekwencje szarzy od fazy telegrafu (wind-up).
func _on_charge() -> void:
	if is_dying:
		return
	if phase != Phase.TRACK:
		return # sekwencja juz trwa - nie nakladaj faz
	if target == null or not is_instance_valid(target):
		return
	_begin_telegraph()

# Faza TELEGRAPH: boss zatrzymuje sie, ZABLOKOWuje cel i sygnalizuje szarze (czas na unik).
func _begin_telegraph() -> void:
	phase = Phase.TELEGRAPH
	# Zablokuj kierunek juz teraz: boss natiera w LINII (overshoot o MINIBOSS_CHARGE_DISTANCE),
	# przelatujac obok gracza i odslaniajac bok. Gracz, ktory odejdzie, unika trafienia.
	if target != null and is_instance_valid(target):
		var dir := (target.global_position - global_position).normalized()
		if dir.is_zero_approx():
			dir = Vector2.UP
		_charge_target = global_position + dir * GameConfig.MINIBOSS_CHARGE_DISTANCE
	charge_telegraph.emit(telegraph_duration)
	_flash_telegraph()
	_show_telegraph(telegraph_duration)
	var tween := create_tween()
	tween.tween_interval(telegraph_duration)
	tween.tween_callback(_begin_charge)

# Faza CHARGE: natarcie w ZABLOKOWANA pozycje (a nie biezaca gracza) - dlatego do unikniecia.
func _begin_charge() -> void:
	if is_dying:
		phase = Phase.TRACK
		return
	_hide_telegraph()  # wind-up skonczony - telegraf gasnie tuz przed natarciem
	phase = Phase.CHARGE
	var tween := create_tween()
	tween.tween_property(self, "global_position", _charge_target, charge_duration)
	tween.tween_callback(_end_charge)

func _end_charge() -> void:
	_hide_telegraph()  # bezpiecznik - telegraf nie zostaje po szarzy
	phase = Phase.TRACK

# Pokazuje telegraf szarzy na czas wind-upu. Respektuje dostepnosc: reduce_flashing ->
# stale lagodne swiecenie zamiast narastajacej pulsacji.
func _show_telegraph(duration: float) -> void:
	if _telegraph == null:
		return
	_telegraph.visible = true
	_telegraph.modulate.a = 0.0
	if not SettingsStore.should_flash(SettingsStore.reduce_flashing):
		_telegraph.modulate.a = 0.95
		return
	var tween := create_tween()
	var pulses: int = GameConfig.MINIBOSS_TELEGRAPH_PULSES
	var half: float = duration / float(maxi(pulses, 1) * 2)
	for i in pulses:
		# Overbright (>1) na blendzie additive - mocny, narastajacy ku szarzy rozblysk.
		var peak: float = lerpf(0.9, 1.6, float(i + 1) / float(pulses))
		tween.tween_property(_telegraph, "modulate:a", peak, half)
		tween.tween_property(_telegraph, "modulate:a", peak * 0.5, half)

func _hide_telegraph() -> void:
	if _telegraph != null:
		_telegraph.visible = false
		_telegraph.modulate.a = 0.0

# Wizualny telegraf wind-upu: pulsujace rozjasnienie sprite'a, by gracz jednoznacznie
# odczytal nadchodzaca szarze. Respektuje dostepnosc: przy wlaczonym "reduce flashing"
# telegraf jest pojedynczy i lagodny (bez migotania).
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

# Czysta funkcja: czy w danej fazie ruch sledzacy jest zablokowany (telegraf/szarza).
static func is_locked(p: int) -> bool:
	return p == Phase.TELEGRAPH or p == Phase.CHARGE

## Czysta funkcja: plynny obrot ku zadanemu katowi przez lerp_angle. Interpolacja
## najkrotsza droga (poprawne owijanie 2*PI), waga przycieta do [0,1] - brak przeskoku
## nawet przy duzym delta. Zwraca nowy kat w radianach.
##
## @param current    - biezacy kat (rad).
## @param target     - docelowy kat (rad).
## @param turn_speed - szybkosc obrotu (1/s); wieksza = szybsze dojscie.
## @param delta      - czas klatki (s).
static func aim_rotation(current: float, target: float, turn_speed: float, delta: float) -> float:
	return lerp_angle(current, target, clampf(turn_speed * delta, 0.0, 1.0))

# Kolysanie idle: Tween pętla na LOKALNYM Sprite2D.position:y. Rozlaczne z szarza
# (global_position ciala), telegrafem (modulate) i celowaniem (rotation ciala).
func _start_idle_bob() -> void:
	var sprite := get_node_or_null("Sprite2D")
	if sprite == null:
		return
	var base_y: float = sprite.position.y
	var h: float = GameConfig.MINIBOSS_BOB_PERIOD * 0.5
	var t := create_tween().set_loops()
	t.tween_property(sprite, "position:y", base_y - GameConfig.MINIBOSS_BOB_AMOUNT, h).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(sprite, "position:y", base_y + GameConfig.MINIBOSS_BOB_AMOUNT, h).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_health_changed() -> void:
	if hp_bar:
		hp_bar.value = health

func _on_death() -> void:
	boss_defeated.emit(global_position)
