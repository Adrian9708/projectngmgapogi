extends Control

# Exported variables for easy configuration in the Godot editor
@export var game_scene_path: String = "D:/projectngmgapogi/pizzamap.tscn"  # Path to your game scene
@export var options_scene_path: String = "res://Scenes/Options.tscn"  # Path to your options scene

# References to the buttons (Godot will connect these automatically if nodes are named correctly)
@onready var start_button = $Start
@onready var options_button = $Option
@onready var quit_button = $Exit

func _ready():
	# Connect button signals to their respective functions
	start_button.pressed.connect(_on_start_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	print("Loading game...")
	# Load the game scene (replace the current scene with the game scene)
	get_tree().change_scene_to_file("res://pizzamap.tscn")

func _on_options_button_pressed():
	print("Showing options...")
	# Load the options scene (replace the current scene with the options scene)
	get_tree().change_scene_to_file(options_scene_path)

func _on_quit_button_pressed():
	print("Quitting game...")
	# Quit the game
	get_tree().quit()
