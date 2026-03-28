class_name Player extends CharacterBody3D


const SPEED : float = 1.3
const SPRINTSPEED : float = 3.0
const JUMP_VELOCITY : float = 3.0

const turn_speed : float = 240.0
const quick_turn_time : float = 0.4
var is_quick_turning : bool = false

@onready var animation_tree: AnimationTree = $school_girl/AnimationTree
var animation_state_machine_playback : AnimationNodeStateMachinePlayback
var running : bool = false

var is_dont_move : bool = false

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
	if Input.is_action_just_pressed("quick_turn") and not is_quick_turning:
		is_quick_turning = true
		var target_y_rotation := rotation.y + PI
		var tween := create_tween() as Tween
		tween.tween_property(self, "rotation:y", target_y_rotation, quick_turn_time)
		check_correct_anim("walk")
		
		tween.finished.connect(func(): is_quick_turning = false )
		
	

func walk(delta):
	var input_dir = Input.get_axis("forward", "backward")
	var direction = basis.z * input_dir
	
	if input_dir > 0:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		check_correct_anim("walk_backward")
	
	elif input_dir != 0:
		if Input.is_action_pressed("Sprint"):
			velocity.x = direction.x * SPRINTSPEED 
			velocity.z = direction.z * SPRINTSPEED
			check_correct_anim("run")
			running = true
		else:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			check_correct_anim("walk")
			running = false
	else:
		velocity.x = 0
		velocity.z = 0
		check_correct_anim("idle")
		running = false

func check_correct_anim(anim):
	if !(animation_state_machine_playback.get_current_node() == anim):
			animation_state_machine_playback.travel(anim)

func _physics_process(delta: float) -> void:
	
	if is_dont_move:
		velocity = Vector3.ZERO
		check_correct_anim("idle")
		move_and_slide()
		return
	
	turn(delta)
	walk(delta)
	
	if is_quick_turning:
		velocity.x = 0
		velocity.z = 0
	
	## Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("Jump"):
		velocity.y = JUMP_VELOCITY
	##
	move_and_slide()
	
func dont_move():
	print("dont move")
	is_dont_move = true
	
func set_dont_move_false():
	is_dont_move = false
	print("move")
