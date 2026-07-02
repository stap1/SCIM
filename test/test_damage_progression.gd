extends GutTest

# Model progresji obrazen (SCIM_UPGRADE_REBALANCE_ANALIZA): karta "Ostrzejszy grot"
# daje plaski przyrost +2/poziom, co tworzy ZAMIERZONE breakpointy liczby strzalow.
# Ten test to straznik modelu - zmiana HP wrogow lub przyrostu obrazen, ktora
# psuje breakpointy, musi tu glosno poleciec (swiadoma decyzja, nie przypadek).

const BarracudaScene := preload("res://scenes/enemies/barracuda.tscn")
const SharkScene := preload("res://scenes/enemies/shark.tscn")

func _dmg_at_level(level: int) -> float:
	var d := GameConfig.HARPOON_DAMAGE
	for i in level:
		d = Upgrades.apply_sharper_harpoon(d)
	return d

func test_shots_to_kill_pure() -> void:
	assert_eq(Upgrades.shots_to_kill(10.0, 5.0), 2, "10 HP / 5 dmg = 2 strzaly")
	assert_eq(Upgrades.shots_to_kill(10.0, 11.0), 1, "nadmiar obrazen -> 1 strzal")
	assert_eq(Upgrades.shots_to_kill(10.0, 0.0), 0, "zerowe obrazenia -> guard (0)")

func test_sharper_harpoon_flat_growth() -> void:
	assert_almost_eq(Upgrades.apply_sharper_harpoon(5.0), 7.0, 0.001, "+2 obrazen na poziom")
	assert_almost_eq(_dmg_at_level(3), 11.0, 0.001, "maks. poziom: 5 -> 11 obrazen")

func test_slow_strength_for_level() -> void:
	assert_almost_eq(Upgrades.slow_strength_for_level(0), 0.0, 0.001, "bez karty brak spowolnienia")
	assert_almost_eq(Upgrades.slow_strength_for_level(1), 0.25, 0.001, "poziom 1 -> 25%")
	assert_almost_eq(Upgrades.slow_strength_for_level(3), 0.45, 0.001, "poziom 3 -> 45%")
	assert_almost_eq(Upgrades.slow_strength_for_level(9), 0.45, 0.001, "powyzej skali -> ostatni prog")

func test_breakpoints_of_progression_model() -> void:
	var barracuda = BarracudaScene.instantiate()
	var shark = SharkScene.instantiate()
	var jelly_hp := GameConfig.ENEMY_JELLYFISH_HP
	var barracuda_hp: float = barracuda.max_health
	var shark_hp: float = shark.max_health
	var boss_hp := GameConfig.MINIBOSS_HP
	barracuda.free()
	shark.free()

	# Baza (bez kart): stan wyjsciowy modelu.
	assert_eq(Upgrades.shots_to_kill(jelly_hp, _dmg_at_level(0)), 2, "baza: meduza 2 strzaly")
	assert_eq(Upgrades.shots_to_kill(shark_hp, _dmg_at_level(0)), 8, "baza: rekin 8 strzalow")
	assert_eq(Upgrades.shots_to_kill(boss_hp, _dmg_at_level(0)), 60, "baza: boss 60 strzalow")

	# Breakpointy kart (zamierzone skoki mocy):
	assert_eq(Upgrades.shots_to_kill(shark_hp, _dmg_at_level(1)), 6, "poziom 1: rekin 8 -> 6 strzalow")
	assert_eq(Upgrades.shots_to_kill(barracuda_hp, _dmg_at_level(2)), 1,
		"poziom 2: barakuda z JEDNEGO strzalu (skok mid-game)")
	assert_eq(Upgrades.shots_to_kill(jelly_hp, _dmg_at_level(3)), 1,
		"poziom 3: meduza z jednego strzalu (nagroda late-game)")
	assert_eq(Upgrades.shots_to_kill(shark_hp, _dmg_at_level(3)), 4, "poziom 3: rekin 4 strzaly")
	assert_true(Upgrades.shots_to_kill(boss_hp, _dmg_at_level(3)) <= 28,
		"poziom 3: boss maks. 28 strzalow (cel modelu: realny time-to-kill)")

func test_new_cards_in_catalog_old_removed() -> void:
	assert_true(Upgrades.UPGRADES.has("sharper_harpoon") and Upgrades.UPGRADES.has("slow_harpoon"),
		"nowe karty w katalogu")
	assert_false(Upgrades.UPGRADES.has("longer_range") or Upgrades.UPGRADES.has("double_harpoon"),
		"martwy zasieg i duplikat podwojnego harpuna usuniete z puli")
	assert_true(Upgrades.has_effect("sharper_harpoon") and Upgrades.has_effect("slow_harpoon"),
		"efekty nowych kart zarejestrowane")