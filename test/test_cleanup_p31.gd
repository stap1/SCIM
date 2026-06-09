extends GutTest

# P3.1: porzadki - dedup format_time (TimeFormat), const sciezek scen (ScenePaths),
# jedna sciezka zbierania orba, usunieta martwa galaz get_parent w harpunie,
# death_burst lifetime z GameConfig.

const XpOrbScript := preload("res://scripts/systems/xp_orb.gd")

func _read_src(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	assert_not_null(f, "plik istnieje: %s" % path)
	if f == null:
		return ""
	var src := f.get_as_text()
	f.close()
	return src

# --- Dedup: jeden format mm:ss (TimeFormat) ---

func test_time_format_mmss() -> void:
	assert_eq(TimeFormat.mmss(75.0), "01:15", "75s -> 01:15")
	assert_eq(TimeFormat.mmss(5.0), "00:05", "5s -> 00:05")
	assert_eq(TimeFormat.mmss(0.0), "00:00", "0s -> 00:00")
	assert_eq(TimeFormat.mmss(3661.0), "61:01", "3661s -> 61:01")

func test_hud_format_time_delegates() -> void:
	# HUD zachowuje publiczne API format_time, ale deleguje do TimeFormat (jeden wzor).
	var HudScript := load("res://scripts/ui/hud.gd")
	assert_eq(HudScript.format_time(75.0), TimeFormat.mmss(75.0), "HUD.format_time == TimeFormat.mmss")

func test_game_over_has_no_local_format_time() -> void:
	var src := _read_src("res://scripts/ui/game_over.gd")
	assert_false(src.contains("func _format_time"),
		"game_over nie ma wlasnej kopii _format_time (dedup -> TimeFormat)")

# --- Const sciezek scen (ScenePaths) ---

func test_scene_paths_consts() -> void:
	assert_eq(ScenePaths.MAIN_MENU, "res://scenes/MainMenu.tscn", "ScenePaths.MAIN_MENU")
	assert_eq(ScenePaths.MAIN, "res://scenes/Main.tscn", "ScenePaths.MAIN")
	assert_eq(ScenePaths.SCORES, "res://scenes/Scores.tscn", "ScenePaths.SCORES")
	assert_eq(ScenePaths.SETTINGS, "res://scenes/Settings.tscn", "ScenePaths.SETTINGS")

# --- Orb: jedna sciezka zbierania (bez body_entered) ---

func test_orb_single_collect_path() -> void:
	var src := _read_src("res://scripts/systems/xp_orb.gd")
	assert_false(src.contains("body_entered"),
		"orb zbiera jedna sciezka (dystans w _physics_process, bez body_entered)")
	assert_false(src.contains("_on_body_entered"), "usunieto handler kontaktu orba")

func test_orb_still_collects_once() -> void:
	# Zbieranie nadal dziala (przez _collect) i jest jednorazowe (guard).
	var orb = preload("res://scenes/xp_orb.tscn").instantiate()
	add_child_autofree(orb)
	await wait_physics_frames(1)
	GameState.reset()
	var before: int = GameState.xp
	var ov: int = orb.xp_value
	orb._collect()
	orb._collect()
	assert_eq(GameState.xp, before + ov, "orb zbiera xp dokladnie raz")

# --- Harpun: usunieta martwa galaz get_parent ---

func test_harpoon_no_dead_get_parent_branch() -> void:
	var src := _read_src("res://scripts/weapons/harpoon.gd")
	assert_false(src.contains("get_parent"),
		"harpoon nie ma martwej galezi get_parent (wrog jest bezposrednio w grupie)")

# --- death_burst lifetime z GameConfig ---

func test_death_burst_lifetime_config_exists() -> void:
	assert_almost_eq(GameConfig.DEATH_BURST_LIFETIME, 1.5, 0.001,
		"GameConfig ma DEATH_BURST_LIFETIME (= dotychczasowe 1.5)")
	var src := _read_src("res://scripts/systems/death_burst.gd")
	assert_true(src.contains("GameConfig.DEATH_BURST_LIFETIME"),
		"death_burst czyta lifetime z GameConfig (bez zahardkodowanego 1.5)")
