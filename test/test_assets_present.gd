extends GutTest

# Brama assetow GFX (FAZA 0 ingest): kazdy docelowy plik z res://assets/ musi istniec
# i ladowac sie jako zasob. Nie sprawdza scen - podmiana ext_resource to FAZY 2-4.
# Lapie brak/zla nazwe assetu zanim trafi do sceny.

const GAMEPLAY := [
	"boat", "enemy_jellyfish", "enemy_barracuda", "enemy_shark", "miniboss_motorboat",
	"xp_orb", "harpoon", "heal_plank", "hud_ammo_icon", "app_icon",
	"hull_hp_0", "hull_hp_1", "hull_hp_2", "hull_hp_3", "hull_hp_4",
	"upgrade_faster_attack", "upgrade_longer_range", "upgrade_tougher_hull",
	"upgrade_faster_boat", "upgrade_resource_magnet", "upgrade_double_harpoon",
	"upgrade_extra_harpoon", "upgrade_piercing",
]

const WATER := ["water_noise", "water_noise_2", "water_normal"]

func test_sprites_and_icons_present() -> void:
	for name in GAMEPLAY:
		var path := "res://assets/%s.png" % name
		assert_true(ResourceLoader.exists(path), "asset istnieje: %s" % path)
		if ResourceLoader.exists(path):
			assert_not_null(load(path) as Texture2D, "asset laduje sie jako Texture2D: %s" % path)

func test_water_maps_present() -> void:
	for name in WATER:
		var path := "res://assets/%s.png" % name
		assert_true(ResourceLoader.exists(path), "mapa wody istnieje: %s" % path)
		if ResourceLoader.exists(path):
			assert_not_null(load(path) as Texture2D, "mapa wody laduje sie jako Texture2D: %s" % path)
