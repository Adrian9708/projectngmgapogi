extends CharacterBody3D

# Enemy stats
var player = null
var hp = 100

const SPEED = 1.35
const SIGHT_RANGE = 5.0
const ATTACK_RANGE = 0.5
const DAMAGE = 5
const ATTACK_COOLDOWN = 1.5

# Node references
@export var player_path : NodePath
@onready var nav_agent = $NavigationAgent3D
@onready var collision_shape = $CollisionShape3D

# Animation - We'll find it manually
var animation_player : AnimationPlayer

# Enemy state
var is_alive = true
var current_state = "idle"
var attack_cooldown = 0.0
var attack_animation_timer = 0.0  # Track how long we've been in attack state

# For testing animations manually
var test_timer = 0.0
var current_test_anim = 0

func _ready() -> void:
	print("=== ENEMY SETUP START ===")
	
	# Find player
	if player_path.is_empty():
		player = get_tree().get_first_node_in_group("player")
	else:
		player = get_node(player_path)
	
	print("Player found:", player != null)
	
	# DISABLE AnimationTree FIRST before setting up AnimationPlayer
	disable_animation_tree()
	
	# Find AnimationPlayer - let's be very thorough
	find_animation_player()
	
	print("=== ENEMY SETUP COMPLETE ===")

func find_animation_player():
	print("=== SEARCHING FOR ANIMATIONPLAYER ===")
	
	# Method 1: Direct child search
	animation_player = get_node_or_null("AnimationPlayer")
	if animation_player:
		print("Found AnimationPlayer as direct child")
		setup_animation_player()
		return
	
	# Method 2: Find in children recursively
	animation_player = find_child("AnimationPlayer", true, false)
	if animation_player:
		print("Found AnimationPlayer in child nodes:", animation_player.get_path())
		setup_animation_player()
		return
	
	# Method 3: Search entire scene tree
	print("Searching entire scene tree...")
	search_node_for_animation_player(self)
	
	if not animation_player:
		print("ERROR: No AnimationPlayer found anywhere!")
		print("Available nodes in enemy:")
		print_all_children(self, 0)

func search_node_for_animation_player(node: Node):
	if animation_player:
		return
		
	if node is AnimationPlayer:
		animation_player = node
		print("Found AnimationPlayer at:", node.get_path())
		setup_animation_player()
		return
	
	for child in node.get_children():
		search_node_for_animation_player(child)

func setup_animation_player():
	if not animation_player:
		return
		
	print("=== ANIMATIONPLAYER SETUP ===")
	print("AnimationPlayer path:", animation_player.get_path())
	
	# Make sure AnimationPlayer has full control
	animation_player.set_process_mode(Node.PROCESS_MODE_INHERIT)
	
	# Stop any current animations
	if animation_player.is_playing():
		animation_player.stop()
		print("Stopped existing animation")
	
	# Get list of available animations
	var animations = animation_player.get_animation_list()
	print("Available animations:", animations)
	
	if animations.size() == 0:
		print("ERROR: No animations found in AnimationPlayer!")
		return
	
	# Try to play idle animation to start
	var idle_anim = find_animation_by_name("idle")
	if idle_anim != "":
		print("Starting with idle animation:", idle_anim)
		animation_player.play(idle_anim)
	else:
		print("No idle animation found, using first available")
		var first_anim = animations[0]
		animation_player.play(first_anim)
	
	# Give it a moment to start
	await get_tree().create_timer(0.1).timeout
	
	print("After playing - Is playing:", animation_player.is_playing())
	print("Current animation:", animation_player.current_animation)
	
	if not animation_player.is_playing():
		print("ANIMATION NOT PLAYING! Trying to force it...")
		animation_player.seek(0.0)
		if idle_anim != "":
			animation_player.play(idle_anim)
		await get_tree().process_frame
		print("After force - Is playing:", animation_player.is_playing())

func disable_animation_tree():
	print("=== DISABLING ANIMATIONTREE ===")
	
	# Find and disable AnimationTree that might interfere
	var anim_tree = find_child("AnimationTree", true, false)
	if anim_tree:
		print("Found AnimationTree, disabling it")
		anim_tree.active = false
		# Also try to remove it completely from processing
		anim_tree.set_process_mode(Node.PROCESS_MODE_DISABLED)
		print("AnimationTree disabled and process mode set to disabled")
	else:
		print("No AnimationTree found")

func print_all_children(node: Node, indent: int):
	var indent_str = ""
	for i in indent:
		indent_str += "  "
	
	print(indent_str + node.name + " (" + node.get_class() + ")")
	
	for child in node.get_children():
		print_all_children(child, indent + 1)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	# Handle gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.y = 0.0
	
	# Update attack cooldown and animation timer
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	if current_state == "attack":
		attack_animation_timer += delta
	else:
		attack_animation_timer = 0.0
	
	# Skip AI if no player
	if player == null:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	
	# Simple AI logic
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
			
			# Attack if ready
			if attack_cooldown <= 0:
				attack_player()
				attack_cooldown = ATTACK_COOLDOWN
				# Reset animation timer when we actually attack
				attack_animation_timer = 0.0
			
			# Check if we should exit attack state
			if distance_to_player > ATTACK_RANGE * 2.0:
				# Player moved away, chase them
				new_state = "chase"
			elif attack_animation_timer > 1.0 and attack_cooldown <= 0:
				# Animation finished and we're ready to attack again
				# Stay in attack state but trigger new attack animation
				attack_animation_timer = 0.0
				# Force animation restart by briefly changing state
				play_state_animation("attack")
	
	# Update state and play appropriate animation
	if new_state != current_state:
		current_state = new_state
		play_state_animation(current_state)
		print("Enemy state changed to:", current_state)
	
	move_and_slide()

func find_animation_by_name(search_name: String) -> String:
	if not animation_player:
		return ""
	
	var animations = animation_player.get_animation_list()
	
	# Look for exact matches first (case insensitive)
	for anim in animations:
		if anim.to_lower() == search_name.to_lower():
			return anim
	
	# Look for animations that contain the search term
	for anim in animations:
		if anim.to_lower().contains(search_name.to_lower()):
			return anim
	
	return ""

func play_attack_animation():
	"""Specifically handles playing attack animations for repeated attacks"""
	if not animation_player:
		print("ERROR: No AnimationPlayer available for attack animation")
		return
	
	var attack_anim = find_animation_by_name("attack")
	if attack_anim != "":
		print("Playing attack animation:", attack_anim)
		
		# Stop current animation and start attack from beginning
		if animation_player.is_playing():
			animation_player.stop()
		
		await get_tree().process_frame
		animation_player.seek(0.0, true)
		animation_player.play(attack_anim)
		
		print("Attack animation started - Playing:", animation_player.is_playing())
	else:
		print("ERROR: No attack animation found!")
		print("Available animations:", animation_player.get_animation_list())

func play_state_animation(state: String):
	if not animation_player:
		print("ERROR: No AnimationPlayer available for state:", state)
		return
	
	var target_anim = ""
	
	# Find the appropriate animation for each state
	match state:
		"idle":
			target_anim = find_animation_by_name("idle")
		"chase":
			# Try run first, then walk
			target_anim = find_animation_by_name("run")
			if target_anim == "":
				target_anim = find_animation_by_name("walk")
		"attack":
			target_anim = find_animation_by_name("attack")
			# For attack, also reset the animation timer
			attack_animation_timer = 0.0
		"dead":
			target_anim = find_animation_by_name("death")
			if target_anim == "":
				target_anim = find_animation_by_name("die")
	
	# CRITICAL: Always stop current animation before starting new one
	if animation_player.is_playing():
		animation_player.stop()
		print("Stopped current animation:", animation_player.current_animation)
	
	# Play the animation if found
	if target_anim != "":
		print("Playing animation for state", state, ":", target_anim)
		
		# Wait a frame to ensure stop takes effect
		await get_tree().process_frame
		
		# Force seek to beginning and play
		animation_player.seek(0.0, true)
		animation_player.play(target_anim)
		
		# For attack animation, ensure it plays from the beginning
		if state == "attack":
			print("Attack animation started, will play for at least 1 second")
			# Double-check it's actually playing
			await get_tree().process_frame
			if not animation_player.is_playing():
				print("WARNING: Attack animation failed to start!")
				# Try one more time with explicit parameters
				animation_player.play(target_anim, -1, 1.0, false)
		
		print("Animation status - Playing:", animation_player.is_playing(), "Current:", animation_player.current_animation)
	else:
		print("ERROR: No animation found for state:", state)
		print("Available animations:", animation_player.get_animation_list())
		
		# Fallback - stop any current animation at least
		if animation_player.is_playing():
			animation_player.stop()

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
	
	print("Enemy attacking! Damage:", DAMAGE)
	
	if player and player.has_method("take_damage"):
		player.take_damage(DAMAGE)
	else:
		print("Player doesn't have take_damage method")

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
	
	play_state_animation("dead")
	
	print("Enemy died!")
	
	await get_tree().create_timer(3.0).timeout
	queue_free()
