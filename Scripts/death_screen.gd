extends Control

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://Maps/Prototype.tscn")

func _on_stop_motion_pressed() -> void:
	get_tree().change_scene_to_file("res://Maps/Prototype_slowmotion.tscn")


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		get_tree().change_scene_to_file("res://Maps/Prototype.tscn")
	
