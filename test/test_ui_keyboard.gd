extends GutTest

# Nawigacja klawiatura: menu lapie focus na otwarciu, wiec strzalki (ui_up/down/left/right),
# Enter i Spacja (ui_accept) dzialaja natywnie. Tu sprawdzamy, ze focus jest ustawiany.

const MenuScene := preload("res://scenes/MainMenu.tscn")
const LevelUpScene := preload("res://scenes/ui/level_up.tscn")
const PauseScene := preload("res://scenes/ui/pause_menu.tscn")
const GameOverScene := preload("res://scenes/ui/game_over.tscn")

const _TMP_META := "user://test_meta_ui.cfg"

func before_each() -> void:
	GameState.reset()
	# Izolacja meta (ekran konca dolicza punkty) - nie ruszaj realnego meta.cfg.
	MetaProgress._path = _TMP_META
	MetaProgress._points = 0
	MetaProgress._levels = {}
	MetaProgress._loaded = true

func after_each() -> void:
	get_tree().paused = false
	MetaProgress._path = MetaProgress.PATH
	MetaProgress._loaded = false
	if FileAccess.file_exists(_TMP_META):
		DirAccess.remove_absolute(_TMP_META)

func test_main_menu_grabs_focus() -> void:
	var m = MenuScene.instantiate()
	add_child_autofree(m)
	await wait_frames(2)
	assert_eq(get_viewport().gui_get_focus_owner(), m.get_node("Menu/QuickGameButton"),
		"menu glowne: focus na SZYBKA GRA")

func test_level_up_grabs_card_focus() -> void:
	var lu = LevelUpScene.instantiate()
	add_child_autofree(lu)
	await wait_frames(1)
	GameState.level_up.emit(2)  # -> _on_level_up pokazuje karty i lapie focus
	await wait_frames(1)
	assert_eq(get_viewport().gui_get_focus_owner(), lu.get_node("Panel/Card0"),
		"level-up: focus na pierwszej karcie")
	get_tree().paused = false

func test_pause_grabs_focus_on_open() -> void:
	var pm = PauseScene.instantiate()
	add_child_autofree(pm)
	await wait_frames(1)
	pm.toggle()  # otworz pauze
	await wait_frames(1)
	assert_eq(get_viewport().gui_get_focus_owner(), pm.get_node("Dimmer/Center/Menu/ResumeButton"),
		"pauza: focus na Wznow")
	pm.resume()

func test_upgrades_popup_returns_focus_on_close() -> void:
	# Regresja: po wyjsciu z ULEPSZEN focus musi wrocic do menu (inaczej nawigacja zamiera).
	var m = MenuScene.instantiate()
	add_child_autofree(m)
	await wait_frames(1)
	var popup = m.get_node("UpgradesMenu")
	m._on_upgrades()  # otwiera popup (focus na ulepszeniu)
	await wait_frames(1)
	popup._on_exit()  # WYJSCIE
	await wait_frames(1)
	assert_eq(get_viewport().gui_get_focus_owner(), m.get_node("Menu/UpgradesButton"),
		"po wyjsciu z ulepszen focus wraca na ULEPSZENIA (nawigacja dziala)")

func test_game_over_grabs_focus() -> void:
	var go = GameOverScene.instantiate()
	add_child_autofree(go)
	await wait_frames(1)
	GameState.trigger_game_over(false)  # -> ekran konca pokazany, focus na Ponow
	await wait_frames(1)
	assert_eq(get_viewport().gui_get_focus_owner(), go.get_node("Panel/RestartButton"),
		"ekran konca: focus na Sprobuj ponownie")
	get_tree().paused = false
