extends GutTest

# B3: intro Santiago - losowanie portretu, pauza na starcie, zdjecie pauzy + sygnal po koncu.

const IntroScene := preload("res://scenes/ui/santiago_intro.tscn")
const Intro := preload("res://scripts/ui/santiago_intro.gd")

func after_each() -> void:
	# Bezpiecznik: zaden test nie zostawia drzewa zapauzowanego.
	if get_tree().paused:
		get_tree().paused = false

func test_pick_index_empty_pool() -> void:
	assert_eq(Intro.pick_portrait_index(0, 123), -1, "pusta pula -> -1")

func test_pick_index_in_range_and_deterministic() -> void:
	var a := Intro.pick_portrait_index(4, 777)
	var b := Intro.pick_portrait_index(4, 777)
	assert_eq(a, b, "ten sam seed -> ten sam indeks")
	assert_between(a, 0, 3, "indeks w zakresie [0,3]")

func test_portraits_available() -> void:
	assert_eq(Intro._available_portraits().size(), 4, "4 portrety realnie dostepne")

func test_overlay_always_process_and_pauses() -> void:
	var overlay = IntroScene.instantiate()
	add_child_autofree(overlay)
	assert_eq(overlay.process_mode, Node.PROCESS_MODE_ALWAYS, "overlay ma PROCESS_MODE_ALWAYS")
	assert_true(get_tree().paused, "intro pauzuje gre na starcie")
	# Reczne zakonczenie (bez czekania calej sekwencji) zdejmuje pauze i emituje sygnal.
	watch_signals(overlay)
	overlay._finish()
	assert_signal_emitted(overlay, "intro_finished", "emituje intro_finished")
	assert_false(get_tree().paused, "po zakonczeniu zdejmuje pauze")

func test_exit_before_finish_unpauses() -> void:
	# Symuluje zmiane sceny w trakcie intro: overlay znika bez _finish -> nie zostawia pauzy.
	var overlay = IntroScene.instantiate()
	add_child(overlay)
	assert_true(get_tree().paused, "intro zapauzowalo")
	overlay.free()
	assert_false(get_tree().paused, "_exit_tree zdjal pauze mimo braku _finish")
