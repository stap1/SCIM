extends GutTest

# B6: czysta funkcja ujawniania "maszyny do pisania" (TypewriterLabel.visible_count).

func test_zero_at_start() -> void:
	assert_eq(TypewriterLabel.visible_count(0.0, 32.0, 10), 0, "t=0 -> 0 znakow")

func test_grows_with_time() -> void:
	# 0.1 s * 32 cps = 3.2 -> floor 3
	assert_eq(TypewriterLabel.visible_count(0.1, 32.0, 100), 3, "rosnie z czasem (floor)")
	assert_eq(TypewriterLabel.visible_count(0.25, 32.0, 100), 8, "0.25*32=8")

func test_clamped_to_total() -> void:
	assert_eq(TypewriterLabel.visible_count(1.0, 32.0, 10), 10, "duzy czas -> przyciete do total")

func test_clamped_non_negative() -> void:
	assert_eq(TypewriterLabel.visible_count(-1.0, 32.0, 10), 0, "ujemny czas -> 0")

func test_zero_cps_instant() -> void:
	assert_eq(TypewriterLabel.visible_count(0.0, 0.0, 7), 7, "cps<=0 -> od razu calosc")
	assert_eq(TypewriterLabel.visible_count(5.0, -3.0, 7), 7, "cps ujemne -> od razu calosc")
