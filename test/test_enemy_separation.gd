extends GutTest

# Separacja wrogow: "kolizja na pol rozmiaru" - wrogowie moga nachodzic na siebie
# do polowy sumy promieni, ponizej sa rozpychani. Zapobiega pelnemu stackowaniu cial
# (i kilwaterow: nalozone smugi psuly odbior i wydajnosc).

const EnemyScene := preload("res://scenes/enemies/enemy.tscn")

func after_each() -> void:
	GameState.reset()

# --- Czysta funkcja separation_dir (para wrogow) ---

func test_no_push_when_far_apart() -> void:
	var push := EnemyBase.separation_dir(Vector2.ZERO, 14.0, Vector2(100, 0), 14.0, 0.5)
	assert_eq(push, Vector2.ZERO, "daleko od siebie -> brak odpychania")

func test_no_push_at_half_overlap_threshold() -> void:
	# Prog = (14+14) * 0.5 = 14 px: dokladnie na progu jeszcze bez odpychania.
	var push := EnemyBase.separation_dir(Vector2.ZERO, 14.0, Vector2(14, 0), 14.0, 0.5)
	assert_eq(push, Vector2.ZERO, "na progu polowy rozmiaru -> jeszcze bez pchniecia")

func test_push_away_inside_threshold() -> void:
	var push := EnemyBase.separation_dir(Vector2.ZERO, 14.0, Vector2(7, 0), 14.0, 0.5)
	assert_true(push.x < 0.0, "pcha OD sasiada (sasiad z prawej -> pchniecie w lewo)")
	assert_almost_eq(push.y, 0.0, 0.001, "pchniecie wzdluz osi laczacej")
	assert_almost_eq(push.length(), 0.5, 0.001, "w polowie progu -> polowa sily [0..1]")

func test_full_overlap_gives_full_push() -> void:
	var push := EnemyBase.separation_dir(Vector2(5, 5), 14.0, Vector2(5, 5), 14.0, 0.5)
	assert_almost_eq(push.length(), 1.0, 0.001, "pelne nalozenie -> pelna sila")

func test_push_mirrored_between_pair() -> void:
	var a := EnemyBase.separation_dir(Vector2.ZERO, 14.0, Vector2(0, 8), 14.0, 0.5)
	var b := EnemyBase.separation_dir(Vector2(0, 8), 14.0, Vector2.ZERO, 14.0, 0.5)
	assert_eq(a, -b, "para odpycha sie lustrzanie")

# --- Scena: nachodzacy wrogowie rozjezdzaja sie w ruchu ---

func test_overlapping_enemies_separate() -> void:
	var player_stub := Node2D.new()
	player_stub.position = Vector2(400, 0)
	player_stub.add_to_group("player")
	add_child_autofree(player_stub)

	var a: Node = EnemyScene.instantiate()
	var b: Node = EnemyScene.instantiate()
	a.position = Vector2(0, -2)
	b.position = Vector2(0, 2)
	add_child_autofree(a)
	add_child_autofree(b)
	a.set_target(player_stub)
	b.set_target(player_stub)
	var initial_gap: float = a.global_position.distance_to(b.global_position)
	await wait_physics_frames(20)
	var gap: float = a.global_position.distance_to(b.global_position)
	assert_gt(gap, initial_gap + 4.0, "nalozeni wrogowie rozpychaja sie w trakcie plyniecia")
