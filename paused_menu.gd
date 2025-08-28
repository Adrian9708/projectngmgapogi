extends Control

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("ESC pressed - current paused state:", get_tree().paused)
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		print("Resuming game...")
		resume_game()
	else:
		print("Pausing game...")
		pause_game()

func pause_game():
	get_tree().paused = true
	visible = true
	print("Menu should be visible:", visible)
	# Don't change mouse mode here - let it stay as is for menu interaction

func resume_game():
	get_tree().paused = false
	visible = false
	print("Menu should be hidden:", visible)
	# Only hide cursor if your game normally hides it
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# These functions need to be connected to your buttons
func _on_resume_pressed():
	print("Resume button clicked")
	resume_game()

func _on_restart_pressed():
	print("Restart button clicked")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	print("Quit button clicked")
	get_tree().quit()
