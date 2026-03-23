extends CharacterBody3D


const SPEED = 100
const SPRINTSPEED = 220
const JUMP_VELOCITY = 3

const turn_speed = 240
const quick_turn_time = 0.4

var is_quick_turning = false

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
	
func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("quick_turn") and not is_quick_turning:
		is_quick_turning = true
		var target_y_rotation := rotation.y + PI
		var tween := create_tween() as Tween
		tween.tween_property(self, "rotation:y", target_y_rotation, quick_turn_time)
		
		tween.finished.connect(func(): is_quick_turning = false )
		
		
		
