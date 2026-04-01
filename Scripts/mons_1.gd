extends CharacterBody3D

var player : Player = null
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@onready var animation_tree: AnimationTree = $mons1/AnimationTree
@onready var anim_playback : AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
enum State {
	IDLE,
	CHASE,
	PREPARE_BITE,
	BITE,
	DEATH,
	CRAWL
}
var state : State = State.IDLE

const SPEED : float = 0.7
var ATTACK_RANGE : float = 0.9

var can_bite : bool = true
var is_bitting : bool = false
@onready var bite_timer: Timer = $bite_timer
@onready var can_bite_timer: Timer = $can_bite_timer
@onready var bite_bef_limit: Timer = $bite_bef_limit
var bite_limit_reached : bool = false
var player_original_rota : float

var health : int = 100
var knockback : Vector3 = Vector3.ZERO

@onready var blood_particle_bite: Node3D = $blood_particle_bite

@export var can_crawl : bool = false
var died_after_crawl : bool = false

@onready var area_3d: Area3D = $Area3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var corpses: Node3D = $"../../corpses"
@onready var gamemode: Node = $"../../gamemode"

@onready var animation_player: AnimationPlayer = $mons1/AnimationPlayer

var frame_counter := 0
var step_frames := 3

func _ready() -> void:
	animation_tree.active = true
	
	for anim_name in animation_player.get_animation_list():
		var anim = animation_player.get_animation(anim_name)
		
		for track in anim.get_track_count():
			anim.track_set_interpolation_type(track, Animation.INTERPOLATION_NEAREST)
			var interp = anim.track_get_interpolation_type(track)
		
			if interp == Animation.INTERPOLATION_NEAREST:
				print("ok")
	
func _process(delta):
	##print(State.keys()[state])
	

	animation_tree.process_callback = AnimationTree.ANIMATION_PROCESS_MANUAL
	frame_counter += 1
	
	if frame_counter >= step_frames:
		animation_tree.advance(delta * step_frames)
		frame_counter = 0
	
	if player and !state == State.DEATH:
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
	
				navigation_agent_3d.set_target_position(Vector3(player.global_position.x, global_position.y, player.global_position.z))
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
			ATTACK_RANGE = 0.8
		
		State.DEATH:
			velocity = Vector3.ZERO
		
		State.CRAWL:
			if player:
				var direction = player.global_position - global_position
				direction.y = 0
				var target_rotation = atan2(direction.x, direction.z)
				rotation.y = lerp_angle(rotation.y, target_rotation, 5 * delta)
	
				navigation_agent_3d.set_target_position(Vector3(player.global_position.x, global_position.y, player.global_position.z))
				var next_nav_point = navigation_agent_3d.get_next_path_position()
				velocity = (next_nav_point - global_position).normalized() * SPEED * 0.6
	
				if _target_in_range() and can_bite:
					state = State.PREPARE_BITE
					bite_bef_limit.start()
		
	_update_animation_conditions()
	
	velocity += knockback
	knockback *= 0.92
	if knockback.length() < 0.05:
		knockback = Vector3.ZERO
	
	move_and_slide()

func _update_animation_conditions():
	if !player:
		animation_tree.set("parameters/conditions/walking", false)
		animation_tree.set("parameters/conditions/bite", false)
		animation_tree.set("parameters/conditions/fall", state == State.DEATH)
		animation_tree.set("parameters/conditions/should_crawl", false)
		animation_tree.set("parameters/conditions/idle", state == State.IDLE)
		return
	else:
		animation_tree.set("parameters/conditions/idle", false)

	animation_tree.set("parameters/conditions/bite", state == State.BITE)
	animation_tree.set("parameters/conditions/walking", state == State.CHASE)
	animation_tree.set("parameters/conditions/fall", state == State.DEATH or state == State.CRAWL)
	animation_tree.set("parameters/conditions/should_crawl", state == State.CRAWL)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body


func _on_bite_timer_timeout() -> void:
	player.is_dont_move = false
	is_bitting = false
	var push_dir = (player.global_position - global_position).normalized()
	push_dir.y = 0
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

func blood_effect_onbite():
	player.take_damage()
	blood_particle_bite.get_node("GPUParticles3D").emitting = true
	if get_tree():
		await get_tree().create_timer(1).timeout
		blood_particle_bite.get_node("GPUParticles3D").emitting = false

func _target_in_range():
	return (Vector3(player.global_position.x,0,player.global_position.z)
	- Vector3(global_position.x,0,global_position.z)).length() < ATTACK_RANGE
	
func do_damage(damage):
	health -= damage
	if !player:
		player = gamemode.player

	if health <= 0:
		if can_crawl and player:
			state = State.CRAWL
			collision_shape_3d.shape.radius = 0.001
			can_crawl = false
			died_after_crawl = true
			can_bite = false
			await get_tree().create_timer(3).timeout
			collision_shape_3d.shape.radius = 0.28
			health = 10
			ATTACK_RANGE = 1
			can_bite = true
		else:
			state = State.DEATH
			area_3d.monitoring = false
			can_bite = false
			player = null
			
			if died_after_crawl:
				anim_playback.travel("fall_after_crawl")
			get_parent().remove_child(self)
			corpses.add_child(self)
			collision_shape_3d.queue_free()
			await get_tree().create_timer(3).timeout
			set_physics_process(false)
			set_process(false)
			
