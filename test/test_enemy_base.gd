extends GutTest

# P1.4: wspolna baza EnemyBase usuwa duplikacje enemy <-> motor_boat
# (health / is_dying / target / die() / take_damage() / set_target() / grupa "enemies").
# Guard is_dying ZOSTAJE testem regresji #2 - sprawdzany tu na poziomie bazy.

const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const MotorBoatScene := preload("res://scenes/enemies/motor_boat.tscn")

func before_each() -> void:
	GameState.reset()

# --- Wspolna baza: oba typy dziedzicza z EnemyBase ---

func test_enemy_is_enemy_base() -> void:
	var e = EnemyScene.instantiate()
	add_child_autofree(e)
	await wait_physics_frames(1)
	assert_true(e is EnemyBase, "Jellyfish dziedziczy z EnemyBase")

func test_boss_is_enemy_base() -> void:
	var b = MotorBoatScene.instantiate()
	add_child_autofree(b)
	await wait_physics_frames(1)
	assert_true(b is EnemyBase, "MotorBoat dziedziczy z EnemyBase")

# --- Wspolny kontrakt (zrodlo prawdy: GameConfig dla bazowych wartosci) ---

func test_shared_init_health_and_group() -> void:
	var e = EnemyScene.instantiate()
	add_child_autofree(e)
	await wait_physics_frames(1)
	assert_eq(e.health, e.max_health, "health startuje rowne max_health (z bazy)")
	assert_eq(e.max_health, GameConfig.ENEMY_JELLYFISH_HP, "Jellyfish HP z GameConfig (nie re-hardcode)")
	assert_true(e.is_in_group("enemies"), "baza dodaje do grupy enemies")

func test_boss_init_from_game_config() -> void:
	var b = MotorBoatScene.instantiate()
	add_child_autofree(b)
	await wait_physics_frames(1)
	assert_eq(b.max_health, GameConfig.MINIBOSS_HP, "Boss HP z GameConfig (nie re-hardcode)")
	assert_eq(b.kill_score, GameConfig.MINIBOSS_SCORE, "Boss score z GameConfig")
	assert_true(b.is_in_group("enemies"), "boss tez w grupie enemies")

func test_set_target_shared() -> void:
	var e = EnemyScene.instantiate()
	add_child_autofree(e)
	var dummy := Node2D.new()
	add_child_autofree(dummy)
	await wait_physics_frames(1)
	e.set_target(dummy)
	assert_eq(e.target, dummy, "set_target z bazy ustawia cel")

# --- REGRESJA #2: guard is_dying (na poziomie bazy, oba typy) ---

func test_enemy_double_die_guarded() -> void:
	var e = EnemyScene.instantiate()
	add_child_autofree(e)
	await wait_physics_frames(1)
	var before: int = GameState.enemies_killed
	e.die()
	e.die() # drugie wywolanie ignorowane przez guard
	assert_true(e.is_dying, "is_dying ustawione")
	assert_eq(GameState.enemies_killed, before + 1, "die() liczy zabicie dokladnie raz (guard)")
	await wait_physics_frames(1)

func test_boss_double_die_guarded() -> void:
	var b = MotorBoatScene.instantiate()
	add_child_autofree(b)
	await wait_physics_frames(1)
	var before: int = GameState.enemies_killed
	b.die()
	b.die()
	assert_true(b.is_dying, "boss is_dying ustawione")
	assert_eq(GameState.enemies_killed, before + 1, "boss die() liczy zabicie raz (guard)")
	await wait_physics_frames(1)

# --- take_damage po smierci nie schodzi ponizej / nie liczy ponownie ---

func test_take_damage_after_death_ignored() -> void:
	var e = EnemyScene.instantiate()
	add_child_autofree(e)
	await wait_physics_frames(1)
	e.die()
	var killed: int = GameState.enemies_killed
	e.take_damage(999.0) # po smierci - guard w take_damage
	assert_eq(GameState.enemies_killed, killed, "take_damage po smierci nie wywoluje ponownego die()")
	await wait_physics_frames(1)
