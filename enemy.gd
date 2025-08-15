extends CharacterBody3D

var player = null

const SPEED = 1.3

@export var player_path : NodePath
@onready var aux_scene: Node3D = $"character-male-f2"
enum animation_state {IDLE,RUNNING,JUMPING}
var player_animation_state : animation_state = animation_state.IDLE
@onready var animation_player : AnimationPlayer = $"playermodel/character-male-f2/AnimationPlayer"

@onready var nav_agent = $NavigationAgent3D

func _ready() -> void:
	player = get_node(player_path)

func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	
	nav_agent.set_target_position(player.global_position)
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_position).normalized() * SPEED
	
	move_and_slide()
