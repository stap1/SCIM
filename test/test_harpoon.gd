extends GutTest

# KROK 9 (Prompt 9): harpun + pula (Object Pooling, bez celowania).

const HarpoonScene := preload("res://scenes/weapons/harpoon.tscn")
const HarpoonPoolScript := preload("res://scripts/weapons/harpoon_pool.gd")

func test_fire_sets_active_and_direction() -> void:
	var h = HarpoonScene.instantiate()
	add_child(h)
	await wait_physics_frames(1)
	h.fire(Vector2(0, 0), Vector2(1, 0))
	assert_true(h.active, "fire() ustawia active == true")
	assert_eq(h.direction, Vector2(1, 0), "fire() ustawia direction")
	h.free()

func test_harpoon_moves_when_active() -> void:
	var h = HarpoonScene.instantiate()
	add_child(h)
	await wait_physics_frames(1)
	h.fire(Vector2(0, 0), Vector2(1, 0))
	var start_x: float = h.global_position.x
	await wait_physics_frames(5)
	assert_gt(h.global_position.x, start_x, "aktywny harpun przesuwa sie zgodnie z direction*speed")
	h.free()

func test_get_harpoon_returns_inactive() -> void:
	var pool = HarpoonPoolScript.new()
	add_child(pool)
	await wait_physics_frames(1)
	var h = pool.get_harpoon()
	assert_not_null(h, "get_harpoon() zwraca harpun")
	assert_false(h.active, "zwrocony harpun jest nieaktywny")
	pool.free()

func test_pool_does_not_exceed_limit() -> void:
	var pool = HarpoonPoolScript.new()
	pool.pool_size = 5 # maly limit dla szybkiego testu
	add_child(pool)
	await wait_physics_frames(1)
	# Wypozyczamy i "aktywujemy" wszystkie harpuny z puli.
	for i in 5:
		var h = pool.get_harpoon()
		assert_not_null(h, "harpun %d dostepny" % i)
		h.active = true
	assert_null(pool.get_harpoon(), "po wyczerpaniu puli get_harpoon() zwraca null")
	assert_eq(pool.total_count(), 5, "pula nie przekracza limitu (5)")
	pool.free()
