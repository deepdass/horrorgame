extends Path3D

@onready var fixed_cam: Camera3D = $PathFollow3D/fixed_cam
@onready var path_follow_3d: PathFollow3D = $PathFollow3D

func _process(delta: float) -> void:
	if fixed_cam.player != null:
		var player_position = fixed_cam.player.global_position
		path_follow_3d.progress = curve.get_closest_offset(player_position)
