class_name TypewriterLabel
extends Label

# Wielokrotnego uzytku "maszyna do pisania" - ujawnia tekst litera po literze, klika
# klawiszem (throttlowane, z jitterem pitchu) i na koncu (karetka u konca) gra dzwonek.
# Uzywany przez DialogueBanner (B4) i ostrzezenie o bossie w HUD (B3/B6). Bazuje na
# Label.visible_characters - bez churnu substringow. NIE pauzuje gry sam z siebie.

signal finished

var _active: bool = false
var _elapsed: float = 0.0
var _full_len: int = 0
var _keyed: int = 0  # ile nie-bialych znakow juz "klikneto" (do throttlingu klawisza)

func _ready() -> void:
	set_process(false)

# Rozpoczyna pisanie podanego tekstu od zera.
func start(text_value: String) -> void:
	text = text_value
	_full_len = text_value.length()
	visible_characters = 0
	_elapsed = 0.0
	_keyed = 0
	if _full_len <= 0:
		_finish()
		return
	_active = true
	set_process(true)

# Natychmiast pokazuje calosc (UX/awaryjne) - dzwonek + finished.
func skip() -> void:
	if not _active:
		return
	visible_characters = -1
	_finish()

func is_typing() -> bool:
	return _active

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	var n := visible_count(_elapsed, GameConfig.TYPEWRITER_CPS, _full_len)
	if n != visible_characters:
		_play_keys(visible_characters, n)
		visible_characters = n
	if n >= _full_len:
		_finish()

# Klika klawiszem dla nowo ujawnionych nie-bialych znakow, co TYPEWRITER_KEY_EVERY znakow.
func _play_keys(from_idx: int, to_idx: int) -> void:
	for i in range(from_idx, to_idx):
		if i < 0 or i >= text.length():
			continue
		if text[i].strip_edges() == "":
			continue  # spacja / nowa linia - bez klikniecia
		if _keyed % GameConfig.TYPEWRITER_KEY_EVERY == 0:
			var jitter: float = GameConfig.TYPEWRITER_KEY_PITCH_JITTER
			AudioManager.play_typewriter_key(randf_range(1.0 - jitter, 1.0 + jitter))
		_keyed += 1

func _finish() -> void:
	_active = false
	set_process(false)
	visible_characters = -1
	AudioManager.play_sfx("typewriter_bell")
	finished.emit()

# Czysta funkcja: ile znakow ma byc widocznych po `elapsed` s przy tempie `cps`.
# cps<=0 -> od razu calosc; wynik przyciety do [0, total].
static func visible_count(elapsed: float, cps: float, total: int) -> int:
	if cps <= 0.0:
		return total
	return clampi(int(floor(elapsed * cps)), 0, total)
