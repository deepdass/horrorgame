extends Control

func _on_stop_motion_pressed() -> void:
	get_tree().change_scene_to_file("res://Maps/Prototype_slowmotion.tscn")
	

func _on_normal_pressed() -> void:
	get_tree().change_scene_to_file("res://Maps/Prototype.tscn")
