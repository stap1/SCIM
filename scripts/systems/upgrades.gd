extends Node

# Autoload "Upgrades": katalog 6 ulepszen + aplikacja efektow do wlasciwych wezlow.
# Czyste funkcje apply_* licza nowe wartosci (testowalne), apply(id) je naklada.

const UPGRADES := {
	"faster_attack": {
		"id": "faster_attack",
		"name": "Szybszy harpun",
		"description": "Atak co 15% krocej",
		"max_level": 3,
	},
	"longer_range": {
		"id": "longer_range",
		"name": "Dluzszy zasieg",
		"description": "Zasieg ataku +20%",
		"max_level": 3,
	},
	"tougher_hull": {
		"id": "tougher_hull",
		"name": "Mocniejszy kadlub",
		"description": "Max HP +30 (i +30 HP)",
		"max_level": 3,
	},
	"faster_boat": {
		"id": "faster_boat",
		"name": "Szybsza lodz",
		"description": "Predkosc +20%",
		"max_level": 3,
	},
	"resource_magnet": {
		"id": "resource_magnet",
		"name": "Magnes na zasoby",
		"description": "Zasieg zbierania XP +40%",
		"max_level": 3,
	},
	"double_harpoon": {
		"id": "double_harpoon",
		"name": "Podwojny harpun",
		"description": "Atakuj 2 najblizszych wrogow",
		"max_level": 1,
	},
}

# Specjalne power-upy milestone (co MILESTONE_LEVEL_INTERVAL poziomow, ZAMIAST zwyklej karty).
# Bez max_level - kumuluja sie bez limitu (kazdy wybor +1).
const MILESTONE_UPGRADES := {
	"extra_harpoon": {
		"id": "extra_harpoon",
		"name": "Dodatkowy harpun",
		"description": "+1 jednoczesny pocisk",
	},
	"piercing": {
		"id": "piercing",
		"name": "Przebijanie",
		"description": "Harpun przebija +1 wroga",
	},
}

# Aktualne poziomy wybranych ulepszen (id -> ile razy wzieto). Resetowane na nowa sesje.
var _levels: Dictionary = {}

func _ready() -> void:
	GameState.session_reset.connect(reset_levels)

func reset_levels() -> void:
	_levels.clear()

func level_of(id: String) -> int:
	return _levels.get(id, 0)

# Ulepszenia jeszcze nie wyczerpane (poziom < max_level) - do losowania kart.
func available_ids() -> Array[String]:
	var out: Array[String] = []
	for id in UPGRADES:
		if level_of(id) < int(UPGRADES[id]["max_level"]):
			out.append(id)
	return out

# Lista id power-upow milestone (do ekranu specjalnego co 5 poziomow).
func milestone_ids() -> Array[String]:
	var out: Array[String] = []
	for id in MILESTONE_UPGRADES:
		out.append(id)
	return out

# Metadane karty (name/description) - dziala dla ulepszen zwyklych i milestone.
func info(id: String) -> Dictionary:
	if UPGRADES.has(id):
		return UPGRADES[id]
	if MILESTONE_UPGRADES.has(id):
		return MILESTONE_UPGRADES[id]
	return {}

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
	# Power-upy milestone (bez _levels - kumuluja sie bez limitu).
	if MILESTONE_UPGRADES.has(id):
		var aa_m := _auto_attacker()
		if aa_m == null:
			return
		match id:
			"extra_harpoon":
				aa_m.projectiles_per_attack += 1
			"piercing":
				aa_m.pierce_bonus += 1
		return
	if not UPGRADES.has(id):
		return
	# Liczymy wybor (cap stackowania). Robimy to przed efektem - wybor zaszedl niezaleznie.
	_levels[id] = level_of(id) + 1
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
				# maxi - nie cofa stackow z power-upow milestone (extra_harpoon).
				aa.projectiles_per_attack = maxi(aa.projectiles_per_attack, apply_double_harpoon())

func _auto_attacker() -> Node:
	return get_tree().get_first_node_in_group("auto_attacker")

func _player() -> Node:
	return get_tree().get_first_node_in_group("player")
