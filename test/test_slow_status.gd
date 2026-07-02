extends GutTest

# Status "spowolnienie" na wrogach (EnemyBase): fundament karty "Harpun z linka"
# oraz przyszlych sieci rybackich i spowalniajacych atakow bossow.

const HarpoonScene := preload("res://scenes/weapons/harpoon.tscn")
const EnemyScene := preload("res://scenes/enemies/enemy.tscn")

func after_each() -> void:
	GameState.reset()

# Stub wroga do testu trafienia harpunem (rejestruje obrazenia i spowolnienie).
class EnemyStub extends Node2D:
	var dmg_taken: float = 0.0
	var slow_mult_received: float = 1.0
	var slow_duration_received: float = 0.0
	func take_damage(d: float) -> void:
		dmg_taken = d
	func apply_slow(mult: float, duration: float) -> void:
		slow_mult_received = mult
		slow_duration_received = duration

# --- Status na EnemyBase (bez drzewa scen) ---

func test_apply_and_expire() -> void:
	var e := EnemyBase.new()
	assert_almost_eq(e.slow_multiplier(), 1.0, 0.001, "bez statusu pelne tempo")
	e.apply_slow(0.75, 1.5)
	assert_almost_eq(e.slow_multiplier(), 0.75, 0.001, "spowolnienie aktywne")
	e.tick_slow(1.6)
	assert_almost_eq(e.slow_multiplier(), 1.0, 0.001, "po czasie status wygasa")
	e.free()

func test_strongest_slow_wins() -> void:
	var e := EnemyBase.new()
	e.apply_slow(0.75, 1.0)
	e.apply_slow(0.55, 1.0)
	assert_almost_eq(e.slow_multiplier(), 0.55, 0.001, "silniejsze spowolnienie nadpisuje slabsze")
	e.apply_slow(0.9, 1.0)
	assert_almost_eq(e.slow_multiplier(), 0.55, 0.001, "slabsze NIE nadpisuje silniejszego")
	e.free()

func test_duration_refreshes_not_shrinks() -> void:
	var e := EnemyBase.new()
	e.apply_slow(0.75, 2.0)
	e.apply_slow(0.75, 0.5)
	e.tick_slow(1.0)
	assert_almost_eq(e.slow_multiplier(), 0.75, 0.001, "krotszy refresh nie skraca aktywnego statusu")
	e.free()

# --- Harpun naklada spowolnienie przy trafieniu ---

func test_harpoon_hit_applies_damage_and_slow() -> void:
	var h = HarpoonScene.instantiate()
	add_child_autofree(h)
	var stub := EnemyStub.new()
	add_child_autofree(stub)
	stub.add_to_group("enemies")
	h.fire(Vector2.ZERO, Vector2.RIGHT, 0, 7.0, 0.35)
	h._on_any_collision(stub)
	assert_almost_eq(stub.dmg_taken, 7.0, 0.001, "obrazenia przekazane z auto-attackera")
	assert_almost_eq(stub.slow_mult_received, 0.65, 0.001, "spowolnienie 35% -> mnoznik 0.65")
	assert_almost_eq(stub.slow_duration_received, GameConfig.HARPOON_SLOW_DURATION, 0.001,
		"czas trwania z GameConfig")

func test_harpoon_without_slow_does_not_slow() -> void:
	var h = HarpoonScene.instantiate()
	add_child_autofree(h)
	var stub := EnemyStub.new()
	add_child_autofree(stub)
	stub.add_to_group("enemies")
	h.fire(Vector2.ZERO, Vector2.RIGHT, 0, 5.0, 0.0)
	h._on_any_collision(stub)
	assert_almost_eq(stub.slow_mult_received, 1.0, 0.001, "bez karty brak spowolnienia")

# --- Spowolniony wrog realnie plynie wolniej ---

func test_slowed_enemy_moves_slower() -> void:
	var player_stub := Node2D.new()
	player_stub.position = Vector2(500, 0)
	player_stub.add_to_group("player")
	add_child_autofree(player_stub)
	var e: Node = EnemyScene.instantiate()
	add_child_autofree(e)
	e.set_target(player_stub)
	e.apply_slow(0.5, 10.0)
	await wait_physics_frames(2)
	assert_almost_eq(e.velocity.length(), float(e.speed) * 0.5, 1.0,
		"spowolniony wrog plynie z polowa tempa")