extends CanvasLayer

# Łączymy skrypt z naszym tekstem
@onready var time_label = $Label

func _process(delta):
	# Zwiększamy globalny czas z Twojego GameState
	GameState.time += delta
	
	# Przeliczamy sekundy na format Minuty:Sekundy
	var minutes = int(GameState.time) / 60
	var seconds = int(GameState.time) % 60
	
	# Aktualizujemy tekst na ekranie
	time_label.text = "%02d:%02d" % [minutes, seconds]
