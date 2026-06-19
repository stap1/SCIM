extends GutTest

# G2: kazde ulepszenie (zwykle i milestone) mapuje na istniejaca ikone upgrade_<id>.png.
# Karta robi graceful fallback gdy plik brak - tu pilnujemy, ze komplet ikon jest obecny.

func test_icon_path_convention() -> void:
	assert_eq(Upgrades.icon_path("faster_attack"), "res://assets/upgrade_faster_attack.png",
		"konwencja sciezki ikony: upgrade_<id>.png")

func test_every_upgrade_has_existing_icon() -> void:
	var ids: Array = Upgrades.UPGRADES.keys() + Upgrades.MILESTONE_UPGRADES.keys()
	for id in ids:
		var path: String = Upgrades.icon_path(id)
		assert_true(ResourceLoader.exists(path), "ikona istnieje dla '%s': %s" % [id, path])
