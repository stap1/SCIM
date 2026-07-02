extends GutTest

# Kontrakt wody (G3/FAZA 2). Shader GLSL = GPU, nietestowalny w GUT - testujemy styk
# GDScript<->zasob (tu wystepuja realne bledy: brak materialu, niepodpieta tekstura).

var _main: Node = null

func before_each() -> void:
	var scene := load("res://scenes/Main.tscn") as PackedScene
	assert_not_null(scene, "Main.tscn laduje sie")
	if scene:
		_main = scene.instantiate()

func after_each() -> void:
	if is_instance_valid(_main):
		_main.free()
	_main = null

func _water() -> ColorRect:
	return _main.get_node_or_null("WaterBackground") as ColorRect

func test_water_background_is_colorrect_behind() -> void:
	var w := _water()
	assert_not_null(w, "WaterBackground to ColorRect")
	if w:
		assert_eq(w.z_index, -100, "WaterBackground z_index = -100 (za gra)")

func test_water_material_is_shader() -> void:
	var w := _water()
	if w == null:
		return
	var mat := w.material as ShaderMaterial
	assert_not_null(mat, "material to ShaderMaterial")
	if mat:
		assert_not_null(mat.shader, "shader nie-null")
		assert_true(mat.shader.resource_path.ends_with("water.gdshader"), "uzywa water.gdshader")

func test_water_textures_wired() -> void:
	var w := _water()
	if w == null:
		return
	var mat := w.material as ShaderMaterial
	if mat == null:
		return
	# Po optymalizacji: JEDNA tekstura z szumami w kanalach R/G (bez normal mapy).
	var tex = mat.get_shader_parameter("noise_tex")
	assert_not_null(tex, "uniform noise_tex podpiety")
	assert_true(tex is Texture2D, "uniform noise_tex to Texture2D")
	assert_not_null(mat.get_shader_parameter("glint_strength"),
		"refleks grzbietow (glint_strength) skonfigurowany zamiast normal mapy")
	# Decyzja art-direction 2026-07-02: woda pasmowa (B1) NA STALE, 3 pasma.
	assert_almost_eq(float(mat.get_shader_parameter("band_count")), 3.0, 0.001,
		"band_count = 3 (woda toon - straznik decyzji stylu)")
	assert_almost_eq(float(mat.get_shader_parameter("glint_strength")), 0.55, 0.001,
		"stonowany refleks grzbietow (0.55)")

# --- Kolor doby: morze ciemnieje z czasem sesji (czysta funkcja) ---

func test_water_colors_follow_session_time() -> void:
	var WaterScript := preload("res://scripts/systems/water_background.gd")
	var dawn: Dictionary = WaterScript.water_colors_for(0.0, 300.0)
	assert_eq(dawn["water"], GameConfig.WATER_COLOR_DAWN, "start sesji -> kolory poranka")
	var dusk: Dictionary = WaterScript.water_colors_for(300.0, 300.0)
	assert_eq(dusk["wave"], GameConfig.WAVE_COLOR_DUSK, "koniec sesji -> kolory zmierzchu")
	var mid: Dictionary = WaterScript.water_colors_for(150.0, 300.0)
	assert_true(mid["water"] != dawn["water"] and mid["water"] != dusk["water"],
		"w polowie sesji kolor pomiedzy (plynny lerp)")
	var over: Dictionary = WaterScript.water_colors_for(999.0, 300.0)
	assert_eq(over["water"], GameConfig.WATER_COLOR_DUSK, "po koncu czasu clamp do zmierzchu")

# --- Rozblyski slonca: stemple w WakeField ---

func test_glint_scale_with_platform_boost() -> void:
	var WaterScript := preload("res://scripts/systems/water_background.gd")
	assert_almost_eq(WaterScript.glint_scale(0.0, 0.3, 0.55, 1.0), 0.3, 0.001,
		"desktop: dolna granica bez boostu")
	assert_almost_eq(WaterScript.glint_scale(1.0, 0.3, 0.55, 1.35), 0.7425, 0.001,
		"mobile: gorna granica x1.35 (ten sam mnoznik co stemple kilwatera)")
	assert_almost_eq(WaterScript.glint_scale(0.5, 0.3, 0.55, 1.0), 0.425, 0.001,
		"posrednio liniowo w widelkach")

func test_glints_deposit_into_wake_field() -> void:
	var field := WakeField.new()
	add_child_autofree(field)
	var wb := ColorRect.new()
	wb.set_script(preload("res://scripts/systems/water_background.gd"))
	wb.size = Vector2(400, 300)
	add_child_autofree(wb)
	await wait_physics_frames(1)
	GameState.reset()
	wb._tick_glints(1.0)
	wb._tick_glints(1.0)
	var alive := 0
	for i in field._born_ms.size():
		if field._born_ms[i] >= 0:
			alive += 1
	assert_gt(alive, 0, "rozblyski odkladaja stemple piany w WakeField")
	get_tree().paused = false
