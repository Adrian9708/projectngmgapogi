extends CharacterBody3D

# Enemy stats
var player = null
var hp = 100

const SPEED = 1.35
const SIGHT_RANGE = 5.0
const ATTACK_RANGE = 0.5
const DAMAGE = -5  # KEPT as -5 as requested
const ATTACK_COOLDOWN = 1.5

# Node references
@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D
@onready var collision_shape = $CollisionShape3D

# Animation
var animation_player : AnimationPlayer

# Enemy state
var is_alive = true
var current_state = "idle"
var attack_cooldown = 0.0

func _ready() -> void:
	print("=== ENEMY SETUP START ===")
	
	# Find player
	if player_path.is_empty():
		player = get_tree().get_first_node_in_group("player")
	else:
		player = get_node(player_path)
	
	print("Player found:", player != null)
	
	# Disable AnimationTree first
	disable_animation_tree()
	
	# Find AnimationPlayer
	find_animation_player()
	
	print("=== ENEMY SETUP COMPLETE ===")

func find_animation_player():
	print("=== SEARCHING FOR ANIMATIONPLAYER ===")
	
	# Try multiple methods to find AnimationPlayer
	animation_player = get_node_or_null("AnimationPlayer")
	if not animation_player:
		animation_player = find_child("AnimationPlayer", true, false)
	
	if animation_player:
		print("Found AnimationPlayer at:", animation_player.get_path())
		setup_animation_player()
	else:
		print("ERROR: No AnimationPlayer found!")

func setup_animation_player():
	if not animation_player:
		return
		
	print("=== ANIMATIONPLAYER SETUP ===")
	print("Available animations:", animation_player.get_animation_list())
	
	# Play idle to start
	var idle_anim = find_animation_by_name("idle")
	if idle_anim != "":
		animation_player.play(idle_anim)
		print("Started idle animation")

func disable_animation_tree():
	var anim_tree = find_child("AnimationTree", true, false)
	if anim_tree:
		anim_tree.active = false
		anim_tree.set_process_mode(Node.PROCESS_MODE_DISABLED)
		print("AnimationTree disabled")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	# Handle gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.y = 0.0
	
	# Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Skip AI if no player
	if player == null:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	
	# AI logic
	var distance_to_player = global_position.distance_to(player.global_position)
	var can_see = can_see_player()
	
	var new_state = current_state
	
	match current_state:
		"idle":
			velocity.x = 0
			velocity.z = 0
			
			if distance_to_player < SIGHT_RANGE and can_see:
				new_state = "chase"
		
		"chase":
			if distance_to_player > SIGHT_RANGE or not can_see:
				new_state = "idle"
			elif distance_to_player <= ATTACK_RANGE:
				new_state = "attack"
			else:
				# Move toward player
				var direction = (player.global_position - global_position)
				direction.y = 0
				direction = direction.normalized()
				
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
				
				# Face movement direction
				if direction.length() > 0.01:
					look_at(global_position + direction, Vector3.UP)
		
		"attack":
			velocity.x = 0
			velocity.z = 0
			
			# Face player
			var look_dir = (player.global_position - global_position)
			look_dir.y = 0
			if look_dir.length() > 0.01:
				look_at(global_position + look_dir.normalized(), Vector3.UP)
			
			# Attack if cooldown is ready
			if attack_cooldown <= 0:
				print("Enemy attacking player!")
				attack_player()
				attack_cooldown = ATTACK_COOLDOWN
				
				# Play attack animation
				play_animation("attack")
			
			# Exit attack state if player moves away
			if distance_to_player > ATTACK_RANGE * 1.5:
				new_state = "chase"
	
	# Change state and animation
	if new_state != current_state:
		current_state = new_state
		print("Enemy state changed to:", current_state)
		
		# Play appropriate animation for new state
		match current_state:
			"idle":
				play_animation("idle")
			"chase":
				play_animation("run")
			"attack":
				play_animation("attack")
	
	move_and_slide()

func find_animation_by_name(search_name: String) -> String:
	if not animation_player:
		return ""
	
	var animations = animation_player.get_animation_list()
	
	# Look for exact matches first
	for anim in animations:
		if anim.to_lower() == search_name.to_lower():
			return anim
	
	# Look for animations containing the search term
	for anim in animations:
		if anim.to_lower().contains(search_name.to_lower()):
			return anim
	
	return ""

func play_animation(anim_name: String):
	if not animation_player:
		return
	
	var target_anim = find_animation_by_name(anim_name)
	
	if target_anim == "":
		# Fallback animations
		if anim_name == "run":
			target_anim = find_animation_by_name("walk")
	
	if target_anim != "":
		# Only change if different animation
		if animation_player.current_animation != target_anim:
			animation_player.play(target_anim)
			print("Playing animation:", target_anim)

func can_see_player() -> bool:
	if player == null:
		return false
	
	var space_state = get_world_3d().direct_space_state
	var start_pos = global_position + Vector3(0, 1.5, 0)
	var end_pos = player.global_position + Vector3(0, 1.0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [self]
	query.collision_mask = 1
	
	var result = space_state.intersect_ray(query)
	return not result or result.collider == player

func attack_player() -> void:
	if not is_alive:
		return
	
	print("Enemy dealing", DAMAGE, "damage to player")
	
	if player and player.has_method("take_damage"):
		player.take_damage(DAMAGE)  # Passes -5 to player
	else:
		print("ERROR: Player doesn't have take_damage method")

func take_damage(amount: int) -> void:
	if not is_alive:
		return
	
	hp -= amount
	print("Enemy took damage! HP:", hp, "/100")
	
	if hp <= 0:
		die()

func die() -> void:
	is_alive = false
	current_state = "dead"
	velocity = Vector3.ZERO
	
	if collision_shape:
		collision_shape.disabled = true
	
	play_animation("death")
	
	print("Enemy died!")
	
	await get_tree().create_timer(3.0).timeout
	queue_free()

# Removed Area3D handler that was interfering
