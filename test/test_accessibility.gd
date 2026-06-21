extends GutTest

# Behawioralne testy dostepnosci: czy flagi REALNIE tlumia efekty w miejscach uzycia
# (nie tylko czyste should_*). reduce_shake -> brak trzesienia kamery; reduce_flashing -> brak blysku.

const BoatScene := preload("res://scenes/player/boat.tscn")
const LevelUpScene := preload("res://scenes/ui/level_up.tscn")

func before_each() -> void:
	GameState.reset()

func after_each() -> void:
	SettingsStore.reduce_shake = false
	SettingsStore.reduce_flashing = false

func test_shake_suppressed_when_reduced() -> void:
	var boat = BoatScene.instantiate()
	add_child_autofree(boat)
	await wait_physics_frames(1)
	var cam = boat.get_node("Camera2D")
	cam.offset = Vector2.ZERO
	SettingsStore.reduce_shake = true
	boat._do_shake()
	assert_eq(cam.offset, Vector2.ZERO, "reduce_shake -> kamera nie drga")

func test_shake_applied_when_enabled() -> void:
	var boat = BoatScene.instantiate()
	add_child_autofree(boat)
	await wait_physics_frames(1)
	var cam = boat.get_node("Camera2D")
	cam.offset = Vector2.ZERO
	SettingsStore.reduce_shake = false
	boat._do_shake()
	assert_ne(cam.offset, Vector2.ZERO, "bez redukcji -> trzesienie kamery (offset != 0)")

func test_flash_suppressed_when_reduced() -> void:
	var lu = LevelUpScene.instantiate()
	add_child_autofree(lu)
	await wait_physics_frames(1)
	var flash = lu.get_node("Flash")
	flash.color.a = 0.0
	SettingsStore.reduce_flashing = true
	lu._flash()
	assert_almost_eq(flash.color.a, 0.0, 0.001, "reduce_flashing -> brak blysku")

func test_flash_applied_when_enabled() -> void:
	var lu = LevelUpScene.instantiate()
	add_child_autofree(lu)
	await wait_physics_frames(1)
	var flash = lu.get_node("Flash")
	flash.color.a = 0.0
	SettingsStore.reduce_flashing = false
	lu._flash()
	assert_gt(flash.color.a, 0.0, "bez redukcji -> blysk widoczny (alpha > 0)")
