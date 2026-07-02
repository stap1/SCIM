extends Node

# Tablica najlepszych wynikow (top 5) zapisywana w user://highscores.cfg (ConfigFile).
# Kazdy wpis to slownik {"name": String, "score": int}. Czyste funkcje na dole.
# Metody przyjmuja opcjonalna sciezke (do testow). Obsluguje tez stary format (same liczby).

const PATH := "user://highscores.cfg"
const MAX := 5
const NAME_MAX_LEN := 20
const DEFAULT_NAME := "Anon"
# Twardy limit dlugosci surowego wejscia sanitize_name - chroni przed kwadratowym kosztem
# budowania stringa znak po znaku, gdy uszkodzony plik podsunie wielomegabajtowa "nazwe".
const RAW_NAME_CAP := 200

# Czysta funkcja: dodaje wpis {name, score}, sortuje malejaco po wyniku, przycina do max_len.
# Remisy rozstrzyga stabilnie - istniejace (starsze) wpisy stoja przed nowo dodanym.
static func insert_score(list: Array[Dictionary], player_name: String, score: int, max_len: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = list.duplicate(true)
	result.append({"name": sanitize_name(player_name), "score": score})
	result = sort_entries_desc(result)
	return result.slice(0, clampi(max_len, 0, result.size()))

static func add_score(player_name: String, score: int, path: String = PATH) -> void:
	var top := get_top(MAX, path)
	_save(insert_score(top, player_name, score, MAX), path)

static func get_top(n: int, path: String = PATH) -> Array[Dictionary]:
	var cfg := ConfigFile.new()
	var list: Array[Dictionary] = []
	if cfg.load(path) == OK:
		# Plik moze byc uszkodzony lub edytowany z zewnatrz - waliduj zawartosc.
		list = sanitize_entries(cfg.get_value("scores", "top", []))
	list = sort_entries_desc(list)
	return list.slice(0, clampi(n, 0, list.size()))

# Czysta funkcja: sortowanie malejaco po wyniku, STABILNE dla remisow. Array.sort_custom
# w Godocie jest niestabilny, wiec remis rozstrzyga jawny tiebreak po pozycji wejsciowej -
# kolejnosc wpisow o rownym wyniku (i to, kto wypada przy przycieciu) jest deterministyczna.
static func sort_entries_desc(list: Array[Dictionary]) -> Array[Dictionary]:
	var indexed: Array[Array] = []
	for i in list.size():
		indexed.append([list[i], i])
	indexed.sort_custom(func(a: Array, b: Array) -> bool:
		var sa: int = int((a[0] as Dictionary).get("score", 0))
		var sb: int = int((b[0] as Dictionary).get("score", 0))
		if sa != sb:
			return sa > sb
		return int(a[1]) < int(b[1]))
	var out: Array[Dictionary] = []
	for pair in indexed:
		out.append(pair[0])
	return out

# Czysta funkcja: nazwa gracza -> bezpieczna nazwa. Biale znaki i NBSP -> spacja, znaki
# sterujace (C0, DEL, C1) i zero-width usuniete, krawedzie przyciete, dlugosc <= NAME_MAX_LEN.
# Idempotentna (po przycieciu tnie tez koncowe spacje). Pusta/niewidzialna -> DEFAULT_NAME.
static func sanitize_name(raw: String) -> String:
	var s := raw.substr(0, RAW_NAME_CAP)
	s = s.replace("\n", " ").replace("\r", " ").replace("\t", " ")
	var clean := ""
	for ch in s:
		var code := ch.unicode_at(0)
		if code < 32 or code == 127 or (code >= 128 and code <= 159):
			continue # znaki sterujace C0 / DEL / C1
		if code == 0x200B or code == 0x200C or code == 0x200D or code == 0x2060 or code == 0xFEFF:
			continue # znaki zero-width - umozliwialyby "niewidzialny" wpis na tablicy
		if code == 0x00A0:
			clean += " " # twarda spacja -> zwykla (strip_edges jej nie tnie)
		else:
			clean += ch
	clean = clean.strip_edges()
	if clean.length() > NAME_MAX_LEN:
		clean = clean.substr(0, NAME_MAX_LEN).strip_edges()
	return clean if clean != "" else DEFAULT_NAME

# Czysta funkcja: z dowolnej wartosci configu wyciaga liste wpisow {name, score}.
# Akceptuje nowy format ({name, score}) i stary (same liczby). Smieci pomijane - brak crasha.
static func sanitize_entries(raw: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (raw is Array):
		return out
	for v in raw:
		if v is Dictionary:
			var sc: Variant = _coerce_score((v as Dictionary).get("score"))
			if sc != null:
				out.append({"name": sanitize_name(str((v as Dictionary).get("name", ""))), "score": sc})
		else:
			var sc: Variant = _coerce_score(v)
			if sc != null:
				out.append({"name": DEFAULT_NAME, "score": sc}) # stary format (same liczby)
	return out

# Czysta funkcja: koercja wyniku do int albo null. Jedno zrodlo taksonomii akceptowanych
# wartosci (int / skonczony float / string-int); bool, inf/nan i reszta smieci odpadaja.
static func _coerce_score(v: Variant) -> Variant:
	if v is int:
		return v
	if v is float and is_finite(v):
		return int(v)
	if v is String and (v as String).is_valid_int():
		return int(v)
	return null

static func clear(path: String = PATH) -> void:
	_save([] as Array[Dictionary], path)

static func _save(list: Array[Dictionary], path: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("scores", "top", list)
	cfg.save(path)
