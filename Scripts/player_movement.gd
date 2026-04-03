class_name Player extends CharacterBody3D

const SPEED : float = 1.3
const SPRINTSPEED : float = 2.7
const JUMP_VELOCITY : float = 3.0

const turn_speed : float = 200.0
const quick_turn_time : float = 0.4
var is_quick_turning : bool = false

@onready var animation_tree: AnimationTree = $heather/AnimationTree
var animation_state_machine_playback : AnimationNodeStateMachinePlayback
var running : bool = false

var is_dont_move : bool = false
var knockback : Vector3 = Vector3.ZERO

var is_aiming : bool = false
var fired : bool = false
var can_fire : bool = true
@onready var pistol: Node3D = $heather/Armature/Skeleton3D/BoneAttachment3D/pistol
@onready var ray_cast_3d: RayCast3D = $heather/Armature/Skeleton3D/BoneAttachment3D/pistol/Cylinder_Material_0/RayCast3D
@onready var bullet_timer: Timer = $bullet_timer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

const blood_effect : PackedScene = preload("res://Maps/scenes/blood.tscn")

@onready var allmons: Node3D = $"../allmons"
var nearestEnemy : CharacterBody3D 
var nearestEnemy_distance : float = INF
var allreadyfix : bool = false

var health : int = 3
const DEATH_SCREEN = preload("res://Maps/death_screen.tscn")

const MUZZLE = preload("uid://dp5triedcn6i5")
@onready var marker_3d: Marker3D = $heather/Armature/Skeleton3D/BoneAttachment3D/pistol/Marker3D

enum State {
	IDLE,
	WALKING,
	WALK_BACKWARD,
	RUNNING,
	AIMING
}
var current_state : State = State.IDLE

func _ready() -> void:
	animation_state_machine_playback = animation_tree.get("parameters/playback")
	animation_tree.active = true
	

func turn(delta):
	var turn_dir = Input.get_axis("turn_left", "turn_right")
	var input_dir = Input.get_axis("forward", "backward")
	if input_dir != 1 or input_dir == 0:
		rotation_degrees.y -= turn_dir * turn_speed * delta
	else: 
		rotation_degrees.y += turn_dir * turn_speed * delta
		
	
	
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("quick_turn") and not is_quick_turning and !is_dont_move:
		is_quick_turning = true
		var target_y_rotation := rotation.y + PI
		var tween := create_tween() as Tween
		tween.tween_property(self, "rotation:y", target_y_rotation, quick_turn_time)
		check_correct_anim("walk")
		
		tween.finished.connect(func(): is_quick_turning = false )
		
	
func walk(delta):
	var input_dir = Input.get_axis("forward", "backward")
	var direction = basis.z * input_dir
	
	if Input.is_action_pressed("aim"):
		current_state = State.AIMING
		if !allreadyfix:
			calnearst_enemy()
			allreadyfix = true
	elif input_dir == 0.0 or is_dont_move:
		current_state = State.IDLE
	elif input_dir > 0:
		current_state = State.WALK_BACKWARD
	elif input_dir < 0:
		if Input.is_action_pressed("Sprint"):
			current_state = State.RUNNING
		else:
			current_state = State.WALKING
	
	fired = false
	if Input.is_action_just_pressed("fire") and current_state == State.AIMING and can_fire:
		can_fire = false
		fired = true
		
		var muzzle = MUZZLE.instantiate()
		marker_3d.get_parent().add_child(muzzle)
		muzzle.global_position = marker_3d.global_position
		
		audio_stream_player.play()
		bullet_timer.start()
		 
	
	match current_state:
		
		State.IDLE:
			check_correct_anim("idle") 
			velocity.x = 0
			velocity.z = 0
		
		State.WALKING:
			check_correct_anim("walk") 
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		
		State.WALK_BACKWARD:
			check_correct_anim("walk_backward") 
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		
		State.RUNNING:
			check_correct_anim("run") 
			velocity.x = direction.x * SPRINTSPEED 
			velocity.z = direction.z * SPRINTSPEED
		
		State.AIMING:
			pistol.visible = true
			check_correct_anim("aim") 
			velocity.x = 0
			velocity.z = 0
			ray_cast_3d.enabled = true
			
			if allmons.get_children():
				aim_assist(delta)
		
			if ray_cast_3d.is_colliding():
				if ray_cast_3d.get_collider().has_method("do_damage") and fired:
					var body = ray_cast_3d.get_collider()
					body.do_damage(35)
					if !ray_cast_3d.get_collider().died_after_crawl:
						var blood = blood_effect.instantiate()
						get_tree().current_scene.add_child(blood)
						blood.global_position = ray_cast_3d.get_collision_point()
						blood.rotation = rotation   
						blood.get_node("GPUParticles3D").emitting = true
					
					var push_dir = body.global_position - global_position
					push_dir.y = 0
					push_dir = push_dir.normalized()
	
	if Input.is_action_just_released("aim") and allreadyfix:
		pistol.visible = false
		ray_cast_3d.enabled = false
		allreadyfix = false
	

func check_correct_anim(anim):
	if !(animation_state_machine_playback.get_current_node() == anim):
		animation_state_machine_playback.travel(anim)

func _physics_process(delta: float) -> void:
	
	if is_dont_move:
		pistol.visible = false
		ray_cast_3d.enabled = false
		current_state = State.IDLE
		if animation_state_machine_playback.get_current_node() != "push":
			check_correct_anim("idle") 
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	turn(delta)
	walk(delta)
	
	if is_quick_turning:
		velocity.x = 0
		velocity.z = 0
	
	velocity += knockback
	knockback *= 0.91
	if knockback.length() < 0.05:
		knockback = Vector3.ZERO
		
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	

func _on_bullet_timer_timeout() -> void:
	can_fire = true
	
func calnearst_enemy() -> void:
	nearestEnemy_distance = INF
	for i : CharacterBody3D in allmons.get_children():
		var newdis : float = (global_position - i.global_position).length()
		if !(nearestEnemy_distance < newdis):
			nearestEnemy_distance = newdis
			nearestEnemy = i
	if nearestEnemy:
		look_at(Vector3(nearestEnemy.global_position.x, global_position.y, nearestEnemy.global_position.z), Vector3.UP)

func aim_assist(delta):
	var turn_dir = Input.get_axis("turn_left", "turn_right")
	if abs(turn_dir) > 0.05:
		return
	
	var best_enemy : CharacterBody3D
	var best_score : float = INF
		
	for enemy : CharacterBody3D in allmons.get_children():
			
		var target_pos = enemy.global_position
		target_pos.y = global_position.y
		var dir = (target_pos - global_position).normalized()
		var angle = atan2(-dir.x, -dir.z)
		var diff = wrapf(angle - rotation.y, -PI, PI)
		var abs_diff = abs(diff)
		var distance = global_position.distance_to(enemy.global_position)
		var score = abs_diff + (distance * 0.02)
		
		if score < best_score:
			best_score = score
			best_enemy = enemy
	if best_enemy:
		var target_pos = best_enemy.global_position
		target_pos.y = global_position.y
		var dir = (target_pos - global_position).normalized()
		var angle = atan2(-dir.x, -dir.z)
		var diff = wrapf(angle - rotation.y, -PI, PI)
		if abs(diff) < deg_to_rad(60):
			rotation.y += diff * 5 * delta
		
func take_damage():
	health -= 1
	if health <= 0:
		Engine.time_scale = 0.3
		await get_tree().create_timer(0.7, true).timeout
		Engine.time_scale = 1
		get_tree().change_scene_to_packed(DEATH_SCREEN)
	else:
		await get_tree().create_timer(0.8, true).timeout
		check_correct_anim("push")
