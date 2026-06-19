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
	for param in ["noise_tex", "noise_tex_2", "normal_tex"]:
		var tex = mat.get_shader_parameter(param)
		assert_not_null(tex, "uniform %s podpiety" % param)
		assert_true(tex is Texture2D, "uniform %s to Texture2D" % param)
