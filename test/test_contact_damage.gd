extends GutTest

# P2.4: obrazenia kontaktowe sa PER-WROG. Kazdy wrog niesie contact_damage (EnemyBase),
# lodz czyta wartosc z trafionego wroga zamiast stalego damage_per_hit.

const BoatScene := preload("res://scenes/player/boat.tscn")
const EnemyScene := preload("res://scenes/enemies/enemy.tscn")
const MotorBoatScene := preload("res://scenes/enemies/motor_boat.tscn")

func before_each() -> void:
	GameState.health = GameState.max_health
	GameState.is_game_over = false

# --- Wrogowie niosa contact_damage z GameConfig ---

func test_enemy_has_contact_damage() -> void:
	var e = EnemyScene.instantiate()
	add_child_autofree(e)
	await wait_physics_frames(1)
	assert_true("contact_damage" in e, "wrog ma pole contact_damage (z EnemyBase)")
	assert_almost_eq(e.contact_damage, GameConfig.ENEMY_CONTACT_DAMAGE, 0.001,
		"zwykly wrog: contact_damage z GameConfig")

func test_boss_hits_harder_than_regular() -> void:
	var e = EnemyScene.instantiate()
	var b = MotorBoatScene.instantiate()
	add_child_autofree(e)
	add_child_autofree(b)
	await wait_physics_frames(1)
	assert_almost_eq(b.contact_damage, GameConfig.MINIBOSS_CONTACT_DAMAGE, 0.001,
		"boss: contact_damage z GameConfig")
	assert_gt(b.contact_damage, e.contact_damage, "mini-boss rani mocniej niz zwykly wrog")

# --- Lodz czyta obrazenia z trafionego wroga ---

func test_boat_reads_damage_from_enemy() -> void:
	var boat = BoatScene.instantiate()
	add_child_autofree(boat)
	var e = EnemyScene.instantiate()
	add_child_autofree(e)
	await wait_physics_frames(1)
	e.contact_damage = 7.5
	assert_almost_eq(boat.contact_damage_of(e), 7.5, 0.001, "lodz czyta contact_damage z wroga")

func test_boat_fallback_when_no_contact_damage() -> void:
	var boat = BoatScene.instantiate()
	add_child_autofree(boat)
	var plain := Node2D.new()
	add_child_autofree(plain)
	await wait_physics_frames(1)
	assert_almost_eq(boat.contact_damage_of(plain), boat.damage_per_hit, 0.001,
		"bez pola contact_damage lodz uzywa fallbacku damage_per_hit")
	assert_almost_eq(boat.contact_damage_of(null), boat.damage_per_hit, 0.001,
		"null -> fallback")

# --- Trafienie nadal idzie przez GameState z cooldownem (parametr: ile obrazen) ---

func test_take_hit_routes_amount_through_gamestate() -> void:
	var boat = BoatScene.instantiate()
	add_child_autofree(boat)
	await wait_physics_frames(1)
	GameState.health = 100.0
	boat.time_since_last_hit = 1.0 # poza cooldownem
	boat.try_take_enemy_hit(25.0)
	assert_almost_eq(GameState.health, 75.0, 0.001, "obrazenia per-wrog (25) ida przez GameState")
	boat.try_take_enemy_hit(25.0) # w cooldownie - zignorowane
	assert_almost_eq(GameState.health, 75.0, 0.001, "cooldown blokuje drugie trafienie")
