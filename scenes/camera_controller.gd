extends Node3D

@onready var camera := $Camera3D
var mouse_acceleration := 0.005
var min_limit_x := -0.8
var max_limit_x := -0.2

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		print(event)
		rotate_from_vector(event.relative * mouse_acceleration)

func rotate_from_vector(v: Vector2):
	if v.length() > 0:
		rotation.y -= v.x
		camera.rotation.x -= v.y
		camera.rotation.x = clamp(camera.rotation.x, min_limit_x, max_limit_x)
