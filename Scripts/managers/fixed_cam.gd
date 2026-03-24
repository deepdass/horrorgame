extends Camera3D

@export var follow_player = false
@export var look_speed : float = 4

var player : Player = null

func _physics_process(delta: float) -> void:
	if follow_player and player:
		var direction = (player.global_position + Vector3(0, 1.5, 0) - global_position).normalized()
		var target_basis = Basis().looking_at(direction, Vector3.UP)

		global_transform.basis = global_transform.basis.slerp(target_basis, look_speed * delta)


func _on_trigger_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body
		##for camera : Camera3D in get_tree().get_nodes_in_group("camera"): 
			##camera.current = false
		current = true
