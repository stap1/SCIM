extends GutTest

# P1.5: neutralny SettingsStore (autoload) jest jedynym wlascicielem trwalosci ustawien
# + czystych funkcji audio/accessibility. Gameplay/audio NIE moga siegac do skryptu ekranu UI.

func test_settings_store_is_autoload() -> void:
	assert_true(ProjectSettings.has_setting("autoload/SettingsStore"),
		"SettingsStore zarejestrowany jako autoload")

# --- Czyste funkcje przeniesione do neutralnego store ---

func test_slider_to_db() -> void:
	assert_almost_eq(SettingsStore.slider_to_db(1.0), 0.0, 0.001, "slider_to_db(1.0) == 0 db")
	assert_true(SettingsStore.slider_to_db(0.0) <= -60.0, "slider_to_db(0.0) <= -60 db")

func test_accessibility_flags() -> void:
	assert_false(SettingsStore.should_apply_shake(true), "reduce wlaczone -> bez shake")
	assert_true(SettingsStore.should_apply_shake(false), "reduce wylaczone -> shake gra")
	assert_false(SettingsStore.should_flash(true), "reduce wlaczone -> bez flash")
	assert_true(SettingsStore.should_flash(false), "reduce wylaczone -> flash gra")

# --- Trwalosc (round-trip ConfigFile) ---

func test_config_round_trip() -> void:
	var path := "user://test_settings_store.cfg"
	SettingsStore.save_settings(path, 0.3, 0.7, 20, true, true)
	var s := SettingsStore.load_settings(path)
	assert_almost_eq(s["music_vol"], 0.3, 0.001, "music_vol round-trip")
	assert_almost_eq(s["sfx_vol"], 0.7, 0.001, "sfx_vol round-trip")
	assert_eq(int(s["session_length"]), 20, "session_length round-trip")
	assert_true(bool(s["reduce_shake"]), "reduce_shake round-trip")
	assert_true(bool(s["reduce_flashing"]), "reduce_flashing round-trip")

func test_load_missing_returns_defaults() -> void:
	var s := SettingsStore.load_settings("user://nie_istnieje_xyz.cfg")
	assert_almost_eq(s["music_vol"], 1.0, 0.001, "domyslna glosnosc 1.0")
	assert_eq(int(s["session_length"]), 5, "domyslna sesja 5")
	assert_false(bool(s["reduce_shake"]), "domyslnie bez redukcji shake")
	assert_eq(str(s["control_mode"]), "", "brak zapisu trybu -> pusty (sanityzacja da default platformy)")

func test_control_mode_round_trip() -> void:
	var path := "user://test_settings_store_ctrl.cfg"
	SettingsStore.save_settings(path, 1.0, 1.0, 5, false, false, ControlModes.MOUSE_FOLLOW)
	var s := SettingsStore.load_settings(path)
	assert_eq(str(s["control_mode"]), ControlModes.MOUSE_FOLLOW, "tryb sterowania round-trip")

func test_control_mode_live_setter_emits_signal() -> void:
	var got: Array[String] = []
	var cb := func(m: String) -> void: got.append(m)
	SettingsStore.control_mode_changed.connect(cb)
	var prev: String = SettingsStore.control_mode
	SettingsStore.control_mode = ControlModes.MOUSE_CLICK
	SettingsStore.control_mode = prev # przywroc stan (testy nie moga zostawiac smieci)
	SettingsStore.control_mode_changed.disconnect(cb)
	assert_true(ControlModes.MOUSE_CLICK in got,
		"zmiana trybu emituje control_mode_changed (joystick/UI reaguja na zywo)")

# apply_saved zapisuje ustawienia do SettingsStore - patrz test_state_separation.gd (P1.6).

# --- REGRESJA P1.5: brak couplingu gameplay/audio -> skrypt ekranu UI ---

func test_no_coupling_to_ui_settings_script() -> void:
	var decoupled := [
		"res://scripts/player/boat.gd",
		"res://scripts/systems/audio_manager.gd",
		"res://scripts/ui/level_up.gd",
	]
	for p in decoupled:
		var f := FileAccess.open(p, FileAccess.READ)
		assert_not_null(f, "plik istnieje: %s" % p)
		if f:
			var src := f.get_as_text()
			f.close()
			assert_false(src.contains("scripts/ui/settings.gd"),
				"%s nie moze siegac do skryptu ekranu UI (uzyj SettingsStore)" % p)
