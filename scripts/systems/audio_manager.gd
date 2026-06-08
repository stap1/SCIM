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

const SFX_POOL_SIZE := 8

const SettingsScript := preload("res://scripts/ui/settings.gd")

var _sfx_streams := {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer

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

	# Zastosuj zapisane ustawienia (glosnosc) i wczytaj dlugosc sesji na starcie gry.
	var s := SettingsScript.load_settings(SettingsScript.SETTINGS_PATH)
	_apply_saved_bus("Music", s["music_vol"])
	_apply_saved_bus("SFX", s["sfx_vol"])
	GameState.session_length = int(s["session_length"])

func _apply_saved_bus(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, SettingsScript.slider_to_db(value))

func _on_level_up(_new_level: int) -> void:
	play_sfx("level_up")

func _on_game_over() -> void:
	play_sfx("game_over")

func _on_boss_incoming() -> void:
	play_sfx("boss_spawn")

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
	if _music_player == null:
		return
	if track != "" and ResourceLoader.exists(track):
		_music_player.stream = load(track)
		_music_player.play()

func crossfade_to(track: String, duration: float) -> void:
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
