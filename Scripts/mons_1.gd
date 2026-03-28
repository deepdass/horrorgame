extends CharacterBody3D

var player : Player = null
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@onready var animation_tree: AnimationTree = $mons1/AnimationTree
var animation_state_machine_playback : AnimationNodeStateMachinePlayback

const SPEED : float = 0.7

func _ready() -> void:
	animation_state_machine_playback = animation_tree.get("parameters/playback")
	animation_tree.active = true


func _process(delta: float) -> void:
	velocity = Vector3.ZERO
	if player:
		look_at(player. global_position)
		navigation_agent_3d.set_target_position(player.global_position)
		var next_nav_point = navigation_agent_3d.get_next_path_position()
		velocity = (next_nav_point - global_position).normalized() * SPEED
		check_correct_anim("walk")
	else:
		check_correct_anim("idle1")
	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body

func check_correct_anim(anim):
	if !(animation_state_machine_playback.get_current_node() == anim):
			animation_state_machine_playback.travel(anim)
