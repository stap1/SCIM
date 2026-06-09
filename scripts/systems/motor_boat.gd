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
## Pozycja szarzy zablokowana na poczatku telegrafu. Boss celuje w nia juz w wind-upie
## (obrot staje sie czescia telegrafu) i tam natrze - dlatego szarza jest do unikniecia:
## gracz, ktory odejdzie po rozpoczeciu telegrafu, nie zostanie trafiony.
var _charge_target: Vector2 = Vector2.ZERO

@onready var hp_bar: ProgressBar = get_node_or_null("HpBar")

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

	_charge_timer = Timer.new()
	_charge_timer.wait_time = charge_interval
	_charge_timer.autostart = true
	_charge_timer.timeout.connect(_on_charge)
	add_child(_charge_timer)

func _physics_process(delta: float) -> void:
	if GameState.is_paused or GameState.is_game_over:
		return
	_face_aim(delta) # obrot dziala w KAZDEJ fazie (sledzenie i szarza)
	# Swobodny ruch (sledzenie) tylko w fazie TRACK; telegraf zatrzymuje, szarza steruje Tweenem.
	if is_locked(phase):
		return
	if not acquire_target():
		return
	velocity = (target.global_position - global_position).normalized() * track_speed
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
	# Zablokuj cel juz teraz: aim (obrot) i szarza ida w to samo miejsce, a gracz moze uciec.
	if target != null and is_instance_valid(target):
		_charge_target = target.global_position
	charge_telegraph.emit(telegraph_duration)
	_flash_telegraph()
	var tween := create_tween()
	tween.tween_interval(telegraph_duration)
	tween.tween_callback(_begin_charge)

# Faza CHARGE: natarcie w ZABLOKOWANA pozycje (a nie biezaca gracza) - dlatego do unikniecia.
func _begin_charge() -> void:
	if is_dying:
		phase = Phase.TRACK
		return
	phase = Phase.CHARGE
	var tween := create_tween()
	tween.tween_property(self, "global_position", _charge_target, charge_duration)
	tween.tween_callback(_end_charge)

func _end_charge() -> void:
	phase = Phase.TRACK

# Subtelny blysk wind-upu (placeholder telegrafu wizualnego; pelny efekt G4 pozniej).
func _flash_telegraph() -> void:
	modulate = Color(1.6, 1.4, 0.6)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1), telegraph_duration)

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

func _on_health_changed() -> void:
	if hp_bar:
		hp_bar.value = health

func _on_death() -> void:
	boss_defeated.emit(global_position)
