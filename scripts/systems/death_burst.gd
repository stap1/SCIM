extends CPUParticles2D

# Niezalezny burst smierci wroga. Odpala sie sam (emitting=true, one_shot w .tscn)
# i zwalnia sie po zakonczeniu animacji oraz dzwieku - nie zalezy od znikajacego wroga.

func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	queue_free()
