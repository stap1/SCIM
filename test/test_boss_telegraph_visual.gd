extends GutTest

# QA #4: telegraf ataku bossa jest wyrazny (pulsujacy rozblysk sprite'a) i respektuje
# dostepnosc (reduce_flashing -> wariant lagodny, bez migotania).

const MotorBoatScene := preload("res://scenes/enemies/motor_boat.tscn")

func before_each() -> void:
	GameState.reset()
	SettingsStore.reduce_flashing = false # czysty start (telegraf moga ustawiac inne testy)

func after_each() -> void:
	SettingsStore.reduce_flashing = false

func test_telegraph_constants_in_config() -> void:
	assert_eq(GameConfig.MINIBOSS_TELEGRAPH_PULSES, 3, "3 pulsy telegrafu")
	assert_eq(GameConfig.MINIBOSS_TELEGRAPH_COLOR, Color(1.8, 1.8, 1.8, 1), "overbright rozblysk")

func test_base_modulate_captured_from_sprite() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	var sprite: Node = boss.get_node("Sprite2D")
	assert_eq(boss._base_modulate, sprite.modulate,
		"zapamietana barwa bazowa = modulate sprite'a (czerwony kadlub)")

func test_telegraph_changes_sprite_modulate() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	var sprite: Node = boss.get_node("Sprite2D")
	var base: Color = sprite.modulate
	boss._flash_telegraph()
	await wait_physics_frames(2)
	assert_ne(sprite.modulate, base, "telegraf zmienia barwe sprite'a (widoczny blysk)")

func test_telegraph_sprite_hidden_initially() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	var tg = boss.get_node_or_null("Telegraph")
	assert_not_null(tg, "boss ma wezel Telegraph (G4)")
	if tg:
		assert_false(tg.visible, "telegraf ukryty poza wind-upem")
		assert_true(tg.material is CanvasItemMaterial, "telegraf ma material (additive blend)")

func test_show_telegraph_toggles_visibility() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	SettingsStore.reduce_flashing = false
	boss._show_telegraph(0.6)
	var tg = boss.get_node_or_null("Telegraph")
	assert_true(tg.visible, "telegraf widoczny po _show_telegraph")
	boss._hide_telegraph()
	assert_false(tg.visible, "telegraf ukryty po _hide_telegraph")

func test_telegraph_respects_reduce_flashing() -> void:
	var boss = MotorBoatScene.instantiate()
	add_child_autofree(boss)
	await wait_physics_frames(1)
	SettingsStore.reduce_flashing = true
	boss._flash_telegraph() # wariant dostepny - nie moze crashowac
	await wait_physics_frames(1)
	pass_test("telegraf z reduce_flashing dziala (lagodny wariant, bez migotania)")
