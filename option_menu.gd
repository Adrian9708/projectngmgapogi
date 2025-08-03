extends Control

@onready var volume_slider = $MenuContainer/VolumeSlider
@onready var mute_button = $MenuContainer/Mute

func _ready():
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
	if get_tree().current_scene == get_parent():
		show()
	else:
		hide()

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


func _on_mute_toggled(toggled_on: bool) -> void:
		pass # Replace with function body.
