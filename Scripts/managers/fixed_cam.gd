extends Camera3D

@export var follow_player = false
@export var look_speed : float = 4

var player : Player = null

var shake_strength := 0.13
var shake_time := 0.6
var shake_timer := 0.0
var original_camera_pos : Vector3

func _ready() -> void:
	original_camera_pos = position

func _physics_process(delta: float) -> void:
	if follow_player and player:
		var direction = (player.global_position + Vector3(0, 1.5, 0) - global_position).normalized()
		var target_basis = Basis().looking_at(direction, Vector3.UP)

		global_transform.basis = global_transform.basis.slerp(target_basis, look_speed * delta)
	
	if shake_timer > 0:
		shake_timer -= delta
		var strength = shake_strength * (shake_timer / shake_time)
		position = original_camera_pos + Vector3(
			randf_range(-shake_strength, strength),
			randf_range(-shake_strength, strength),
			0
		)
	else:
		position = original_camera_pos

func start_shake():
	shake_timer = shake_time

func _on_trigger_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body
		current = true
