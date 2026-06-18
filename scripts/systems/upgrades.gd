extends Node

# Autoload "Upgrades": katalog 6 ulepszen + aplikacja efektow do wlasciwych wezlow.
# Czyste funkcje apply_* licza nowe wartosci (testowalne), apply(id) je naklada.

const UPGRADES := {
	"faster_attack": {
		"id": "faster_attack",
		"name": "Szybszy harpun",
		"description": "Atak co 15% krócej",
		"max_level": 3,
	},
	"longer_range": {
		"id": "longer_range",
		"name": "Dłuższy zasięg",
		"description": "Zasięg ataku +20%",
		"max_level": 3,
	},
	"tougher_hull": {
		"id": "tougher_hull",
		"name": "Mocniejszy kadłub",
		"description": "Max HP +30",
		"max_level": 3,
	},
	"faster_boat": {
		"id": "faster_boat",
		"name": "Szybsza łódź",
		"description": "Prędkość +20%",
		"max_level": 3,
	},
	"resource_magnet": {
		"id": "resource_magnet",
		"name": "Magnes na zasoby",
		"description": "Zasięg zbierania XP +40%",
		"max_level": 3,
	},
	"double_harpoon": {
		"id": "double_harpoon",
		"name": "Podwójny harpun",
		"description": "Atakuj 2 najbliższych wrogów",
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

# Rejestr efektow (id -> Callable bez argumentow). Budowany w _ready - dyspozytornia
# dla apply(), dzieki czemu dodanie ulepszenia nie wymaga dotykania apply() (P2.3).
var _effects: Dictionary = {}

func _ready() -> void:
	GameState.session_reset.connect(reset_levels)
	_build_effects()

# Mapuje id katalogu na metode nakladajaca efekt. Jedyne miejsce wiazace id z dzialaniem.
func _build_effects() -> void:
	_effects = {
		"faster_attack": _effect_faster_attack,
		"longer_range": _effect_longer_range,
		"tougher_hull": _effect_tougher_hull,
		"faster_boat": _effect_faster_boat,
		"resource_magnet": _effect_resource_magnet,
		"double_harpoon": _effect_double_harpoon,
		"extra_harpoon": _effect_extra_harpoon,
		"piercing": _effect_piercing,
	}

func has_effect(id: String) -> bool:
	return _effects.has(id)

func effect_ids() -> Array:
	return _effects.keys()

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

# Sciezka ikony ulepszenia. Konwencja: upgrade_<id>.png w res://assets/ (id == nazwa pliku).
# Karta robi graceful fallback (tekst) gdy plik nie istnieje.
func icon_path(id: String) -> String:
	return "res://assets/upgrade_%s.png" % id

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

# --- Aplikacja efektu do wezlow gry (dispatch po rejestrze, luzne powiazanie przez grupy) ---
func apply(id: String) -> void:
	if not _effects.has(id):
		return
	# Zwykle ulepszenia licza poziom (cap stackowania); milestone NIE (kumuluja bez limitu).
	# Robimy to przed efektem - wybor zaszedl niezaleznie.
	if UPGRADES.has(id):
		_levels[id] = level_of(id) + 1
	_effects[id].call()

# --- Efekty (jeden na ulepszenie). Kazdy sam pilnuje swoich zaleznosci/guardow. ---
func _effect_faster_attack() -> void:
	var aa := _auto_attacker()
	if aa:
		aa.set_attack_interval(apply_faster_attack(aa.attack_interval))

func _effect_longer_range() -> void:
	var aa := _auto_attacker()
	if aa:
		aa.attack_range = apply_longer_range(aa.attack_range)

func _effect_tougher_hull() -> void:
	GameState.max_health = apply_tougher_hull(GameState.max_health)
	GameState.health = apply_tougher_hull(GameState.health)
	GameState.health_changed.emit(GameState.health)

func _effect_faster_boat() -> void:
	var boat := _player()
	if boat:
		boat.max_speed = apply_faster_boat(boat.max_speed)

func _effect_resource_magnet() -> void:
	GameState.magnet_range_mult = apply_resource_magnet(GameState.magnet_range_mult)

func _effect_double_harpoon() -> void:
	var aa := _auto_attacker()
	if aa:
		# maxi - nie cofa stackow z power-upow milestone (extra_harpoon).
		aa.projectiles_per_attack = maxi(aa.projectiles_per_attack, apply_double_harpoon())

func _effect_extra_harpoon() -> void:
	var aa := _auto_attacker()
	if aa:
		aa.projectiles_per_attack += 1

func _effect_piercing() -> void:
	var aa := _auto_attacker()
	if aa:
		aa.pierce_bonus += 1

func _auto_attacker() -> Node:
	return get_tree().get_first_node_in_group("auto_attacker")

func _player() -> Node:
	return get_tree().get_first_node_in_group("player")
