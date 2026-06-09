extends Node

# Autoload "AudioManager": centralne SFX + muzyka. Graceful fallback gdy plik nie istnieje
# (ciche placeholdery na tym etapie - realne OGG wejda pozniej). SFX pool (round-robin)
# zapobiega ucinaniu przy wielu zdarzeniach naraz.

const SFX_PATHS := {
	"harpoon_shot": "res://audio/sfx/GameFX_Shoot_01_fx_BANDLAB.wav",
	"hit": "",
	"enemy_death": "res://audio/sfx/enemy_death.wav",
	"level_up": "",
	"game_over": "",
	"boss_spawn": "",
}

const SFX_POOL_SIZE := 16

# Utwory muzyczne (placeholdery - realne OGG wejda pozniej; graceful fallback gdy brak pliku).
const MUSIC := {
	"gameplay": "res://audio/music/gameplay.ogg",
	"boss": "res://audio/music/boss.ogg",
}
const MUSIC_CROSSFADE := 1.5

var _sfx_streams := {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
# Ostatnio zazadany utwor (intencja) - ustawiany nawet gdy plik to placeholder.
# Pozwala wpiac/testowac muzyke bez realnych plikow audio.
var current_music_track: String = ""

func _ready() -> void:
	# Preload strumieni z graceful fallback (null = cichy placeholder).
	for sfx_name in SFX_PATHS:
		var path: String = SFX_PATHS[sfx_name]
		if path != "" and ResourceLoader.exists(path):
			_sfx_streams[sfx_name] = load(path)
		else:
			_sfx_streams[sfx_name] = null

	# Pula odtwarzaczy SFX (round-robin).
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = _bus_or_master("SFX")
		add_child(p)
		_sfx_players.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _bus_or_master("Music")
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = _bus_or_master("Ambient")
	add_child(_ambient_player)

	# Wyzwalacze globalne (sygnaly GameState).
	GameState.level_up.connect(_on_level_up)
	GameState.game_over.connect(_on_game_over)
	GameState.boss_incoming.connect(_on_boss_incoming)
	GameState.session_reset.connect(_on_session_reset)
	# Glosnosc busow + sesja/accessibility ustawia SettingsStore (autoload przed AudioManager).

func _on_level_up(_new_level: int) -> void:
	play_sfx("level_up")

func _on_game_over() -> void:
	play_sfx("game_over")

func _on_boss_incoming() -> void:
	play_sfx("boss_spawn")
	# Muzyka napiecia: plynne przejscie na utwor bossa.
	crossfade_to(MUSIC["boss"], MUSIC_CROSSFADE)

# Start nowej sesji (reset) - wlacz muzyke rozgrywki.
func _on_session_reset() -> void:
	play_music(MUSIC["gameplay"])

func play_sfx(sfx_name: String) -> void:
	if not _sfx_streams.has(sfx_name):
		return
	var stream = _sfx_streams[sfx_name]
	if stream == null:
		return # graceful fallback - cichy placeholder
	if _sfx_players.is_empty():
		return
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = stream
	player.play()

func play_music(track: String) -> void:
	# Zapisz intencje zawsze (takze dla placeholderow) - wpiecie testowalne bez plikow.
	current_music_track = track
	if _music_player == null:
		return
	if track != "" and ResourceLoader.exists(track):
		_music_player.stream = load(track)
		_music_player.play()

func crossfade_to(track: String, duration: float) -> void:
	# Cel crossfade'u to docelowy utwor - zapisz intencje od razu (testowalne bez plikow).
	current_music_track = track
	# Wycisz Music, podmien utwor, wzmocnij z powrotem (Tween glosnosci busa).
	var tween := create_tween()
	tween.tween_method(_set_music_bus_db, 0.0, -40.0, duration * 0.5)
	tween.tween_callback(func(): play_music(track))
	tween.tween_method(_set_music_bus_db, -40.0, 0.0, duration * 0.5)

func _set_music_bus_db(db: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, db)

func _bus_or_master(bus_name: String) -> String:
	return bus_name if AudioServer.get_bus_index(bus_name) != -1 else "Master"

# Czysta funkcja: liniowa interpolacja glosnosci (db) wg t in [0,1].
static func fade_volume_db(t: float, from_db: float, to_db: float) -> float:
	return from_db + (to_db - from_db) * t
