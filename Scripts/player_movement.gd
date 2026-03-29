class_name Player extends CharacterBody3D

const SPEED : float = 1.3
const SPRINTSPEED : float = 3.0
const JUMP_VELOCITY : float = 3.0

const turn_speed : float = 200.0
const quick_turn_time : float = 0.4
var is_quick_turning : bool = false

@onready var animation_tree: AnimationTree = $school_girl/AnimationTree
var animation_state_machine_playback : AnimationNodeStateMachinePlayback
var running : bool = false

var is_dont_move : bool = false
var knockback : Vector3 = Vector3.ZERO

var is_aiming : bool = false
var fired : bool = false
var can_fire : bool = true
@onready var pistol: Node3D = $school_girl/Armature/Skeleton3D/BoneAttachment3D/pistol
@onready var ray_cast_3d: RayCast3D = $school_girl/Armature/Skeleton3D/BoneAttachment3D/pistol/RayCast3D
@onready var bullet_timer: Timer = $bullet_timer

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
			if ray_cast_3d.is_colliding():
				if ray_cast_3d.get_collider().has_method("do_damage") and fired:
					ray_cast_3d.get_collider().do_damage(30)
			
	if Input.is_action_just_released("aim"):
		pistol.visible = false
		ray_cast_3d.enabled = false


func check_correct_anim(anim):
	if !(animation_state_machine_playback.get_current_node() == anim):
		animation_state_machine_playback.travel(anim)

func _physics_process(delta: float) -> void:
	
	if is_dont_move:
		pistol.visible = false
		ray_cast_3d.enabled = false
		current_state = State.IDLE
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
	knockback *= 0.92
	if knockback.length() < 0.05:
		knockback = Vector3.ZERO
		
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	


func _on_bullet_timer_timeout() -> void:
	can_fire = true
