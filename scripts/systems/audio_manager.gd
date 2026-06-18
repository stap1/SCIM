extends Node

const SFX_PATHS := {
	"harpoon_shot": "res://audio/sfx/harpoon_shot.ogg",
	"hit": "res://audio/sfx/hit.ogg",
	"enemy_death": "res://audio/sfx/enemy_death.wav",
	# Brak dedykowanego SFX bossa - tymczasowo reuzywamy enemy_spawn.ogg jako cue.
	# Docelowo podmienic na wlasny dzwiek bossa, gdy asset powstanie.
	"boss_spawn": "res://audio/sfx/enemy_spawn.ogg",
	"player_hit": "res://audio/sfx/player_hit.ogg",
	"level_up": "res://audio/sfx/level_up.ogg",
	# Uwaga: brak klucza "game_over" - ekran porazki gra muzyke (music_gameover.ogg), nie SFX.
	"ui_click": "res://audio/sfx/ui_click.ogg",
	"heal": "res://audio/sfx/heal.ogg",
}

const SFX_POOL_SIZE := 16

const MUSIC := {
	"menu": "res://audio/music/music_menu.ogg",
	"gameplay": "res://audio/music/music_game.ogg",
	"boss": "res://audio/music/music_boss.ogg",
	"gameover": "res://audio/music/music_gameover.ogg",
}

const AMBIENT_PATH := "res://audio/ambient/ambient_sea.ogg"
const MUSIC_CROSSFADE := 1.5

var _sfx_streams := {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var current_music_track: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 1. Inicjalizacja SFX
	for sfx_name in SFX_PATHS:
		var path: String = SFX_PATHS[sfx_name]
		if path != "" and ResourceLoader.exists(path):
			_sfx_streams[sfx_name] = load(path)
		else:
			_sfx_streams[sfx_name] = null

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = _bus_or_master("SFX")
		add_child(p)
		_sfx_players.append(p)

	# 2. Inicjalizacja Muzyki
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _bus_or_master("Music")
	add_child(_music_player)

	# 3. Inicjalizacja Ambientu
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = _bus_or_master("Ambient")
	add_child(_ambient_player)
	
	if ResourceLoader.exists(AMBIENT_PATH):
		_ambient_player.stream = load(AMBIENT_PATH)
		_ambient_player.volume_db = -15.0 # Przyciszenie ambientu w tle
		# Nie odpalamy `.play()` tutaj - funkcję tę przejmuje teraz play_music()

	# 4. Połączenie sygnałów gry
	GameState.level_up.connect(_on_level_up)
	GameState.game_over.connect(_on_game_over)
	GameState.boss_incoming.connect(_on_boss_incoming)
	GameState.session_reset.connect(_on_session_reset)
	
	# Start muzyki menu po załadowaniu klatki
	await get_tree().process_frame
	play_music(MUSIC["menu"])

# Reakcje na sygnały z GameState
func _on_level_up(_new_level: int) -> void: play_sfx("level_up")
func _on_game_over() -> void: play_music(MUSIC["gameover"])
func _on_boss_incoming() -> void: 
	play_sfx("boss_spawn")
	crossfade_to(MUSIC["boss"], MUSIC_CROSSFADE)
func _on_session_reset() -> void: play_music(MUSIC["gameplay"])

# Odtwarzanie efektów dźwiękowych (SFX)
func play_sfx(sfx_name: String) -> void:
	if not _sfx_streams.has(sfx_name): return
	var stream = _sfx_streams[sfx_name]
	if stream == null: return
	var player := _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_players.size()
	player.stream = stream
	player.play()

# Kontrola muzyki
func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()
		_music_player.stream = null

func play_music(track: String) -> void:
	if _music_player == null: return
	
	stop_music()
	current_music_track = track

	if track != "" and ResourceLoader.exists(track):
		_music_player.stream = load(track)
		_music_player.play()
	
	# NOWOŚĆ: Kontrola szumu otoczenia (ambientu) w zależności od utworu
	if _ambient_player != null and _ambient_player.stream != null:
		if track == MUSIC["menu"]:
			if not _ambient_player.playing:
				_ambient_player.play()
		else:
			if _ambient_player.playing:
				_ambient_player.stop()

func crossfade_to(track: String, duration: float) -> void:
	# Zapisz intencje od razu (synchronicznie) - play_music ustawi ja ponownie w callbacku
	# tweena, ale testy wpiecia muzyki czytaja current_music_track tuz po wywolaniu.
	current_music_track = track
	if _music_player == null:
		play_music(track)
		return
	# Crossfade na poziomie ODTWARZACZA muzyki (volume_db), nie busa "Music". Bus trzyma
	# glosnosc ustawiona przez gracza (SettingsStore.apply_bus) - nie wolno go nadpisywac,
	# inaczej po bossie muzyka wracalaby do 0 dB niezaleznie od suwaka gracza.
	var half := maxf(duration, 0.0) * 0.5
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, half)
	tween.tween_callback(func() -> void: play_music(track))
	tween.tween_property(_music_player, "volume_db", 0.0, half)

func _bus_or_master(bus_name: String) -> String:
	return bus_name if AudioServer.get_bus_index(bus_name) != -1 else "Master"

# Czysta funkcja: liniowa interpolacja glosnosci (db) wg t in [0,1].
static func fade_volume_db(t: float, from_db: float, to_db: float) -> float:
	return from_db + (to_db - from_db) * t
