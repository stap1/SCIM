extends GutTest

# R1a: dowod, ze sciezka audio maszyny do pisania dochodzi (klawisz + dzwonek).
# Bez tego efekt jest niemy mimo dzialajacego revealu.

func test_key_stream_loaded() -> void:
	assert_true(AudioManager._sfx_streams.has("typewriter_key"), "klawisz w streamach")
	assert_not_null(AudioManager._sfx_streams.get("typewriter_key"), "stream klawisza zaladowany")

func test_bell_stream_loaded() -> void:
	assert_true(AudioManager._sfx_streams.has("typewriter_bell"), "dzwonek w streamach")
	assert_not_null(AudioManager._sfx_streams.get("typewriter_bell"), "stream dzwonka zaladowany")

func test_play_typewriter_key_assigns_stream() -> void:
	assert_not_null(AudioManager._typewriter_player, "dedykowany player istnieje")
	AudioManager.play_typewriter_key(1.0)
	assert_not_null(AudioManager._typewriter_player.stream,
		"play_typewriter_key ustawia stream (audio realnie dochodzi)")
