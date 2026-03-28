extends CharacterBody3D

var player : Player = null
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@onready var animation_tree: AnimationTree = $mons1/AnimationTree
var animation_state_machine_playback : AnimationNodeStateMachinePlayback

const SPEED : float = 0.7
const ATTACK_RANGE : float = 0.7

var can_bite : bool = true
var is_bitting : bool = false
@onready var bite_timer: Timer = $bite_timer
@onready var can_bite_timer: Timer = $can_bite_timer
var player_original_rota : float

func _ready() -> void:
	animation_state_machine_playback = animation_tree.get("parameters/playback")
	animation_tree.active = true
	
func _process(delta):
	velocity = Vector3.ZERO
	if player:
		var direction = player.global_position - global_position
		direction.y = 0
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 5 * delta)
		
		if (Vector3(player.global_position.x, 0, player.global_position.z) - Vector3(global_position.x, 0, global_position.z)).length() < ATTACK_RANGE and can_bite and !is_bitting:
			is_bitting = true
			can_bite = false
			player_original_rota = player.rotation.y
			check_correct_anim("bite")
			player.is_dont_move = true
			bite_timer.start()
			await get_tree().create_timer(1.05).timeout
			get_viewport().get_camera_3d().start_shake()
		elif !is_bitting:
			navigation_agent_3d.set_target_position(player.global_position)
			var next_nav_point = navigation_agent_3d.get_next_path_position()
			velocity = (next_nav_point - global_position).normalized() * SPEED
			check_correct_anim("walk")
	else:
		check_correct_anim("idle1")
		
	if is_bitting:
		var dir = -(global_position - player.global_position)
		dir.y = 0
		var target_rot = atan2(dir.x, dir.z)
		player.rotation.y = lerp_angle(player.rotation.y, target_rot, 3 * delta)
	move_and_slide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body

func check_correct_anim(anim):
	if !(animation_state_machine_playback.get_current_node() == anim):
			animation_state_machine_playback.travel(anim)


func _on_bite_timer_timeout() -> void:
	player.is_dont_move = false
	is_bitting = false
	var push_dir = (player.global_position - global_position).normalized()
	player.rotation.y = lerp_angle(player.rotation.y, player_original_rota, 1)
	player.knockback = push_dir * 4
	can_bite_timer.start()
	
func _on_can_bite_timer_timeout() -> void:
	can_bite = true
