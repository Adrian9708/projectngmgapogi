extends Control

@onready var volume_slider = $MenuContainer/VolumeSlider
@onready var mute_button = $MenuContainer/Mute
var back_button: Button

func _ready():
	# Create and add the back button
	create_back_button()
	
	# Connect signals programmatically to ensure they work
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	mute_button.toggled.connect(_on_mute_button_toggled)
	
	# Load saved settings
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var saved_volume = config.get_value("audio", "master_volume", 0.5)
		var is_muted = config.get_value("audio", "is_muted", false)
		
		# Set volume slider
		volume_slider.value = saved_volume
		
		# Set mute button
		mute_button.button_pressed = is_muted
		update_mute_button_text(is_muted)

func _on_volume_slider_value_changed(value):
	# Update volume in real-time
	AudioManager.set_volume(value)

func _on_mute_button_toggled(button_pressed):
	# Update mute state
	AudioManager.set_mute(button_pressed)
	update_mute_button_text(button_pressed)

func update_mute_button_text(is_muted: bool):
	# Update button text based on mute state
	mute_button.text = "Unmute" if is_muted else "Mute"

func create_back_button():
	# Create the back button
	back_button = Button.new()
	back_button.text = "Back"
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Style the button (optional)
	back_button.custom_minimum_size = Vector2(100, 40)
	
	# Connect the button signal
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Add to the MenuContainer
	var menu_container = $MenuContainer
	menu_container.add_child(back_button)

func _on_back_button_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://Menu/Main_menu.tscn")
