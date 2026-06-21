extends GutTest

# R3: meta-progresja (MetaProgress) - kupno/koszt/cap, reset (zwrot), bonusy, zapis/odczyt,
# przeliczenie wyniku na punkty, pip_lit (UI). Izolacja od realnego meta.cfg przez _path tymczasowy.

const TMP := "user://test_meta_tmp.cfg"

func before_each() -> void:
	MetaProgress._path = TMP
	MetaProgress._points = 0
	MetaProgress._levels = {}
	MetaProgress._loaded = true  # kontrolowany stan, bez ladowania z dysku

func after_each() -> void:
	# Przywroc czysty stan i realna sciezke (by inne testy nie widzialy zakupow).
	MetaProgress._levels = {}
	MetaProgress._points = 0
	MetaProgress._path = MetaProgress.PATH
	MetaProgress._loaded = false
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(TMP)

func test_buy_spends_and_levels() -> void:
	MetaProgress._points = 200
	var cost := MetaProgress.cost_of("boat", 0)
	assert_true(MetaProgress.buy("boat"), "kupno za wystarczajace punkty")
	assert_eq(MetaProgress.level_of("boat"), 1, "poziom +1")
	assert_eq(MetaProgress.points(), 200 - cost, "punkty pobrane")

func test_buy_fails_without_points() -> void:
	MetaProgress._points = 10
	assert_false(MetaProgress.buy("boat"), "brak punktow -> false")
	assert_eq(MetaProgress.level_of("boat"), 0, "poziom bez zmian")

func test_buy_capped_at_max() -> void:
	MetaProgress._points = 100000
	for i in MetaProgress.max_level_of("magnet"):
		MetaProgress.buy("magnet")
	assert_eq(MetaProgress.level_of("magnet"), MetaProgress.max_level_of("magnet"), "na maksie")
	assert_false(MetaProgress.can_buy("magnet"), "nie kupisz ponad maks")

func test_reset_refunds_all() -> void:
	MetaProgress._points = 1000
	MetaProgress.buy("boat")  # 50
	MetaProgress.buy("boat")  # 100
	assert_eq(MetaProgress.points(), 1000 - 150, "wydane 150")
	MetaProgress.reset_upgrades()
	assert_eq(MetaProgress.points(), 1000, "reset zwraca wszystkie punkty")
	assert_eq(MetaProgress.level_of("boat"), 0, "poziomy wyzerowane")

func test_bonuses_grow_with_level() -> void:
	assert_almost_eq(MetaProgress.bonus_boat_speed(), 0.0, 0.001, "poziom 0 -> brak bonusu")
	MetaProgress._points = 100000
	for i in MetaProgress.max_level_of("boat"):
		MetaProgress.buy("boat")
	assert_almost_eq(MetaProgress.bonus_boat_speed(), GameConfig.META_BOAT_SPEED_MAX, 0.001, "maks -> pelny bonus")

func test_horde_bonus_grows_with_level() -> void:
	assert_almost_eq(MetaProgress.enemy_budget_bonus(), 0.0, 0.001, "poziom 0 -> brak hordy")
	MetaProgress._points = 100000
	for i in MetaProgress.max_level_of("horde"):
		MetaProgress.buy("horde")
	assert_almost_eq(MetaProgress.enemy_budget_bonus(), GameConfig.META_HORDE_BUDGET_MAX, 0.001,
		"maks -> pelny dodatek do budzetu wrogow")

func test_magnet_mult_starts_at_one() -> void:
	assert_almost_eq(MetaProgress.bonus_magnet_mult(), 1.0, 0.001, "bez ulepszenia mnoznik 1.0")

func test_score_to_points() -> void:
	assert_eq(MetaProgress.score_to_points(0), 0, "0 -> 0")
	assert_eq(MetaProgress.score_to_points(95), 95 / GameConfig.META_POINTS_PER_SCORE, "przelicznik")

func test_save_load_roundtrip() -> void:
	MetaProgress._points = 500
	MetaProgress.buy("magnet")  # zapis do TMP, magnet=1, punkty 450
	MetaProgress._points = 0
	MetaProgress._levels = {}
	MetaProgress._load(TMP)
	assert_eq(MetaProgress.points(), 450, "punkty odczytane z dysku")
	assert_eq(MetaProgress.level_of("magnet"), 1, "poziom odczytany z dysku")

func test_pip_lit() -> void:
	assert_true(UpgradesMenu.pip_lit(3, 0), "pip 0 < poziom 3 zapalony")
	assert_true(UpgradesMenu.pip_lit(3, 2), "pip 2 < poziom 3 zapalony")
	assert_false(UpgradesMenu.pip_lit(3, 3), "pip 3 >= poziom 3 zgaszony")

func test_popup_builds_and_toggles() -> void:
	var menu = preload("res://scenes/MainMenu.tscn").instantiate()
	add_child_autofree(menu)
	var popup = menu.get_node_or_null("UpgradesMenu")
	assert_not_null(popup, "MainMenu ma UpgradesMenu")
	popup.open()
	assert_true(popup.visible, "open() pokazuje popup")
	assert_not_null(popup._points_label, "popup zbudowal UI")
	assert_eq(popup._rows.size(), 3, "3 realne ulepszenia w UI")
	popup._on_exit()
	assert_false(popup.visible, "WYJSCIE chowa popup")
