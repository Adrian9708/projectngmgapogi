# DeliveryManager.gd - Create this as a separate script
extends Node

var active_destinations: Array[DeliveryDestination] = []
var completed_deliveries: int = 0

# Map boundaries - adjust these to match your map size
@export var map_min_x: float = -100.0
@export var map_max_x: float = 100.0
@export var map_min_z: float = -100.0
@export var map_max_z: float = 100.0
@export var spawn_height: float = 1.0  # Height above ground
@export var number_of_destinations: int = 10

# Preload the destination scene (optional - we'll create programmatically)
# var destination_scene = preload("res://scenes/DeliveryDestination.tscn")

func _ready():
	# Create random destinations
	create_random_destinations()

func create_random_destinations():
	for i in range(number_of_destinations):
		create_destination_at_random_location(i)

func create_destination_at_random_location(index: int):
	# Create destination programmatically
	var destination = create_destination_programmatically()
	
	# Set random position
	var random_pos = get_random_position()
	destination.global_position = random_pos
	
	# Set unique ID
	destination.destination_id = "destination_" + str(index)
	
	# Add to scene
	get_parent().add_child(destination)
	
	# Register the destination
	register_destination(destination)

func create_destination_programmatically() -> DeliveryDestination:
	# Create destination with all required nodes
	var destination = DeliveryDestination.new()
	
	# Add MeshInstance3D
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 2.0
	cylinder_mesh.top_radius = 1.5
	cylinder_mesh.bottom_radius = 1.5
	mesh_instance.mesh = cylinder_mesh
	destination.add_child(mesh_instance)
	
	# Add CollisionShape3D
	var collision_shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.height = 2.0
	cylinder_shape.radius = 1.5
	collision_shape.shape = cylinder_shape
	destination.add_child(collision_shape)
	
	return destination

func get_random_position() -> Vector3:
	var random_x = randf_range(map_min_x, map_max_x)
	var random_z = randf_range(map_min_z, map_max_z)
	return Vector3(random_x, spawn_height, random_z)

func register_destination(destination: DeliveryDestination):
	active_destinations.append(destination)
	destination.delivery_completed.connect(_on_delivery_completed)
	
	# Add destination to a group for easy finding
	destination.add_to_group("delivery_destinations")

func _on_delivery_completed(destination: DeliveryDestination):
	completed_deliveries += 1
	active_destinations.erase(destination)
	print("Delivery completed! Total deliveries: ", completed_deliveries)
	# Spawn next delivery or update UI here

func get_nearest_destination(position: Vector3) -> DeliveryDestination:
	var nearest: DeliveryDestination = null
	var nearest_distance: float = INF
	
	for dest in active_destinations:
		var distance = position.distance_to(dest.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = dest
	
	return nearest
