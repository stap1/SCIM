extends Node

# Tablica najlepszych wynikow (top 5) zapisywana w user://highscores.cfg (ConfigFile).
# Kazdy wpis to slownik {"name": String, "score": int}. Czyste funkcje na dole.
# Metody przyjmuja opcjonalna sciezke (do testow). Obsluguje tez stary format (same liczby).

const PATH := "user://highscores.cfg"
const MAX := 5
const NAME_MAX_LEN := 20
const DEFAULT_NAME := "Anonim"

# Czysta funkcja: dodaje wpis {name, score}, sortuje malejaco po wyniku, przycina do max_len.
static func insert_score(list: Array, player_name: String, score: int, max_len: int) -> Array:
	var result: Array = list.duplicate(true)
	result.append({"name": sanitize_name(player_name), "score": score})
	result.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if result.size() > max_len:
		result = result.slice(0, max_len)
	return result

static func add_score(player_name: String, score: int, path: String = PATH) -> void:
	var top := get_top(MAX, path)
	_save(insert_score(top, player_name, score, MAX), path)

static func get_top(n: int, path: String = PATH) -> Array:
	var cfg := ConfigFile.new()
	var list: Array = []
	if cfg.load(path) == OK:
		# Plik moze byc uszkodzony lub edytowany z zewnatrz - waliduj zawartosc.
		list = sanitize_entries(cfg.get_value("scores", "top", []))
	list.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if list.size() > n:
		list = list.slice(0, n)
	return list

# Czysta funkcja: nazwa gracza -> bezpieczna nazwa. Zamienia znaki nowej linii/tab na spacje,
# usuwa znaki sterujace (< 32), przycina biale znaki, ogranicza do NAME_MAX_LEN. Pusta -> DEFAULT_NAME.
static func sanitize_name(raw: String) -> String:
	var s := raw.replace("\n", " ").replace("\r", " ").replace("\t", " ")
	var clean := ""
	for ch in s:
		if ch.unicode_at(0) >= 32:
			clean += ch
	clean = clean.strip_edges()
	if clean.length() > NAME_MAX_LEN:
		clean = clean.substr(0, NAME_MAX_LEN)
	return clean if clean != "" else DEFAULT_NAME

# Czysta funkcja: z dowolnej wartosci configu wyciaga liste wpisow {name, score}.
# Akceptuje nowy format ({name, score}) i stary (same liczby). Smieci pomijane - brak crasha.
static func sanitize_entries(raw) -> Array:
	var out: Array = []
	if not (raw is Array):
		return out
	for v in raw:
		if v is Dictionary and v.has("score"):
			var sc = v["score"]
			if sc is int or sc is float or (sc is String and (sc as String).is_valid_int()):
				out.append({"name": sanitize_name(str(v.get("name", ""))), "score": int(sc)})
		elif v is int or v is float:
			out.append({"name": DEFAULT_NAME, "score": int(v)}) # stary format
		elif v is String and (v as String).is_valid_int():
			out.append({"name": DEFAULT_NAME, "score": int(v)})
	return out

static func clear(path: String = PATH) -> void:
	_save([], path)

static func _save(list: Array, path: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", list)
	cfg.save(path)
