extends GutTest

# FAZA 5 (juice): kontrakty komponentow/materialow. Ruch Tween/GPU jest wizualny -
# testujemy strukture i konfiguracje (gdzie sa realne bledy), nie klatka po klatce.

func test_idle_profiles_in_config() -> void:
	for k in ["barracuda", "shark"]:
		assert_true(GameConfig.ENEMY_IDLE.has(k), "profil idle '%s' w GameConfig" % k)
		for key in ["bob_amount", "bob_period", "sway_amount", "sway_period"]:
			assert_true(GameConfig.ENEMY_IDLE[k].has(key), "%s ma %s" % [k, key])

func test_barracuda_has_idle_component() -> void:
	var e = preload("res://scenes/enemies/barracuda.tscn").instantiate()
	add_child_autofree(e)
	var idle = e.get_node_or_null("EnemyIdle")
	assert_not_null(idle, "barracuda ma wezel EnemyIdle")
	if idle:
		assert_eq(idle.profile, "barracuda", "profil = barracuda")

func test_shark_has_idle_component() -> void:
	var e = preload("res://scenes/enemies/shark.tscn").instantiate()
	add_child_autofree(e)
	var idle = e.get_node_or_null("EnemyIdle")
	assert_not_null(idle, "rekin ma wezel EnemyIdle")
	if idle:
		assert_eq(idle.profile, "shark", "profil = shark")

func test_jellyfish_has_wobble_material() -> void:
	var e = preload("res://scenes/enemies/enemy.tscn").instantiate()
	add_child_autofree(e)
	var sprite = e.get_node_or_null("Sprite2D")
	assert_not_null(sprite, "meduza ma Sprite2D")
	if sprite:
		var mat := sprite.material as ShaderMaterial
		assert_not_null(mat, "Sprite2D meduzy ma ShaderMaterial (wobble)")
		if mat:
			assert_true(mat.shader.resource_path.ends_with("wobble.gdshader"), "uzywa wobble.gdshader")

func test_wobble_material_shared() -> void:
	# Jeden wspoldzielony material dla wszystkich meduz (koszt web).
	var a = preload("res://scenes/enemies/enemy.tscn").instantiate()
	var b = preload("res://scenes/enemies/enemy.tscn").instantiate()
	add_child_autofree(a)
	add_child_autofree(b)
	assert_eq(a.get_node("Sprite2D").material, b.get_node("Sprite2D").material,
		"meduzy wspoldziela ten sam material (nie kopia per instancja)")

func test_boss_has_idle_bob() -> void:
	var b = preload("res://scenes/enemies/motor_boat.tscn").instantiate()
	assert_true(b.has_method("_start_idle_bob"), "boss ma _start_idle_bob (kolysanie Sprite'a)")
	b.free()

func test_plank_has_drift() -> void:
	var p = preload("res://scenes/heal_plank.tscn").instantiate()
	assert_true(p.has_method("_start_drift"), "deska ma _start_drift")
	p.free()
