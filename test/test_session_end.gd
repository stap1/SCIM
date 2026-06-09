extends GutTest

# P2.6: koniec sesji wg czasu - czysta funkcja should_end_session (wydzielona z main._process).

const MainScript := preload("res://scripts/systems/main.gd")

func test_ends_when_time_reaches_limit() -> void:
	assert_true(MainScript.should_end_session(900.0, 900), "czas == limit -> koniec")
	assert_true(MainScript.should_end_session(901.0, 900), "czas > limit -> koniec")

func test_continues_before_limit() -> void:
	assert_false(MainScript.should_end_session(899.0, 900), "czas < limit -> gra trwa")
	assert_false(MainScript.should_end_session(0.0, 900), "start sesji -> gra trwa")

func test_no_limit_never_ends() -> void:
	assert_false(MainScript.should_end_session(99999.0, 0), "limit 0 -> brak konca (sesja bez limitu)")
	assert_false(MainScript.should_end_session(99999.0, -5), "limit ujemny -> brak konca")
