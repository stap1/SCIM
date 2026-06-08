extends GutTest

# P2.1: odchudzenie boat.gd.
# - Licznik amunicji jest EVENT-DRIVEN: pula emituje ammo_changed, HUD slucha
#   (koniec pollingu 60x/s w boat._process; boat nie siega juz do puli/ammo_ui).
# - Jedna sciezka damage: kontakt z wrogiem tylko przez polling Hurtboxa (bez body_entered).

const HarpoonPoolScript := preload("res://scripts/weapons/harpoon_pool.gd")
const HudScene := preload("res://scenes/ui/hud.tscn")

func _make_pool(size: int) -> Node:
	var p = HarpoonPoolScript.new()
	p.pool_size = size
	add_child_autofree(p)
	return p

func _read_src(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	assert_not_null(f, "plik istnieje: %s" % path)
	if f == null:
		return ""
	var src := f.get_as_text()
	f.close()
	return src

# --- Sygnal puli ---

func test_pool_has_ammo_changed_signal() -> void:
	var p = _make_pool(3)
	assert_true(p.has_signal("ammo_changed"), "pula ma sygnal ammo_changed")

func test_firing_emits_ammo_changed_decreasing() -> void:
	var p = _make_pool(3)
	await wait_physics_frames(1)
	var before: int = p.available_count()
	watch_signals(p)
	var h = p.get_harpoon()
	h.fire(Vector2.ZERO, Vector2.RIGHT)
	assert_signal_emitted(p, "ammo_changed", "wystrzal emituje ammo_changed")
	assert_eq(p.available_count(), before - 1, "po wystrzale dostepnych o 1 mniej")

func test_deactivate_emits_ammo_changed_increasing() -> void:
	var p = _make_pool(3)
	await wait_physics_frames(1)
	var h = p.get_harpoon()
	h.fire(Vector2.ZERO, Vector2.RIGHT)
	var fired_avail: int = p.available_count()
	watch_signals(p)
	h.deactivate()
	assert_signal_emitted(p, "ammo_changed", "uspienie emituje ammo_changed")
	assert_eq(p.available_count(), fired_avail + 1, "po uspieniu dostepnych o 1 wiecej")

# --- HUD odswieza licznik ze zdarzenia (nie boat) ---

func test_hud_updates_ammo_label_from_signal() -> void:
	var p = _make_pool(3)
	var hud = HudScene.instantiate()
	add_child_autofree(hud)
	await wait_physics_frames(1)
	var label = hud.get_node_or_null("AmmoLabel")
	assert_not_null(label, "HUD ma AmmoLabel")
	# Synchronizacja poczatkowa w _ready HUD.
	assert_eq(label.text, "%d / %d" % [p.available_count(), p.total_count()],
		"HUD pokazuje stan poczatkowy puli")
	var h = p.get_harpoon()
	h.fire(Vector2.ZERO, Vector2.RIGHT)
	await wait_physics_frames(1)
	assert_eq(label.text, "%d / %d" % [p.available_count(), p.total_count()],
		"HUD odswieza licznik amunicji ze zdarzenia ammo_changed")

# --- Straznik regresji: boat odchudzony ---

func test_boat_no_ammo_polling() -> void:
	var src := _read_src("res://scripts/player/boat.gd")
	assert_false(src.contains("ammo_ui"), "boat.gd nie odpytuje grupy ammo_ui (event-driven w HUD)")
	assert_false(src.contains("harpoon_pool"), "boat.gd nie siega do puli harpunow")

func test_boat_single_damage_path() -> void:
	var src := _read_src("res://scripts/player/boat.gd")
	assert_false(src.contains("body_entered"),
		"boat.gd ma jedna sciezke damage (polling Hurtboxa, bez sygnalu body_entered)")

func test_hud_owns_ammo_display() -> void:
	var src := _read_src("res://scripts/ui/hud.gd")
	assert_true(src.contains("ammo_changed"), "HUD slucha ammo_changed z puli harpunow")
