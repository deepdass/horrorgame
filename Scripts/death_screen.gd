extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://Maps/Prototype.tscn")
