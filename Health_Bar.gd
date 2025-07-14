extends ProgressBar

@export var player: AnimationPlayer

func _redy():
	player.healthChange.connect(update)
	update()
	 
	
func update():
	value = (player.currentHealth / player.maxHealth) * 100
	
	
