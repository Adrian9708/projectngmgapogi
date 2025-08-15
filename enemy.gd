extends CharacterBody3D

var player = null
var hp = 100
var state_machine

const SPEED = 1.3
const ATTACK_RANGE = 1.0
const DAMAGE = 5

@export var player_path : NodePath

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree
@onready var collision_shape = $CollisionShape3D

func _ready() -> void:
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")


func _physics_process(delta: float) -> void:
	match state_machine.get_current_node():
		"Idle":
			anim_tree.set("parameters/conditions/Run", true)
		"Run":
			velocity = Vector3.ZERO

			nav_agent.set_target_position(player.global_position)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_position).normalized() * SPEED
			look_at(Vector3(next_nav_point.x, global_position.y, next_nav_point.z), Vector3.UP)
			anim_tree.set("parameters/conditions/Attack", target_in_range())
			
			move_and_slide()
		"Attack":
			anim_tree.set("parameters/conditions/Run", target_in_range())
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		"Death":
			pass
			
			
			
func target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
