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

# --- Straznicy dryfu wersji (wersja zyje w 3 miejscach: ChangelogData, project.godot, CHANGELOG.md) ---

func test_version_matches_project_settings() -> void:
	assert_eq(ChangelogData.current_version(), str(ProjectSettings.get_setting("application/config/version")),
		"ChangelogData.current_version() == application/config/version - bump wersji musi objac oba miejsca")

func test_changelog_md_lists_current_version() -> void:
	var f := FileAccess.open("res://CHANGELOG.md", FileAccess.READ)
	assert_not_null(f, "CHANGELOG.md istnieje w korzeniu repo")
	if f == null:
		return
	assert_true(f.get_as_text().contains("## v" + ChangelogData.current_version()),
		"CHANGELOG.md ma naglowek dla biezacej wersji - bump wersji musi objac tez plik .md")

# --- Nawigacja klawiatura: przewijanie listy (jedyny focus to Powrot) ---

func test_keyboard_scrolls_changelog() -> void:
	var s = ChangelogScene.instantiate()
	add_child_autofree(s)
	await wait_physics_frames(1)
	var label: Label = s.get_node("Panel/Scroll/ChangelogList")
	label.text = "linia\n".repeat(200) # wymus zawartosc wyzsza niz okno przewijania
	await wait_physics_frames(2)
	var ev := InputEventAction.new()
	ev.action = "ui_down"
	ev.pressed = true
	s._unhandled_input(ev)
	var scroll: ScrollContainer = s.get_node("Panel/Scroll")
	assert_gt(scroll.scroll_vertical, 0, "ui_down przewija liste w dol")
	var ev_up := InputEventAction.new()
	ev_up.action = "ui_up"
	ev_up.pressed = true
	s._unhandled_input(ev_up)
	assert_eq(scroll.scroll_vertical, 0, "ui_up wraca na gore (bez ujemnego przewijania)")
