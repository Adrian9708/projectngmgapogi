extends Control

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("Pause menu ready. Node name: ", name)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("\n=== ESC PRESSED ===")
		print("Current paused state:", get_tree().paused)
		toggle_pause()
		get_viewport().set_input_as_handled()

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
	show()
	modulate = Color(1, 1, 1, 1)  # Ensure it's not transparent
	z_index = 100  # Bring to front
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	print("After pause_game():")
	print("  - Tree paused:", get_tree().paused)
	print("  - Menu visible:", visible)
	print("  - Parent node:", get_parent().name if get_parent() else "NO PARENT")

func resume_game():
	get_tree().paused = false
	visible = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("Game resumed")

func _on_resume_pressed():
	print("Resume button clicked")
	resume_game()

func _on_restart_pressed():
	print("Restart button clicked")
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()

func _on_quit_pressed():
	print("Quit button clicked")
	get_tree().quit()
