extends Node

# Tablica najlepszych wynikow (top 5) zapisywana w user://highscores.cfg (ConfigFile).
# Czysta funkcja insert_score na dole. Metody przyjmuja opcjonalna sciezke (do testow).

const PATH := "user://highscores.cfg"
const MAX := 5

# Czysta funkcja: dodaje wynik, sortuje malejaco, przycina do max_len.
static func insert_score(list: Array[int], score: int, max_len: int) -> Array[int]:
	var result: Array[int] = list.duplicate()
	result.append(score)
	result.sort()
	result.reverse()
	if result.size() > max_len:
		result = result.slice(0, max_len)
	return result

static func add_score(score: int, path: String = PATH) -> void:
	var top := get_top(MAX, path)
	_save(insert_score(top, score, MAX), path)

static func get_top(n: int, path: String = PATH) -> Array[int]:
	var cfg := ConfigFile.new()
	var list: Array[int] = []
	if cfg.load(path) == OK:
		# Plik moze byc uszkodzony lub edytowany z zewnatrz - waliduj zawartosc.
		list = sanitize_scores(cfg.get_value("scores", "top", []))
	list.sort()
	list.reverse()
	if list.size() > n:
		list = list.slice(0, n)
	return list

# Czysta funkcja: z dowolnej wartosci configu wyciaga liste liczb. Nie-Array -> [];
# wpisy nieliczbowe (string nie-int, dict, null, bool) pomijane - brak crasha na smieciach.
static func sanitize_scores(raw) -> Array[int]:
	var out: Array[int] = []
	if not (raw is Array):
		return out
	for v in raw:
		if v is int or v is float:
			out.append(int(v))
		elif v is String and v.is_valid_int():
			out.append(int(v))
	return out

static func clear(path: String = PATH) -> void:
	_save([] as Array[int], path)

static func _save(list: Array[int], path: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", list)
	cfg.save(path)
