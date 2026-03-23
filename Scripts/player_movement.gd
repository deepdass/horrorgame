extends CharacterBody3D


const SPEED = 100
const SPRINTSPEED = 200
const JUMP_VELOCITY = 3

const turn_speed = 180

func turn(delta):
	var turn_dir = Input.get_axis("turn_left", "turn_right")
	var input_dir = Input.get_axis("forward", "backward")
	if input_dir != 1 or input_dir == 0:
		rotation_degrees.y -= turn_dir * turn_speed * delta
	else: 
		rotation_degrees.y += turn_dir * turn_speed * delta

func walk(delta):
	var input_dir = Input.get_axis("forward", "backward")
	var direction = basis.z * input_dir
	if direction:
		if Input.is_action_pressed("Sprint") and input_dir != 1:
			velocity.x = direction.x * SPRINTSPEED * delta
			velocity.z = direction.z * SPRINTSPEED * delta
		else:
			velocity.x = direction.x * SPEED * delta
			velocity.z = direction.z * SPEED * delta
		
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	
 
@onready var camerarig: Node3D = $camerarig

func _physics_process(delta: float) -> void:
	
	turn(delta)
	walk(delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	##
	
	move_and_slide()
