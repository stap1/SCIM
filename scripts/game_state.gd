extends Node

var score: int = 0
var time: float = 0.0
var level: int = 1
var xp: int = 0

# Funkcja do resetowania gry po śmierci gracza
func reset_state():
	score = 0
	time = 0.0
	level = 1
	xp = 0
