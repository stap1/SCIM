extends GutTest

# Changelog: czyste funkcje ChangelogData (wersja + formatowanie) i smoke ekranu.

const ChangelogScene := preload("res://scenes/Changelog.tscn")

func test_current_version_is_newest_entry() -> void:
	assert_eq(ChangelogData.current_version(), str(ChangelogData.ENTRIES[0]["version"]),
		"biezaca wersja = wersja najnowszego wpisu (na gorze listy)")

func test_format_all_newest_on_top() -> void:
	var txt := ChangelogData.format_all()
	var newest := "v" + str(ChangelogData.ENTRIES[0]["version"])
	var oldest := "v" + str(ChangelogData.ENTRIES[ChangelogData.ENTRIES.size() - 1]["version"])
	assert_true(txt.find(newest) < txt.find(oldest), "najnowsza wersja wyzej w tekscie niz najstarsza")

func test_format_entry_contains_header_and_changes() -> void:
	var e := {"version": "9.9.9", "date": "2099-01-01", "changes": ["alfa", "beta"]}
	var txt := ChangelogData.format_entry(e)
	assert_true(txt.contains("v9.9.9") and txt.contains("2099-01-01"), "naglowek z wersja i data")
	assert_true(txt.contains("alfa") and txt.contains("beta"), "wszystkie zmiany w tekscie")

func test_changelog_smoke_loads() -> void:
	var s = ChangelogScene.instantiate()
	add_child_autofree(s)
	await wait_physics_frames(1)
	assert_true(is_instance_valid(s), "Changelog.tscn laduje bez crasha")
