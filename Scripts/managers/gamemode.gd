extends Node

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ESC"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
