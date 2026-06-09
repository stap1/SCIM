extends GutTest

# P2.8: maszyna stanow bossa + telegraf szarzy.
# Fazy: TRACK (sledzenie) -> TELEGRAPH (wind-up, ostrzezenie) -> CHARGE (szarza) -> TRACK.
# Telegraf daje graczowi czas na reakcje; sygnal charge_telegraph pozwala podpiac wizualny blysk (G4).

const MotorBoatScene := preload("res://scenes/enemies/motor_boat.tscn")
const MotorBoatScript := preload("res://scripts/systems/motor_boat.gd")

func before_each() -> void:
	GameState.reset()

func _boss_with_target() -> Node:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	var dummy := Node2D.new()
	dummy.global_position = Vector2(500, 0)
	add_child_autofree(dummy)
	boss.set_target(dummy)
	return boss

# --- Czysta funkcja: ruch swobodny TYLKO w TRACK ---

func test_is_locked_pure() -> void:
	assert_false(MotorBoatScript.is_locked(MotorBoatScript.Phase.TRACK), "TRACK -> swobodny ruch")
	assert_true(MotorBoatScript.is_locked(MotorBoatScript.Phase.TELEGRAPH), "TELEGRAPH -> ruch zablokowany")
	assert_true(MotorBoatScript.is_locked(MotorBoatScript.Phase.CHARGE), "CHARGE -> ruch zablokowany")

# --- Maszyna stanow ---

func test_boss_has_telegraph_signal() -> void:
	var boss = _boss_with_target()
	await wait_physics_frames(1)
	assert_true(boss.has_signal("charge_telegraph"), "boss ma sygnal charge_telegraph")

func test_boss_starts_in_track_phase() -> void:
	var boss = _boss_with_target()
	await wait_physics_frames(1)
	assert_eq(boss.phase, MotorBoatScript.Phase.TRACK, "boss startuje w fazie TRACK")

func test_charge_enters_telegraph_first() -> void:
	var boss = _boss_with_target()
	await wait_physics_frames(1)
	watch_signals(boss)
	boss._on_charge()
	assert_eq(boss.phase, MotorBoatScript.Phase.TELEGRAPH,
		"_on_charge wchodzi NAJPIERW w TELEGRAPH (wind-up), nie od razu w CHARGE")
	assert_signal_emitted(boss, "charge_telegraph", "telegraf emituje sygnal (wizualne ostrzezenie)")

func test_no_charge_without_target() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	boss._on_charge()
	assert_eq(boss.phase, MotorBoatScript.Phase.TRACK, "bez celu boss nie zaczyna szarzy")

func test_dying_boss_does_not_telegraph() -> void:
	var boss = _boss_with_target()
	await wait_physics_frames(1)
	boss.is_dying = true
	boss._on_charge()
	assert_eq(boss.phase, MotorBoatScript.Phase.TRACK, "umierajacy boss nie szarzuje")

func test_no_reentry_during_sequence() -> void:
	var boss = _boss_with_target()
	await wait_physics_frames(1)
	boss._on_charge() # -> TELEGRAPH
	boss._on_charge() # powinno byc zignorowane (faza != TRACK)
	assert_eq(boss.phase, MotorBoatScript.Phase.TELEGRAPH, "drugi _on_charge w trakcie sekwencji ignorowany")

func test_begin_charge_sets_charge_phase() -> void:
	var boss = _boss_with_target()
	await wait_physics_frames(1)
	boss._begin_charge()
	assert_eq(boss.phase, MotorBoatScript.Phase.CHARGE, "po telegrafie nastepuje CHARGE")

func test_end_charge_returns_to_track() -> void:
	var boss = _boss_with_target()
	await wait_physics_frames(1)
	boss._begin_charge()
	boss._end_charge()
	assert_eq(boss.phase, MotorBoatScript.Phase.TRACK, "po szarzy powrot do TRACK")

func test_telegraph_duration_from_config() -> void:
	var boss = _boss_with_target()
	await wait_physics_frames(1)
	assert_almost_eq(boss.telegraph_duration, GameConfig.MINIBOSS_TELEGRAPH_DURATION, 0.001,
		"czas telegrafu z GameConfig")
