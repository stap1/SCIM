extends EnemyBase

# Zwykly wrog (Jellyfish + warianty Barracuda/Shark przez nadpisania w .tscn).
# Wspolna logika (health/is_dying/die/take_damage/set_target/grupa) w EnemyBase.

# Sygnal niesie pozycje (dla efektu) ORAZ xp_value (ile warty jest zrzucony orb).
signal died(position: Vector2, xp_value: int)

# Eksporty specyficzne dla zwyklego wroga (boss ich nie ma).
@export var speed: float = GameConfig.ENEMY_JELLYFISH_SPEED
# Wartosc orba XP zrzucanego po smierci (mocniejsi wrogowie = wiecej).
@export var xp_value: int = GameConfig.XP_ORB_VALUE
# Drapiezniki (barakuda/rekin) obracaja sie paszcza ku graczowi; meduzy nie (bezksztaltne).
@export var face_target: bool = false
@export var turn_speed: float = 8.0

func _init() -> void:
	# Bazowe wartosci (meduza) z GameConfig; barracuda/shark nadpisuja w .tscn.
	max_health = GameConfig.ENEMY_JELLYFISH_HP
	kill_score = GameConfig.ENEMY_JELLYFISH_SCORE

func _ready() -> void:
	super._ready()
	if has_node("SpawnSound"):
		$SpawnSound.play()

func _physics_process(delta: float) -> void:
	if GameState.is_paused or GameState.is_game_over:
		return
	if not acquire_target():
		return
	var dir := (target.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()
	# Obrot ciala paszcza ku graczowi (tekstura wskazuje gore -> +PI/2, jak boss/gracz).
	if face_target and not dir.is_zero_approx():
		var desired := dir.angle() + PI / 2.0
		rotation = lerp_angle(rotation, desired, clampf(turn_speed * delta, 0.0, 1.0))

func _on_death() -> void:
	# Sygnal niesie pozycje + wartosc orba ZANIM wezel zniknie - spawner reaguje niezaleznie.
	died.emit(global_position, xp_value)
