extends Node3D

var mouse_sensitivity := 0.004
var joystick_horizontal_sensitivity := 2.5
var joystick_vertical_sensitivity := 1.5
var min_limit_x := -1.5
var max_limit_x := 0

func _process(delta: float) -> void:
	var joystick_dir := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	rotate_from_vector(joystick_dir * Vector2(joystick_horizontal_sensitivity, joystick_vertical_sensitivity) * delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_from_vector(event.relative * mouse_sensitivity)

func rotate_from_vector(v: Vector2):
	if v.length() > 0:
		rotation.y -= v.x
		rotation.x -= v.y
		rotation.x = clamp(rotation.x, min_limit_x, max_limit_x)
