extends ProgressBar

@export var player: AnimationPlayer

func _redy():
	player.healthChange.connect(update)
	update()
	 
	
func udaye():
	value = player.currentHealth * 100 player.maxHealth
	
