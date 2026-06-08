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
		var stored = cfg.get_value("scores", "top", [])
		for v in stored:
			list.append(int(v))
	list.sort()
	list.reverse()
	if list.size() > n:
		list = list.slice(0, n)
	return list

static func clear(path: String = PATH) -> void:
	_save([] as Array[int], path)

static func _save(list: Array[int], path: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", list)
	cfg.save(path)
