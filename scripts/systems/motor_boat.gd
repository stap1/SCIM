extends EnemyBase

# Mini-boss "Motorowka klusownika". Sledzi gracza i co charge_interval wykonuje szarze
# (Tween ku ostatniej pozycji gracza). HP bar nad bossem.
# Wspolna logika (health/is_dying/die/take_damage/set_target/grupa) w EnemyBase.

signal boss_defeated(position: Vector2)

# Eksporty specyficzne dla bossa (track_speed zamiast speed, parametry szarzy).
@export var track_speed: float = GameConfig.MINIBOSS_TRACK_SPEED
@export var charge_interval: float = GameConfig.MINIBOSS_CHARGE_INTERVAL
@export var charge_duration: float = GameConfig.MINIBOSS_CHARGE_DURATION

var _charging: bool = false
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
	# W trakcie szarzy pozycja jest sterowana Tweenem - nie nadpisujemy ruchem.
	if _charging:
		return
	if not acquire_target():
		return
	velocity = (target.global_position - global_position).normalized() * track_speed
	move_and_slide()

func _on_charge() -> void:
	if is_dying:
		return
	if target == null or not is_instance_valid(target):
		return
	_charging = true
	var dest := target.global_position
	var tween := create_tween()
	tween.tween_property(self, "global_position", dest, charge_duration)
	tween.tween_callback(_end_charge)

func _end_charge() -> void:
	_charging = false

func _on_health_changed() -> void:
	if hp_bar:
		hp_bar.value = health

func _on_death() -> void:
	boss_defeated.emit(global_position)
