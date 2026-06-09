extends GutTest

# P2.5: pasek XP + poziom na HUD (read-only wiring przez sygnaly GameState).

const HUDScene := preload("res://scenes/ui/hud.tscn")
const HudScript := preload("res://scripts/ui/hud.gd")

func before_each() -> void:
	GameState.reset()

# --- Czyste funkcje (testowalne bez sceny) ---

func test_xp_bar_values_pure() -> void:
	assert_eq(HudScript.xp_bar_values(5, 10), Vector2i(5, 10), "xp 5/10 -> (5,10)")
	assert_eq(HudScript.xp_bar_values(0, 10), Vector2i(0, 10), "xp 0/10 -> (0,10)")
	# Max poziom (xp_to_next <= 0): pasek pelny, bez dzielenia przez zero.
	assert_eq(HudScript.xp_bar_values(0, 0), Vector2i(1, 1), "max poziom -> pasek pelny (1,1)")

func test_level_text_pure() -> void:
	assert_eq(HudScript.level_text(1), "Poziom: 1", "poziom 1")
	assert_eq(HudScript.level_text(12), "Poziom: 12", "poziom 12")

# --- Wezly istnieja w scenie HUD ---

func test_hud_has_xp_nodes() -> void:
	var hud = HUDScene.instantiate()
	add_child_autofree(hud)
	await wait_physics_frames(1)
	assert_not_null(hud.get_node_or_null("XPBar"), "HUD ma XPBar")
	assert_not_null(hud.get_node_or_null("LevelLabel"), "HUD ma LevelLabel")

# --- Wiring read-only: XPBar reaguje na xp_changed ---

func test_xp_bar_updates_on_signal() -> void:
	var hud = HUDScene.instantiate()
	add_child_autofree(hud)
	await wait_physics_frames(1)
	GameState.xp = 7
	GameState.xp_to_next = 25
	GameState.xp_changed.emit(7)
	var bar: ProgressBar = hud.get_node("XPBar")
	assert_eq(bar.max_value, 25.0, "XPBar.max_value == xp_to_next (25)")
	assert_eq(bar.value, 7.0, "XPBar.value == xp (7)")

# --- Wiring read-only: LevelLabel reaguje na level_up ---

func test_level_label_updates_on_level_up() -> void:
	var hud = HUDScene.instantiate()
	add_child_autofree(hud)
	await wait_physics_frames(1)
	GameState.level_up.emit(4)
	var label: Label = hud.get_node("LevelLabel")
	assert_true(label.text.find("4") != -1, "LevelLabel pokazuje poziom po level_up(4)")

# --- reset() inicjalizuje xp_to_next (sensowny pasek od startu sesji) ---

func test_reset_initializes_xp_to_next() -> void:
	GameState.reset()
	assert_eq(GameState.xp_to_next, GameState.xp_threshold(GameState.level),
		"reset ustawia xp_to_next na prog biezacego poziomu (pasek nie jest pusty/maxed na starcie)")
