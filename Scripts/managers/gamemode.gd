extends Node

@onready var player: Player = $"../player"

func _ready() -> void:
	Engine.time_scale = 1
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ESC"):
		get_tree().change_scene_to_file("res://Maps/startup.tscn")
		
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
