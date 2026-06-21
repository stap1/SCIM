extends GutTest

# B4: dialogi Santiago - logika doboru kwestii (resolve_kill_line) i kolejka FIFO.

const BannerScene := preload("res://scenes/ui/dialogue_banner.tscn")
const Banner := preload("res://scripts/ui/dialogue_banner.gd")

func before_each() -> void:
	GameState.reset()

func test_first_barracuda_only_on_first() -> void:
	var r := Banner.resolve_kill_line(Enemy.EnemyType.BARRACUDA, 1, 0)
	assert_eq(r["line"], NarrativeData.FIRST_BARRACUDA, "1. barakuda -> kwestia")
	var r2 := Banner.resolve_kill_line(Enemy.EnemyType.BARRACUDA, 2, 0)
	assert_eq(r2["line"], "", "2. barakuda -> brak kwestii")

func test_first_shark_only_on_first() -> void:
	assert_eq(Banner.resolve_kill_line(Enemy.EnemyType.SHARK, 1, 0)["line"],
		NarrativeData.FIRST_SHARK, "1. rekin -> kwestia")
	assert_eq(Banner.resolve_kill_line(Enemy.EnemyType.SHARK, 3, 0)["line"],
		"", "kolejny rekin -> brak")

func test_jellyfish_thresholds_once() -> void:
	# Ponizej progu - nic.
	assert_eq(Banner.resolve_kill_line(Enemy.EnemyType.JELLYFISH, 5, 0)["line"], "", "5 meduz -> nic")
	# Prog 10 osiagniety.
	var r10 := Banner.resolve_kill_line(Enemy.EnemyType.JELLYFISH, 10, 0)
	assert_eq(r10["line"], NarrativeData.JELLYFISH_LINES[10], "10 -> kwestia progu 10")
	assert_eq(int(r10["last_jelly"]), 10, "prog zapamietany = 10")
	# Kolejna meduza w tym samym progu - nic.
	assert_eq(Banner.resolve_kill_line(Enemy.EnemyType.JELLYFISH, 11, 10)["line"], "",
		"11 przy last=10 -> nic (prog juz pokazany)")
	# Nastepny prog.
	var r30 := Banner.resolve_kill_line(Enemy.EnemyType.JELLYFISH, 30, 10)
	assert_eq(r30["line"], NarrativeData.JELLYFISH_LINES[30], "30 -> kwestia progu 30")
	assert_eq(int(r30["last_jelly"]), 30, "prog zapamietany = 30")

func test_highest_jelly_threshold() -> void:
	assert_eq(Banner.highest_jelly_threshold(5), -1, "ponizej 10 -> -1")
	assert_eq(Banner.highest_jelly_threshold(10), 10, "10 -> 10")
	assert_eq(Banner.highest_jelly_threshold(45), 30, "45 -> 30")
	assert_eq(Banner.highest_jelly_threshold(80), 60, "80 -> 60")

func test_queue_is_fifo() -> void:
	var banner = BannerScene.instantiate()
	add_child_autofree(banner)
	await wait_frames(1)
	banner.enqueue("A")  # pierwsza idzie od razu (busy), pisze sie
	banner.enqueue("B")
	banner.enqueue("C")
	assert_eq(banner._queue, ["B", "C"] as Array[String], "kolejka trzyma porzadek FIFO (A w trakcie)")
	assert_true(banner._busy, "baner zajety podczas pisania pierwszej")
