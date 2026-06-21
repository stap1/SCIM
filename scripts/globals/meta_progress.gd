class_name MetaProgress
extends RefCounted

# Meta-progresja (R3, SZKIELET): trwale punkty i ulepszenia miedzy sesjami.
# Stan statyczny (zyje przez caly proces, niezalezny od scen) + zapis do user://meta.cfg
# (ConfigFile, wzorzec jak HighScores). NIE autoload - nie ruszamy project.godot.
# Profile gracza POZA zakresem (przyszlosc).
#
# Trzy realne ulepszenia modyfikuja WARTOSCI STARTOWE gracza (male per poziom, ostatni
# poziom znaczacy - krzywa kwadratowa). 12 placeholderow dochodzi w UI (R3c), nie tutaj.

const PATH := "user://meta.cfg"

const META_UPGRADES := {
	"spawn":  {"name": "Spokojniejszy start", "max_level": 5, "desc": "Łagodniejszy spawn na starcie"},
	"boat":   {"name": "Szybsza łódź",        "max_level": 5, "desc": "Wyższa startowa prędkość"},
	"magnet": {"name": "Zasięg zbierania",    "max_level": 5, "desc": "Większy startowy zasięg XP"},
}

# Kolejnosc realnych ulepszen w UI (deterministyczna).
const REAL_IDS: Array[String] = ["spawn", "boat", "magnet"]

static var _points: int = 0
static var _levels: Dictionary = {}
static var _loaded: bool = false
# Sciezka zapisu - nadpisywalna w testach (izolacja od realnego meta.cfg gracza).
static var _path: String = PATH

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_load(_path)

# --- Saldo punktow ---
static func points() -> int:
	_ensure_loaded()
	return _points

static func add_points(n: int) -> void:
	_ensure_loaded()
	_points += maxi(0, n)
	_save(_path)

# Czysta funkcja: przeliczenie wyniku sesji na punkty meta.
static func score_to_points(score: int) -> int:
	return maxi(0, score) / GameConfig.META_POINTS_PER_SCORE

# --- Poziomy i kupno ---
static func level_of(id: String) -> int:
	_ensure_loaded()
	return int(_levels.get(id, 0))

static func max_level_of(id: String) -> int:
	return int(META_UPGRADES[id]["max_level"]) if META_UPGRADES.has(id) else 0

# Koszt nastepnego poziomu (z poziomu `level`): BASE*(level+1) - rosnie z poziomem.
static func cost_of(id: String, level: int) -> int:
	return GameConfig.META_COST_BASE * (level + 1)

static func can_buy(id: String) -> bool:
	_ensure_loaded()
	if not META_UPGRADES.has(id):
		return false
	var lvl := level_of(id)
	if lvl >= max_level_of(id):
		return false
	return _points >= cost_of(id, lvl)

static func buy(id: String) -> bool:
	_ensure_loaded()
	if not can_buy(id):
		return false
	var lvl := level_of(id)
	_points -= cost_of(id, lvl)
	_levels[id] = lvl + 1
	_save(_path)
	return true

# Suma wszystkich wydanych punktow (do zwrotu przy resecie).
static func total_spent() -> int:
	_ensure_loaded()
	var sum := 0
	for id in _levels:
		for l in int(_levels[id]):
			sum += cost_of(id, l)
	return sum

# Reset: zwraca WSZYSTKIE wydane punkty i zeruje poziomy.
static func reset_upgrades() -> void:
	_ensure_loaded()
	_points += total_spent()
	_levels.clear()
	_save(_path)

# --- Bonusy nakladane na start runu (R3d) ---
static func bonus_boat_speed() -> float:
	return GameConfig.META_BOAT_SPEED_MAX * _curve("boat")

static func bonus_magnet_mult() -> float:
	return 1.0 + GameConfig.META_MAGNET_MULT_MAX * _curve("magnet")

static func spawn_ease() -> float:
	return GameConfig.META_SPAWN_EASE_MAX * _curve("spawn")

# Krzywa wartosci ulepszenia: 0 na poziomie 0, 1.0 na maksie; kwadratowa (ostatnie poziomy znaczace).
static func _curve(id: String) -> float:
	var maxl := max_level_of(id)
	if maxl <= 0:
		return 0.0
	var t := clampf(float(level_of(id)) / float(maxl), 0.0, 1.0)
	return t * t

# --- Trwalosc (ConfigFile) ---
static func _save(path: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "points", _points)
	cfg.set_value("meta", "levels", _levels)
	cfg.save(path)

static func _load(path: String) -> void:
	var cfg := ConfigFile.new()
	_points = 0
	_levels = {}
	if cfg.load(path) == OK:
		_points = int(cfg.get_value("meta", "points", 0))
		var raw = cfg.get_value("meta", "levels", {})
		if raw is Dictionary:
			# Waliduj: tylko znane id z sensownym poziomem (plik moze byc edytowany z zewnatrz).
			for id in raw:
				if META_UPGRADES.has(id):
					_levels[id] = clampi(int(raw[id]), 0, max_level_of(id))
