extends Node

# Autoload "Upgrades": katalog 6 ulepszen + aplikacja efektow do wlasciwych wezlow.
# Czyste funkcje apply_* licza nowe wartosci (testowalne), apply(id) je naklada.

const UPGRADES := {
	"faster_attack": {
		"id": "faster_attack",
		"name": "Szybszy harpun",
		"description": "Atak co 10% krócej",
		"max_level": 3,
	},
	"slow_harpoon": {
		"id": "slow_harpoon",
		"name": "Harpun z linką",
		"description": "Trafienie spowalnia wroga (25/35/45%)",
		"max_level": 3,
	},
	"tougher_hull": {
		"id": "tougher_hull",
		"name": "Mocniejszy kadłub",
		"description": "Max HP +20",
		"max_level": 3,
	},
	"faster_boat": {
		"id": "faster_boat",
		"name": "Szybsza łódź",
		"description": "Prędkość +15%",
		"max_level": 3,
	},
	"resource_magnet": {
		"id": "resource_magnet",
		"name": "Magnes na zasoby",
		"description": "Zasięg zbierania XP +25%",
		"max_level": 3,
	},
	"sharper_harpoon": {
		"id": "sharper_harpoon",
		"name": "Ostrzejszy grot",
		"description": "Obrażenia harpuna +2",
		"max_level": 3,
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
		"slow_harpoon": _effect_slow_harpoon,
		"tougher_hull": _effect_tougher_hull,
		"faster_boat": _effect_faster_boat,
		"resource_magnet": _effect_resource_magnet,
		"sharper_harpoon": _effect_sharper_harpoon,
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
# Rebalans: bonusy z kart level-up zmniejszone (slabszy przyrost mocy per poziom).
static func apply_faster_attack(interval: float) -> float:
	return interval * 0.90

# Ostrzejszy grot: plaski przyrost obrazen (kontrolowane breakpointy TTK -
# straznik w test_damage_progression.gd).
static func apply_sharper_harpoon(damage: float) -> float:
	return damage + GameConfig.HARPOON_DAMAGE_PER_LEVEL

# Harpun z linka: procent spowolnienia dla poziomu karty (poziom 1..3; 0 = brak).
static func slow_strength_for_level(level: int) -> float:
	var pct := GameConfig.HARPOON_SLOW_PCT_PER_LEVEL
	if level <= 0 or pct.is_empty():
		return 0.0
	return float(pct[clampi(level, 1, pct.size()) - 1])

# Czysta funkcja modelu progresji: ile strzalow zdejmuje dany zapas HP.
static func shots_to_kill(hp: float, damage: float) -> int:
	if damage <= 0.0:
		return 0
	return ceili(hp / damage)

static func apply_tougher_hull(value: float) -> float:
	return value + 20.0

static func apply_faster_boat(speed: float) -> float:
	return speed * 1.15

static func apply_resource_magnet(mult: float) -> float:
	return mult * 1.25

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

func _effect_slow_harpoon() -> void:
	var aa := _auto_attacker()
	if aa:
		aa.slow_strength = slow_strength_for_level(level_of("slow_harpoon"))

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

func _effect_sharper_harpoon() -> void:
	var aa := _auto_attacker()
	if aa:
		aa.damage = apply_sharper_harpoon(aa.damage)

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
