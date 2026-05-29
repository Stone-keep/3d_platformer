extends Node3D

@onready var yaw_pivot: Node3D = $CameraYawPivot
@onready var pitch_pivot: Node3D = $CameraYawPivot/CameraPitchPivot

var mouse_sensitivity := 0.004
var joystick_horizontal_sensitivity := 2.5
var joystick_vertical_sensitivity := 1.5
var min_pitch := -1.5
var max_pitch := 0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	var joystick_dir := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
	rotate_from_vector(joystick_dir * Vector2(joystick_horizontal_sensitivity, joystick_vertical_sensitivity) * delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_from_vector(event.relative * mouse_sensitivity)

func rotate_from_vector(v: Vector2):
	if v.length() > 0:
		yaw_pivot.rotation.y -= v.x
		pitch_pivot.rotation.x -= v.y
		pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, min_pitch, max_pitch)
