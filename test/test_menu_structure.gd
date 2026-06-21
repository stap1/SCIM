extends GutTest

# R2: struktura menu (7 pozycji, NOWA GRA wyszarzona), ustawienia (5 aktywne, 10/15 wyszarzone),
# ekran CREDITS.

const MenuScene := preload("res://scenes/MainMenu.tscn")
const SettingsScene := preload("res://scenes/Settings.tscn")
const CreditsScene := preload("res://scenes/Credits.tscn")
const SettingsScript := preload("res://scripts/ui/settings.gd")

func test_menu_has_seven_options() -> void:
	var m = MenuScene.instantiate()
	add_child_autofree(m)
	var menu = m.get_node_or_null("Menu")
	assert_not_null(menu, "VBox Menu istnieje")
	for n in ["QuickGameButton", "NewGameButton", "UpgradesButton", "SettingsButton",
			"ScoresButton", "CreditsButton", "QuitButton"]:
		assert_not_null(menu.get_node_or_null(n), "przycisk %s istnieje" % n)

func test_new_game_disabled_quick_active() -> void:
	var m = MenuScene.instantiate()
	add_child_autofree(m)
	assert_true(m.get_node("Menu/NewGameButton").disabled, "NOWA GRA wyszarzona")
	assert_false(m.get_node("Menu/QuickGameButton").disabled, "SZYBKA GRA aktywna")

func test_session_lengths_const() -> void:
	assert_eq(SettingsScript.SESSION_LENGTHS, [5, 10, 15], "opcje 5/10/15")
	assert_eq(SettingsScript.SESSION_ENABLED, 5, "aktywne tylko 5")

func test_settings_disables_longer_sessions() -> void:
	var s = SettingsScene.instantiate()
	add_child_autofree(s)
	var opt = s.get_node_or_null("Panel/SessionOption")
	assert_not_null(opt, "SessionOption istnieje")
	assert_eq(opt.item_count, 3, "3 opcje sesji")
	assert_false(opt.is_item_disabled(0), "5 min aktywne")
	assert_true(opt.is_item_disabled(1), "10 min wyszarzone")
	assert_true(opt.is_item_disabled(2), "15 min wyszarzone")
	assert_not_null(s.get_node_or_null("Panel/SessionNote"), "notka o dluzszych sesjach")

func test_credits_loads_with_back() -> void:
	assert_true(ResourceLoader.exists(ScenePaths.CREDITS), "scena CREDITS istnieje")
	var c = CreditsScene.instantiate()
	add_child_autofree(c)
	assert_not_null(c.get_node_or_null("Panel/BackButton"), "CREDITS ma przycisk powrotu")
