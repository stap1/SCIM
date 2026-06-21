class_name ScenePaths
extends RefCounted

# Sciezki scen w jednym miejscu (dedup: byly rozsiane jako literaly w change_scene_to_file).
# Centralizacja lapie literowki i ulatwia ewentualne przenosiny scen.

const MAIN_MENU := "res://scenes/MainMenu.tscn"
const MAIN := "res://scenes/Main.tscn"
const SCORES := "res://scenes/Scores.tscn"
const SETTINGS := "res://scenes/Settings.tscn"
const CREDITS := "res://scenes/Credits.tscn"
