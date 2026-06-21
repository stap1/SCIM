extends GutTest

# Regresja: globalny font gry (uid z project.godot [gui]) musi miec poprawne polskie znaki.
# PressStart2P zle renderowal "ę" (glif wyzej niz reszta) - zastapiony Jersey25.

const FONT_UID := "uid://ol68kawq588u"

func test_game_font_has_polish_glyphs() -> void:
	var f = load(FONT_UID)
	assert_not_null(f, "globalny font (uid z project.godot) laduje sie")
	if f == null:
		return
	var chars := {
		"ę": 0x0119, "ą": 0x0105, "ł": 0x0142, "ż": 0x017C, "ś": 0x015B,
		"ć": 0x0107, "ń": 0x0144, "ó": 0x00F3, "ź": 0x017A, "Ł": 0x0141,
	}
	for name in chars:
		assert_true(f.has_char(chars[name]), "font ma glif '%s'" % name)

func test_global_bold_font_resource() -> void:
	# Globalny font gry (FontVariation z lekkim boldem) - laduje sie i ma polskie glify.
	var gv = load("res://resources/game_font.tres")
	assert_not_null(gv, "game_font.tres laduje sie")
	if gv == null:
		return
	assert_true(gv.has_char(0x0119), "globalny font (bold) ma 'ę'")
	assert_gt(gv.variation_embolden, 0.0, "font jest pogrubiony (embolden > 0)")
