extends GutTest

# REGRESJA #2: guard is_dying przeciw podwojnemu die()/queue_free() (kroki 5, 18).
# Pierwsza smierc wygrywa, kolejne wywolania die() sa ignorowane.

const EnemyScene := preload("res://scenes/enemies/enemy.tscn")

func test_die_sets_is_dying() -> void:
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	await wait_physics_frames(1)
	enemy.die()
	assert_true(enemy.is_dying, "Po die() flaga is_dying musi byc true")
	# Pozwalamy coroutine die() dokonczyc wlasne queue_free (po 1s), zeby nie zostawic sieroty.
	await wait_seconds(1.1)

func test_double_die_does_not_crash() -> void:
	var enemy = EnemyScene.instantiate()
	add_child(enemy)
	await wait_physics_frames(1)
	enemy.die()
	enemy.die() # drugie wywolanie musi byc bezpiecznie zignorowane przez guard
	assert_true(enemy.is_dying)
	pass_test("Podwojne die() nie wywolalo bledu - guard is_dying dziala")
	await wait_seconds(1.1)
