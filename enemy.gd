extends CharacterBody3D

var player = null
var hp = 100
var state_machine

const SPEED = 1.3
const ATTACK_RANGE = 1.0
const DAMAGE = 5
const ATTACK_COOLDOWN = 1.5

@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var collision_shape = $CollisionShape3D
@onready var attack_timer = $AttackTimer

var is_alive = true
var attack_cooldown = 0.0

func _ready() -> void:
	player = get_node(player_path)
	if player == null:
		push_error("Player node not found at path: ", player_path)
		return
	if nav_agent == null:
		push_error("NavigationAgent3D not found in scene tree")
		return
	if anim_tree == null:
		push_error("AnimationTree not found in scene tree")
		return
	state_machine = anim_tree.get("parameters/playback")
	if state_machine == null:
		push_error("AnimationTree playback not found. Ensure AnimationTree is set up with a StateMachine.")
		return
	if not attack_timer:
		var timer = Timer.new()
		timer.name = "AttackTimer"
		add_child(timer)
		attack_timer = timer
	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.one_shot = true
	nav_agent.avoidance_enabled = true  # Enable avoidance for better navigation

func _physics_process(delta: float) -> void:
	if not is_alive or state_machine == null:
		return
	
	attack_cooldown -= delta
	print("Current state: ", state_machine.get_current_node()) # Debug
	
	match state_machine.get_current_node():
		"Idle":
			velocity = Vector3.ZERO
			if player_in_sight():
				print("Player in sight, switching to Run") # Debug
				anim_tree.set("parameters/conditions/Idle", false)
				anim_tree.set("parameters/conditions/Run", true)
		
		"Run":
			if not player_in_sight():
				print("Player out of sight, switching to Idle") # Debug
				anim_tree.set("parameters/conditions/Run", false)
				anim_tree.set("parameters/conditions/Idle", true)
				return
				
			nav_agent.set_target_position(player.global_position)
			var next_nav_point = nav_agent.get_next_path_position()
			print("Next nav point: ", next_nav_point, " Distance to target: ", global_position.distance_to(next_nav_point)) # Debug
			var direction = next_nav_point - global_position
			if direction.length() > 0.1:
				velocity = direction.normalized() * SPEED
				print("Velocity set to: ", velocity) # Debug
			else:
				velocity = Vector3.ZERO
				print("Velocity zeroed due to small distance") # Debug
			look_at(Vector3(next_nav_point.x, global_position.y, next_nav_point.z), Vector3.UP)
			
			if target_in_range():
				print("Player in range, switching to Attack") # Debug
				anim_tree.set("parameters/conditions/Run", false)
				anim_tree.set("parameters/conditions/Attack", true)
			
			move_and_slide()
		
		"Attack":
			velocity = Vector3.ZERO
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
			
			if attack_cooldown <= 0 and target_in_range():
				attack_player()
				attack_cooldown = ATTACK_COOLDOWN
				attack_timer.start()
				print("Attack executed, cooldown started") # Debug
				
			if not target_in_range():
				print("Player out of range, switching to Run") # Debug
				anim_tree.set("parameters/conditions/Attack", false)
				anim_tree.set("parameters/conditions/Run", true)
		
		"Death":
			velocity = Vector3.ZERO
			collision_shape.disabled = true
			is_alive = false
			print("Enemy in Death state") # Debug

func player_in_sight() -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 1.0, 0),  # Start above enemy to avoid floor
		player.global_position + Vector3(0, 1.0, 0)  # End at player height
	)
	query.collision_mask = 1  # Match player's collision layer
	query.collide_with_areas = false  # Avoid hitting areas if not intended
	query.collide_with_bodies = true  # Ensure it hits collision bodies
	var result = space_state.intersect_ray(query)
	print("Raycast result: ", result) # Debug
	return result and result.collider == player

func target_in_range() -> bool:
	var in_range = global_position.distance_to(player.global_position) < ATTACK_RANGE
	print("In range: ", in_range, " Distance: ", global_position.distance_to(player.global_position)) # Debug
	return in_range

func attack_player() -> void:
	if is_alive and player.has_method("take_damage"):
		print("Attacking player with ", DAMAGE, " damage") # Debug
		player.take_damage(DAMAGE)

func take_damage(amount: int) -> void:
	if not is_alive:
		return
	
	hp -= amount
	print("Enemy HP reduced to: ", hp) # Debug
	if hp <= 0:
		die()

func die() -> void:
	is_alive = false
	anim_tree.set("parameters/conditions/Idle", false)
	anim_tree.set("parameters/conditions/Run", false)
	anim_tree.set("parameters/conditions/Attack", false)
	anim_tree.set("parameters/conditions/Death", true)
	print("Enemy died, queuing free after 2 seconds") # Debug
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _on_attack_timer_timeout() -> void:
	attack_cooldown = 0.0
	print("Attack cooldown reset") # Debug
