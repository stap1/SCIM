extends GutTest

# P1.3: GameConfig - jedyne zrodlo balansu (autoload tylko-const).
# Pilnuje trzech rzeczy:
#  (1) GameConfig jest zarejestrowany jako autoload,
#  (2) kluczowe stale maja wartosci AS-BUILT (nie wartosci ze spec - hybryda),
#  (3) skrypty gry CZYTAJA wartosci z GameConfig (single-source).
# Punkt (3) to wlasciwy straznik regresji: re-hardcodowanie literalu w skrypcie
# rozjedzie go z GameConfig i obleje test.

const BoatScript := preload("res://scripts/player/boat.gd")
const HarpoonScript := preload("res://scripts/weapons/harpoon.gd")
const HarpoonPoolScript := preload("res://scripts/weapons/harpoon_pool.gd")
const AutoAttackerScript := preload("res://scripts/systems/auto_attacker.gd")
const EnemyScript := preload("res://scripts/systems/enemy.gd")
const MotorBoatScript := preload("res://scripts/systems/motor_boat.gd")
const SpawnerScript := preload("res://scripts/systems/enemy_spawner.gd")
const XpOrbScript := preload("res://scripts/systems/xp_orb.gd")

# --- (1) Rejestracja autoloadu ---

func test_game_config_autoload_registered() -> void:
	assert_true(ProjectSettings.has_setting("autoload/GameConfig"),
		"GameConfig musi byc zarejestrowany jako autoload (jedyne zrodlo balansu)")

# --- (2) Wartosci stalych (AS-BUILT) ---

func test_player_constants() -> void:
	assert_almost_eq(GameConfig.PLAYER_MAX_HP, 100.0, 0.001, "PLAYER_MAX_HP 100")
	assert_almost_eq(GameConfig.PLAYER_MAX_SPEED, 200.0, 0.001, "PLAYER_MAX_SPEED 200")
	assert_almost_eq(GameConfig.PLAYER_ACCELERATION, 600.0, 0.001, "PLAYER_ACCELERATION 600")
	assert_almost_eq(GameConfig.PLAYER_FRICTION, 700.0, 0.001, "PLAYER_FRICTION 700")
	assert_almost_eq(GameConfig.PLAYER_CONTACT_DAMAGE, 10.0, 0.001, "PLAYER_CONTACT_DAMAGE 10")
	assert_almost_eq(GameConfig.PLAYER_HIT_COOLDOWN, 0.5, 0.001, "PLAYER_HIT_COOLDOWN 0.5")

func test_harpoon_constants() -> void:
	assert_almost_eq(GameConfig.HARPOON_DAMAGE, 5.0, 0.001, "HARPOON_DAMAGE 5")
	assert_almost_eq(GameConfig.HARPOON_SPEED, 400.0, 0.001, "HARPOON_SPEED 400")
	assert_almost_eq(GameConfig.HARPOON_LIFETIME, 3.0, 0.001, "HARPOON_LIFETIME 3")
	assert_almost_eq(GameConfig.HARPOON_BASE_INTERVAL, 0.8, 0.001, "HARPOON_BASE_INTERVAL 0.8")
	assert_almost_eq(GameConfig.HARPOON_BASE_RANGE, 350.0, 0.001, "HARPOON_BASE_RANGE 350")
	assert_eq(GameConfig.HARPOON_POOL_SIZE, 30, "HARPOON_POOL_SIZE 30")

func test_enemy_and_miniboss_constants() -> void:
	assert_almost_eq(GameConfig.ENEMY_JELLYFISH_SPEED, 80.0, 0.001, "ENEMY_JELLYFISH_SPEED 80")
	assert_almost_eq(GameConfig.ENEMY_JELLYFISH_HP, 10.0, 0.001, "ENEMY_JELLYFISH_HP 10")
	assert_eq(GameConfig.ENEMY_JELLYFISH_SCORE, 1, "ENEMY_JELLYFISH_SCORE 1")
	assert_eq(GameConfig.ENEMY_MAX_COUNT, 30, "ENEMY_MAX_COUNT 30")
	assert_almost_eq(GameConfig.MINIBOSS_HP, 300.0, 0.001, "MINIBOSS_HP 300")
	assert_eq(GameConfig.MINIBOSS_SCORE, 500, "MINIBOSS_SCORE 500")
	assert_almost_eq(GameConfig.MINIBOSS_SPAWN_TIME, 270.0, 0.001, "MINIBOSS_SPAWN_TIME 270")
	assert_almost_eq(GameConfig.MINIBOSS_WARNING, 2.0, 0.001, "MINIBOSS_WARNING 2")

func test_xp_constants() -> void:
	assert_eq(GameConfig.XP_ORB_VALUE, 1, "XP_ORB_VALUE 1")
	assert_almost_eq(GameConfig.XP_PICKUP_RADIUS, 30.0, 0.001, "XP_PICKUP_RADIUS 30")
	assert_almost_eq(GameConfig.XP_MAGNET_SPEED, 250.0, 0.001, "XP_MAGNET_SPEED 250")
	assert_almost_eq(GameConfig.XP_MAGNET_RANGE, 120.0, 0.001, "XP_MAGNET_RANGE 120")
	assert_almost_eq(GameConfig.XP_ORB_LIFETIME, 12.0, 0.001, "XP_ORB_LIFETIME 12")

# --- (3) Single-source: skrypty CZYTAJA z GameConfig ---
# .new() uruchamia inicjalizatory @export (czyta GameConfig), nie odpala _ready.

func test_boat_reads_from_config() -> void:
	var b = BoatScript.new()
	assert_almost_eq(b.max_speed, GameConfig.PLAYER_MAX_SPEED, 0.001, "boat.max_speed <- GameConfig")
	assert_almost_eq(b.acceleration, GameConfig.PLAYER_ACCELERATION, 0.001, "boat.acceleration <- GameConfig")
	assert_almost_eq(b.friction, GameConfig.PLAYER_FRICTION, 0.001, "boat.friction <- GameConfig")
	assert_almost_eq(b.damage_per_hit, GameConfig.PLAYER_CONTACT_DAMAGE, 0.001, "boat.damage_per_hit <- GameConfig")
	assert_almost_eq(b.hit_cooldown, GameConfig.PLAYER_HIT_COOLDOWN, 0.001, "boat.hit_cooldown <- GameConfig")
	b.free()

func test_harpoon_reads_from_config() -> void:
	var h = HarpoonScript.new()
	assert_almost_eq(h.damage, GameConfig.HARPOON_DAMAGE, 0.001, "harpoon.damage <- GameConfig")
	assert_almost_eq(h.speed, GameConfig.HARPOON_SPEED, 0.001, "harpoon.speed <- GameConfig")
	h.free()

func test_harpoon_pool_reads_from_config() -> void:
	var p = HarpoonPoolScript.new()
	assert_eq(p.pool_size, GameConfig.HARPOON_POOL_SIZE, "harpoon_pool.pool_size <- GameConfig")
	p.free()

func test_auto_attacker_reads_from_config() -> void:
	var a = AutoAttackerScript.new()
	assert_almost_eq(a.attack_interval, GameConfig.HARPOON_BASE_INTERVAL, 0.001, "auto_attacker.attack_interval <- GameConfig")
	assert_almost_eq(a.attack_range, GameConfig.HARPOON_BASE_RANGE, 0.001, "auto_attacker.attack_range <- GameConfig")
	a.free()

func test_enemy_base_reads_from_config() -> void:
	var e = EnemyScript.new()
	assert_almost_eq(e.speed, GameConfig.ENEMY_JELLYFISH_SPEED, 0.001, "enemy base speed <- GameConfig")
	assert_almost_eq(e.max_health, GameConfig.ENEMY_JELLYFISH_HP, 0.001, "enemy base max_health <- GameConfig")
	assert_eq(e.kill_score, GameConfig.ENEMY_JELLYFISH_SCORE, "enemy base kill_score <- GameConfig")
	e.free()

func test_motor_boat_reads_from_config() -> void:
	var m = MotorBoatScript.new()
	assert_almost_eq(m.max_health, GameConfig.MINIBOSS_HP, 0.001, "motor_boat.max_health <- GameConfig")
	assert_eq(m.kill_score, GameConfig.MINIBOSS_SCORE, "motor_boat.kill_score <- GameConfig")
	m.free()

func test_spawner_reads_from_config() -> void:
	var s = SpawnerScript.new()
	assert_eq(s.max_enemies, GameConfig.ENEMY_MAX_COUNT, "spawner.max_enemies <- GameConfig")
	s.free()

func test_xp_orb_reads_from_config() -> void:
	var o = XpOrbScript.new()
	assert_eq(o.xp_value, GameConfig.XP_ORB_VALUE, "xp_orb.xp_value <- GameConfig")
	assert_almost_eq(o.lifetime, GameConfig.XP_ORB_LIFETIME, 0.001, "xp_orb.lifetime <- GameConfig")
	o.free()

func test_game_state_health_from_config() -> void:
	GameState.reset()
	assert_almost_eq(GameState.max_health, GameConfig.PLAYER_MAX_HP, 0.001, "reset() -> max_health z GameConfig")
	assert_almost_eq(GameState.health, GameConfig.PLAYER_MAX_HP, 0.001, "reset() -> health z GameConfig")
