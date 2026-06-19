extends GutTest

# Kontrakty wizualne (rotacja drapieznikow, materialy ruchu, tlo wody, wskaznik HP).
# Animacja Tween/GPU jest wizualna - testujemy strukture/konfiguracje.

func test_predators_face_target() -> void:
	var b = preload("res://scenes/enemies/barracuda.tscn").instantiate()
	add_child_autofree(b)
	assert_true(b.face_target, "barakuda obraca sie paszcza ku graczowi")
	var s = preload("res://scenes/enemies/shark.tscn").instantiate()
	add_child_autofree(s)
	assert_true(s.face_target, "rekin obraca sie paszcza ku graczowi")

func test_jellyfish_no_face_and_floats() -> void:
	var j = preload("res://scenes/enemies/enemy.tscn").instantiate()
	add_child_autofree(j)
	assert_false(j.face_target, "meduza sie nie obraca (bezksztaltna)")
	assert_not_null(j.get_node_or_null("EnemyIdle"), "meduza ma plyw gora-dol (EnemyIdle)")
	assert_true(GameConfig.ENEMY_IDLE.has("jellyfish"), "profil idle meduzy w GameConfig")

func test_predators_have_swim_material() -> void:
	for path in ["res://scenes/enemies/barracuda.tscn", "res://scenes/enemies/shark.tscn"]:
		var e = load(path).instantiate()
		add_child_autofree(e)
		var mat := e.get_node("Sprite2D").material as ShaderMaterial
		assert_not_null(mat, "drapieznik ma material ruchu (fish_swim)")
		if mat:
			assert_true(mat.shader.resource_path.ends_with("fish_swim.gdshader"), "uzywa fish_swim.gdshader")

func test_swim_material_shared_for_perf() -> void:
	# Wydajnosc: JEDEN wspoldzielony material dla wszystkich ryb (barakuda + rekin),
	# nie kopia per instancja - vertex shader na 4 wierzcholkach, bez fragmentu.
	var b1 = preload("res://scenes/enemies/barracuda.tscn").instantiate()
	var b2 = preload("res://scenes/enemies/barracuda.tscn").instantiate()
	var sh = preload("res://scenes/enemies/shark.tscn").instantiate()
	add_child_autofree(b1)
	add_child_autofree(b2)
	add_child_autofree(sh)
	var m: Material = b1.get_node("Sprite2D").material
	assert_eq(m, b2.get_node("Sprite2D").material, "barakudy wspoldziela ten sam material ruchu")
	assert_eq(m, sh.get_node("Sprite2D").material, "rekin wspoldziela ten sam material co barakuda")

func test_water_follows_camera_script() -> void:
	var m = preload("res://scenes/Main.tscn").instantiate()
	add_child_autofree(m)
	var w = m.get_node_or_null("WaterBackground")
	assert_not_null(w, "WaterBackground istnieje")
	if w:
		assert_not_null(w.get_script(), "WaterBackground ma skrypt podazania za kamera")

func test_hull_sprite_has_damage_shader() -> void:
	var hud = preload("res://scenes/ui/hud.tscn").instantiate()
	add_child_autofree(hud)
	var hs = hud.get_node_or_null("HullSprite")
	assert_not_null(hs, "HUD ma HullSprite")
	if hs:
		var mat := hs.material as ShaderMaterial
		assert_not_null(mat, "HullSprite ma ShaderMaterial (blend + desaturacja + zapelnienie)")
		if mat:
			assert_true(mat.shader.resource_path.ends_with("hull_health.gdshader"), "uzywa hull_health.gdshader")
