extends CharacterBody3D


const SPEED = 1.2
const SPRINTSPEED = 3.5
const JUMP_VELOCITY = 3

const turn_speed = 240
const quick_turn_time = 0.4
var is_quick_turning = false

@onready var animation_tree: AnimationTree = $school_girl/AnimationTree
var velo_z 
var walking = false
var running = false
var is_walking_backward = false

func _ready() -> void:
	animation_tree.active = true

func turn(delta):
	var turn_dir = Input.get_axis("turn_left", "turn_right")
	var input_dir = Input.get_axis("forward", "backward")
	if input_dir != 1 or input_dir == 0:
		rotation_degrees.y -= turn_dir * turn_speed * delta
	else: 
		rotation_degrees.y += turn_dir * turn_speed * delta

func walk():
	var input_dir = Input.get_axis("forward", "backward")
	var direction = basis.z * input_dir
	velo_z = (transform.basis.inverse() * velocity).z
		
	if input_dir != 0:
		if Input.is_action_pressed("Sprint") and velo_z < 0 :
			velocity.x = direction.x * SPRINTSPEED 
			velocity.z = direction.z * SPRINTSPEED
			running = true
			walking = false
		else:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			if is_walking_backward:
				walking = false
			else:
				walking = true
			running = false
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		walking = false
		running = false
		
	if velo_z > 0:
		is_walking_backward = true
	else: 
		is_walking_backward = false
	


func _physics_process(delta: float) -> void:
	
	turn(delta)
	walk()
	
	if is_quick_turning:
		velocity.x = 0
		velocity.z = 0
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	##
	
	move_and_slide()
	
	animation_tree.set("parameters/conditions/idle", velo_z == 0)
	animation_tree.set("parameters/conditions/is_walking", walking)
	animation_tree.set("parameters/conditions/is_running", running)
	animation_tree.set("parameters/conditions/is_walking_backward", is_walking_backward)
	
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("quick_turn") and not is_quick_turning:
		is_quick_turning = true
		var target_y_rotation := rotation.y + PI
		var tween := create_tween() as Tween
		tween.tween_property(self, "rotation:y", target_y_rotation, quick_turn_time)
		
		tween.finished.connect(func(): is_quick_turning = false )
		
	
