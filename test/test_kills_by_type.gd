extends GutTest

# B1: licznik zabic per typ (GameState.kills_by_type / register_kill / enemy_killed),
# enum Enemy.EnemyType i rozszerzony sygnal died(pos, xp, type).
# enemies_killed (suma) ZOSTAJE niezalezna (highscores/ekran konca).

const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const BarracudaScene := preload("res://scenes/enemies/barracuda.tscn")
const SharkScene := preload("res://scenes/enemies/shark.tscn")

func before_each() -> void:
	GameState.reset()

func test_register_kill_increments_and_emits() -> void:
	watch_signals(GameState)
	GameState.register_kill(Enemy.EnemyType.JELLYFISH)
	assert_eq(int(GameState.kills_by_type.get(Enemy.EnemyType.JELLYFISH, 0)), 1, "1. meduza")
	GameState.register_kill(Enemy.EnemyType.JELLYFISH)
	assert_eq(int(GameState.kills_by_type.get(Enemy.EnemyType.JELLYFISH, 0)), 2, "2. meduza")
	assert_signal_emitted_with_parameters(GameState, "enemy_killed", [Enemy.EnemyType.JELLYFISH, 2])

func test_types_counted_independently() -> void:
	GameState.register_kill(Enemy.EnemyType.JELLYFISH)
	GameState.register_kill(Enemy.EnemyType.BARRACUDA)
	GameState.register_kill(Enemy.EnemyType.BARRACUDA)
	GameState.register_kill(Enemy.EnemyType.SHARK)
	assert_eq(int(GameState.kills_by_type.get(Enemy.EnemyType.JELLYFISH, 0)), 1, "meduzy 1")
	assert_eq(int(GameState.kills_by_type.get(Enemy.EnemyType.BARRACUDA, 0)), 2, "barakudy 2")
	assert_eq(int(GameState.kills_by_type.get(Enemy.EnemyType.SHARK, 0)), 1, "rekiny 1")

func test_reset_clears_kills_by_type() -> void:
	GameState.register_kill(Enemy.EnemyType.SHARK)
	assert_false(GameState.kills_by_type.is_empty(), "po zabiciu niepusty")
	GameState.reset()
	assert_true(GameState.kills_by_type.is_empty(), "reset czysci kills_by_type")

func test_register_kill_does_not_touch_sum() -> void:
	var before: int = GameState.enemies_killed
	GameState.register_kill(Enemy.EnemyType.JELLYFISH)
	assert_eq(GameState.enemies_killed, before, "register_kill nie rusza enemies_killed (suma)")

func test_scenes_have_correct_type() -> void:
	var j = EnemyScene.instantiate()
	var b = BarracudaScene.instantiate()
	var s = SharkScene.instantiate()
	assert_eq(j.enemy_type, Enemy.EnemyType.JELLYFISH, "meduza = JELLYFISH")
	assert_eq(b.enemy_type, Enemy.EnemyType.BARRACUDA, "barakuda = BARRACUDA")
	assert_eq(s.enemy_type, Enemy.EnemyType.SHARK, "rekin = SHARK")
	j.free()
	b.free()
	s.free()

func test_died_signal_carries_type() -> void:
	var b = BarracudaScene.instantiate()
	add_child_autofree(b)
	await wait_physics_frames(1)
	watch_signals(b)
	b.die()
	assert_signal_emitted_with_parameters(b, "died",
		[b.global_position, b.xp_value, Enemy.EnemyType.BARRACUDA])
	await wait_physics_frames(1)
