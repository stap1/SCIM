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

func _physics_process(_delta: float) -> void:
	if GameState.is_paused or GameState.is_game_over:
		return
	# Swobodny ruch (sledzenie) tylko w fazie TRACK; telegraf zatrzymuje, szarza steruje Tweenem.
	if is_locked(phase):
		return
	if not acquire_target():
		return
	velocity = (target.global_position - global_position).normalized() * track_speed
	move_and_slide()

# Timer co charge_interval: rozpocznij sekwencje szarzy od fazy telegrafu (wind-up).
func _on_charge() -> void:
	if is_dying:
		return
	if phase != Phase.TRACK:
		return # sekwencja juz trwa - nie nakladaj faz
	if target == null or not is_instance_valid(target):
		return
	_begin_telegraph()

# Faza TELEGRAPH: boss zatrzymuje sie i sygnalizuje nadchodzaca szarze (czas na unik).
func _begin_telegraph() -> void:
	phase = Phase.TELEGRAPH
	charge_telegraph.emit(telegraph_duration)
	_flash_telegraph()
	var tween := create_tween()
	tween.tween_interval(telegraph_duration)
	tween.tween_callback(_begin_charge)

# Faza CHARGE: zablokuj cel (pozycja gracza w chwili konca telegrafu) i ruszaj Tweenem.
func _begin_charge() -> void:
	if is_dying:
		phase = Phase.TRACK
		return
	phase = Phase.CHARGE
	var dest := global_position
	if target != null and is_instance_valid(target):
		dest = target.global_position
	var tween := create_tween()
	tween.tween_property(self, "global_position", dest, charge_duration)
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

func _on_health_changed() -> void:
	if hp_bar:
		hp_bar.value = health

func _on_death() -> void:
	boss_defeated.emit(global_position)
