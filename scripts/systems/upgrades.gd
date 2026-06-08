extends Node

# Autoload "Upgrades": katalog 6 ulepszen + aplikacja efektow do wlasciwych wezlow.
# Czyste funkcje apply_* licza nowe wartosci (testowalne), apply(id) je naklada.

const UPGRADES := {
	"faster_attack": {
		"id": "faster_attack",
		"name": "Szybszy harpun",
		"description": "Atak co 15% krocej",
	},
	"longer_range": {
		"id": "longer_range",
		"name": "Dluzszy zasieg",
		"description": "Zasieg ataku +20%",
	},
	"tougher_hull": {
		"id": "tougher_hull",
		"name": "Mocniejszy kadlub",
		"description": "Max HP +30 (i +30 HP)",
	},
	"faster_boat": {
		"id": "faster_boat",
		"name": "Szybsza lodz",
		"description": "Predkosc +20%",
	},
	"resource_magnet": {
		"id": "resource_magnet",
		"name": "Magnes na zasoby",
		"description": "Zasieg zbierania XP +40%",
	},
	"double_harpoon": {
		"id": "double_harpoon",
		"name": "Podwojny harpun",
		"description": "Atakuj 2 najblizszych wrogow",
	},
}

# --- Czyste funkcje (bez zaleznosci od drzewa, testowalne) ---
static func apply_faster_attack(interval: float) -> float:
	return interval * 0.85

static func apply_longer_range(attack_range: float) -> float:
	return attack_range * 1.2

static func apply_tougher_hull(value: float) -> float:
	return value + 30.0

static func apply_faster_boat(speed: float) -> float:
	return speed * 1.2

static func apply_resource_magnet(mult: float) -> float:
	return mult * 1.4

static func apply_double_harpoon() -> int:
	return 2

# --- Aplikacja efektu do wezlow gry (luzne powiazanie przez grupy) ---
func apply(id: String) -> void:
	match id:
		"faster_attack":
			var aa := _auto_attacker()
			if aa:
				aa.set_attack_interval(apply_faster_attack(aa.attack_interval))
		"longer_range":
			var aa := _auto_attacker()
			if aa:
				aa.attack_range = apply_longer_range(aa.attack_range)
		"tougher_hull":
			GameState.max_health = apply_tougher_hull(GameState.max_health)
			GameState.health = apply_tougher_hull(GameState.health)
			GameState.health_changed.emit(GameState.health)
		"faster_boat":
			var boat := _player()
			if boat:
				boat.max_speed = apply_faster_boat(boat.max_speed)
		"resource_magnet":
			GameState.magnet_range_mult = apply_resource_magnet(GameState.magnet_range_mult)
		"double_harpoon":
			var aa := _auto_attacker()
			if aa:
				aa.projectiles_per_attack = apply_double_harpoon()

func _auto_attacker() -> Node:
	return get_tree().get_first_node_in_group("auto_attacker")

func _player() -> Node:
	return get_tree().get_first_node_in_group("player")
