extends Camera3D

@export var follow_player = false
var player : Player = null

func _physics_process(_delta: float) -> void:
	if follow_player and player:
		look_at(player.global_position)


func _on_trigger_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body
		##for camera : Camera3D in get_tree().get_nodes_in_group("camera"):
			##camera.current = false
		current = true
