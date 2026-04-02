extends Control

func _ready() -> void:
	Engine.time_scale = 1
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_stop_motion_pressed() -> void:
	get_tree().change_scene_to_file("res://Maps/Prototype_slowmotion.tscn")
	
func _on_normal_pressed() -> void:
	get_tree().change_scene_to_file("res://Maps/Prototype.tscn")
