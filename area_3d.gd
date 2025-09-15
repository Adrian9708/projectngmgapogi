extends Area3D
class_name DeliveryDestination

signal delivery_completed(destination)
signal delivery_started(destination)

@export var destination_color: Color = Color.YELLOW
@export var active_color: Color = Color.GREEN
@export var inactive_color: Color = Color.GRAY
@export var destination_id: String = ""
@export var required_item: String = ""
@export var is_active: bool = true
@export var completion_radius: float = 2.0

@onready var mesh_instance = $MeshInstance3D
var material: StandardMaterial3D
var is_player_in_range: bool = false
var delivered_items: Array = []

func _ready():
	# Create material for visual feedback
	material = StandardMaterial3D.new()
	material.albedo_color = destination_color
	material.emission = destination_color * 0.3
	mesh_instance.material_override = material
	
	# Set up visual indicator
	setup_visual_indicator()
	
	# Connect signals to the correct function names
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func setup_visual_indicator():
	# Visual indicator setup without particles
	pass

func _on_body_entered(body):
	if body.is_in_group("player"):
		is_player_in_range = true
		show_delivery_prompt()

func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_in_range = false
		hide_delivery_prompt()

func attempt_delivery(player):
	if not is_active or not is_player_in_range:
		return false
	
	# Check if player has inventory system
	if not player.has_method("get_inventory"):
		complete_delivery(player)
		return true
	
	var player_inventory = player.get_inventory()
	if required_item == "" or player_inventory.has_item(required_item):
		complete_delivery(player)
		return true
	
	return false

func complete_delivery(player):
	delivery_completed.emit(self)
	# Add completion effects
	play_completion_effects()
	
	# Remove item from inventory if needed
	if required_item != "" and player.has_method("get_inventory"):
		var player_inventory = player.get_inventory()
		if player_inventory.has_method("remove_item"):
			player_inventory.remove_item(required_item)

func play_completion_effects():
	# Add your completion effects here
	print("Delivery completed at: ", destination_id)

func show_delivery_prompt():
	# Show UI prompt like "Press E to deliver"
	var ui_path = "UI/DeliveryPrompt"
	if get_viewport().has_node(ui_path):
		var ui = get_viewport().get_node(ui_path)
		if ui.has_method("show_prompt"):
			ui.show_prompt(self)

func hide_delivery_prompt():
	var ui_path = "UI/DeliveryPrompt"
	if get_viewport().has_node(ui_path):
		var ui = get_viewport().get_node(ui_path)
		if ui.has_method("hide_prompt"):
			ui.hide_prompt()
