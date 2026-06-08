extends GutTest

# KROK 6 (Prompt 6): kontakt gracz-wrog. Obrazenia WYLACZNIE przez GameState, z cooldownem (i-frames).

const BoatScene := preload("res://scenes/player/boat.tscn")
const BoatScript := preload("res://scripts/player/boat.gd")
const EnemyScene := preload("res://scenes/enemies/enemy.tscn")

func before_each() -> void:
	GameState.health = GameState.max_health
	GameState.is_game_over = false

func test_can_take_hit_pure() -> void:
	assert_true(BoatScript.can_take_hit(0.6, 0.5), "can_take_hit(0.6, 0.5) == true")
	assert_false(BoatScript.can_take_hit(0.2, 0.5), "can_take_hit(0.2, 0.5) == false")

func test_single_hit_reduces_health_through_gamestate() -> void:
	var boat = BoatScene.instantiate()
	GameState.health = 100.0
	boat.time_since_last_hit = 1.0 # poza cooldownem
	boat.try_take_enemy_hit()
	assert_almost_eq(GameState.health, 90.0, 0.001, "jedno trafienie: GameState.health 100 -> 90")
	boat.free()

func test_cooldown_blocks_second_hit() -> void:
	var boat = BoatScene.instantiate()
	GameState.health = 100.0
	boat.time_since_last_hit = 1.0
	boat.try_take_enemy_hit() # 100 -> 90, reset cooldownu
	boat.try_take_enemy_hit() # zablokowane (0 < 0.5)
	assert_almost_eq(GameState.health, 90.0, 0.001, "drugie trafienie w cooldownie nie zmniejsza HP")
	boat.free()

func test_hurtbox_exists_and_detects_enemy_layer() -> void:
	var boat = BoatScene.instantiate()
	var hb = boat.get_node_or_null("Hurtbox")
	assert_not_null(hb, "Lodz musi miec Hurtbox (Area2D)")
	var enemy = EnemyScene.instantiate()
	assert_ne(hb.collision_mask & enemy.collision_layer, 0,
		"maska Hurtboxa musi obejmowac warstwe wroga (inaczej kontakt nie zostanie wykryty)")
	boat.free()
	enemy.free()
