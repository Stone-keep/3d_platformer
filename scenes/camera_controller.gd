extends Node3D

@onready var camera := $Camera3D
var mouse_sensitivity := 0.004
var joystick_sensitivity := 2.0
var min_limit_x := -0.8
var max_limit_x := -0.2

func _process(delta: float) -> void:
	var joystick_dir := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	rotate_from_vector(joystick_dir * joystick_sensitivity * delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_from_vector(event.relative * mouse_sensitivity)

func rotate_from_vector(v: Vector2):
	if v.length() > 0:
		rotation.y -= v.x
		camera.rotation.x -= v.y
		camera.rotation.x = clamp(camera.rotation.x, min_limit_x, max_limit_x)
