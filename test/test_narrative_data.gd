extends GutTest

# B2: dane narracji (NarrativeData) - progi meduz, kwestie, lista portretow.

func test_jellyfish_line_thresholds() -> void:
	assert_eq(NarrativeData.jellyfish_line_for(5), "", "ponizej progu -> pusto")
	assert_eq(NarrativeData.jellyfish_line_for(9), "", "tuz przed 10 -> pusto")
	assert_eq(NarrativeData.jellyfish_line_for(10), NarrativeData.JELLYFISH_LINES[10], "10 -> prog 10")
	assert_eq(NarrativeData.jellyfish_line_for(29), NarrativeData.JELLYFISH_LINES[10], "29 -> wciaz prog 10")
	assert_eq(NarrativeData.jellyfish_line_for(30), NarrativeData.JELLYFISH_LINES[30], "30 -> prog 30")
	assert_eq(NarrativeData.jellyfish_line_for(59), NarrativeData.JELLYFISH_LINES[30], "59 -> wciaz prog 30")
	assert_eq(NarrativeData.jellyfish_line_for(60), NarrativeData.JELLYFISH_LINES[60], "60 -> prog 60")
	assert_eq(NarrativeData.jellyfish_line_for(200), NarrativeData.JELLYFISH_LINES[60], "powyzej -> prog 60")

func test_key_lines_non_empty() -> void:
	assert_false(NarrativeData.INTRO.is_empty(), "INTRO niepuste")
	assert_false(NarrativeData.FIRST_BARRACUDA.is_empty(), "FIRST_BARRACUDA niepuste")
	assert_false(NarrativeData.FIRST_SHARK.is_empty(), "FIRST_SHARK niepuste")
	assert_false(NarrativeData.BOSS_INCOMING.is_empty(), "BOSS_INCOMING niepuste")
	assert_false(NarrativeData.BOSS_DEFEATED.is_empty(), "BOSS_DEFEATED niepuste")

func test_no_em_dash_in_texts() -> void:
	# Zasada projektu: zaden dlugi mysnik. Sprawdzamy wszystkie teksty narracji.
	var all: Array[String] = [
		NarrativeData.INTRO, NarrativeData.FIRST_BARRACUDA, NarrativeData.FIRST_SHARK,
		NarrativeData.BOSS_INCOMING, NarrativeData.BOSS_DEFEATED,
	]
	for k in NarrativeData.JELLYFISH_LINES:
		all.append(NarrativeData.JELLYFISH_LINES[k])
	for line in all:
		assert_false(line.contains("—"), "brak dlugiego mysnika w: " + line)

func test_portraits_list() -> void:
	assert_false(NarrativeData.SANTIAGO_PORTRAITS.is_empty(), "lista portretow niepusta")
	for p in NarrativeData.SANTIAGO_PORTRAITS:
		assert_true(p.begins_with("res://assets/splash/"), "portret w assets/splash: " + p)
		assert_true(ResourceLoader.exists(p), "portret istnieje: " + p)
