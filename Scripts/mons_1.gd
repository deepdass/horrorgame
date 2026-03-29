extends CharacterBody3D

var player : Player = null
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@onready var animation_tree: AnimationTree = $mons1/AnimationTree
enum State {
	IDLE,
	CHASE,
	PREPARE_BITE,
	BITE
}
var state : State = State.IDLE

const SPEED : float = 0.7
const ATTACK_RANGE : float = 0.8

var can_bite : bool = true
var is_bitting : bool = false
@onready var bite_timer: Timer = $bite_timer
@onready var can_bite_timer: Timer = $can_bite_timer
@onready var bite_bef_limit: Timer = $bite_bef_limit
var bite_limit_reached : bool = false
var player_original_rota : float

var health : int = 100

func _ready() -> void:
	animation_tree.active = true
	
func _process(delta):
	if player:
		var direction = player.global_position - global_position
		direction.y = 0
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 5 * delta)
		
	match state:
		State.IDLE:
			velocity = Vector3.ZERO
			if player:
				state = State.CHASE
		
		State.CHASE:
			if player:
				var direction = player.global_position - global_position
				direction.y = 0
				var target_rotation = atan2(direction.x, direction.z)
				rotation.y = lerp_angle(rotation.y, target_rotation, 5 * delta)
	
				navigation_agent_3d.set_target_position(player.global_position)
				var next_nav_point = navigation_agent_3d.get_next_path_position()
				velocity = (next_nav_point - global_position).normalized() * SPEED
	
				if _target_in_range() and can_bite:
					state = State.PREPARE_BITE
					bite_bef_limit.start()
	
		State.PREPARE_BITE:
			velocity = Vector3.ZERO
			if !_target_in_range():
				state = State.CHASE
				
		State.BITE:
			velocity = Vector3.ZERO
			var dir = -(global_position - player.global_position)
			dir.y = 0
			var target_rot = atan2(dir.x, dir.z)
			player.rotation.y = lerp_angle(player.rotation.y, target_rot, 3 * delta)
		
	_update_animation_conditions()
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func _update_animation_conditions():
	if !player:
		animation_tree.set("parameters/conditions/walking", false)
		animation_tree.set("parameters/conditions/bite", false)
		animation_tree.set("parameters/conditions/idle", state == State.IDLE)
		return
	else:
		animation_tree.set("parameters/conditions/idle", false)
	animation_tree.set("parameters/conditions/bite", state == State.BITE)
	animation_tree.set("parameters/conditions/walking", state == State.CHASE)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body


func _on_bite_timer_timeout() -> void:
	player.is_dont_move = false
	is_bitting = false
	var push_dir = (player.global_position - global_position).normalized()
	player.rotation.y = lerp_angle(player.rotation.y, player_original_rota, 1)
	player.knockback = push_dir * 4
	can_bite_timer.start()
	state = State.CHASE

func _on_can_bite_timer_timeout() -> void:
	can_bite = true
	
func _on_bite_bef_limit_timeout() -> void:
	if !_target_in_range():
		state = State.CHASE
		return
	
	state = State.BITE
	is_bitting = true
	can_bite = false
	player_original_rota = player.rotation.y
	player.is_dont_move = true
	bite_timer.start()
	await get_tree().create_timer(1.05).timeout
	get_viewport().get_camera_3d().start_shake()
	

func _target_in_range():
	return (Vector3(player.global_position.x,0,player.global_position.z)
	- Vector3(global_position.x,0,global_position.z)).length() < ATTACK_RANGE
	
func do_damage(damage):
	health -= damage
	print(health)
	if health <= 0:
		print("death")
