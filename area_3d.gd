extends Area3D

@export var destination_color: Color = Color.YELLOW
@export var active_color: Color = Color.GREEN
@export var inactive_color: Color = Color.GRAY

@onready var mesh_instance = $MeshInstance3D
var material: StandardMaterial3D

func _ready():
	# Create material for visual feedback
	material = StandardMaterial3D.new()
	material.albedo_color = destination_color
	material.emission = destination_color * 0.3
	mesh_instance.material_override = material
	
	# Connect signals
	body_entered.connect(_on_delivery_entered)
	body_exited.connect(_on_delivery_exited)
