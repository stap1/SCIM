extends CanvasLayer

# Łączymy skrypt z naszym tekstem
@onready var time_label = $Label

func _process(_delta):
	# HUD jest read-only: czas liczy WYLACZNIE main.gd. Tu tylko odczytujemy wartosc czasu.
	# (Zakaz inkrementacji czasu w HUD - powodowaloby to podwojne liczenie czasu.)

	# Przeliczamy sekundy na format Minuty:Sekundy
	var minutes = int(GameState.time) / 60
	var seconds = int(GameState.time) % 60
	
	# Aktualizujemy tekst na ekranie
	time_label.text = "%02d:%02d" % [minutes, seconds]
