extends Node3D


var Sensitivity = .0017

@onready var camera_3d: Camera3D = $Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		self.rotate_y(event.relative.x * -Sensitivity)
		camera_3d.rotate_x(event.relative.y * -Sensitivity)
		
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(-60), deg_to_rad(90))
