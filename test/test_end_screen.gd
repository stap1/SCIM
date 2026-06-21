extends GutTest

# R4b: jeden ekran konca, dwa warianty (wygrana/porazka) + przeliczenie punktow meta.
# Izolacja meta przez _path tymczasowy (nie ruszamy realnego meta.cfg).

const GameOverScene := preload("res://scenes/ui/game_over.tscn")
const GameOverScript := preload("res://scripts/ui/game_over.gd")
const TMP := "user://test_meta_end.cfg"

func before_each() -> void:
	GameState.reset()
	MetaProgress._path = TMP
	MetaProgress._points = 0
	MetaProgress._levels = {}
	MetaProgress._loaded = true

func after_each() -> void:
	get_tree().paused = false
	MetaProgress._points = 0
	MetaProgress._levels = {}
	MetaProgress._path = MetaProgress.PATH
	MetaProgress._loaded = false
	if FileAccess.file_exists(TMP):
		DirAccess.remove_absolute(TMP)
	GameState.reset()

func test_outcome_title_pure() -> void:
	assert_eq(GameOverScript.outcome_title(true), "WYGRANA", "wygrana -> WYGRANA")
	assert_eq(GameOverScript.outcome_title(false), "KONIEC REJSU", "porazka -> KONIEC REJSU")

func test_win_variant_and_meta_points() -> void:
	var go = GameOverScene.instantiate()
	add_child_autofree(go)
	await wait_physics_frames(1)
	GameState.score = 95
	GameState.trigger_game_over(true)  # emituje game_over -> _on_game_over
	await wait_physics_frames(1)
	assert_eq(go.get_node("Panel/GameOverLabel").text, "WYGRANA", "tytul wygranej")
	assert_eq(MetaProgress.points(), 95 / GameConfig.META_POINTS_PER_SCORE, "punkty meta doliczone")
	assert_string_contains(go.get_node("Panel/MetaLabel").text, "9", "ekran pokazuje zdobyte punkty")

func test_loss_variant() -> void:
	var go = GameOverScene.instantiate()
	add_child_autofree(go)
	await wait_physics_frames(1)
	GameState.score = 40
	GameState.trigger_game_over(false)
	await wait_physics_frames(1)
	assert_eq(go.get_node("Panel/GameOverLabel").text, "KONIEC REJSU", "tytul porazki")
