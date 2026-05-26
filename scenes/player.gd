extends CharacterBody3D

@onready var camera_yaw_pivot: Node3D = $CameraController/CameraYawPivot
@onready var model: Node3D = $Model
@onready var move_state_machine = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var invulnerability_timer = $InvulnerabilityTimer

# Movement
var speed := 5.0
var acceleration := 5.0
var friction := 8.0
var direction: Vector3

# Jumping
@export var jump_height: float = 3.0
@export var jump_time_to_peak: float = 0.5
@export var jump_time_to_descent: float = 0.4
var jump_velocity: float
var jump_gravity: float
var fall_gravity: float
var was_falling := false

# Attack/Damage
var health := 6
var is_invulnerable := false
var invulnerability_time := 2.0

func _ready() -> void:
	setup_jump_values()

func _physics_process(delta: float) -> void:
	get_input()
	move(delta)
	apply_gravity(delta)
	animate(delta)
	was_falling = velocity.y < 0.0
	move_and_slide()

func get_input() -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	direction = (camera_yaw_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()

func move(delta):
	var vel_3d = Vector3(velocity.x, 0, velocity.z)
	if direction:
		vel_3d += direction * speed * delta * acceleration
		vel_3d = vel_3d.limit_length(speed)
		velocity.x = vel_3d.x
		velocity.z = vel_3d.z
	else:
		velocity.x = move_toward(velocity.x, 0, speed * friction * delta)
		velocity.z = move_toward(velocity.z, 0, speed * friction * delta)

func setup_jump_values():
	jump_velocity = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
	jump_gravity = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
	fall_gravity = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

func jump():
	velocity.y = -jump_velocity

func apply_gravity(delta) -> void:
	if not is_on_floor():
		var gravity := jump_gravity if velocity.y > 0 else fall_gravity
		velocity.y -= gravity * delta
	
func animate(delta) -> void:
	if is_on_floor():
		move_state_machine.travel("Running" if direction else "Idle")
	else:
		move_state_machine.travel("Jump")
	if direction:
		var horizontal_velocity := Vector3(velocity.x, 0, velocity.z)
		if horizontal_velocity.length() > 0.2:
			model.rotation.y = rotate_toward(model.rotation.y, -Vector2(horizontal_velocity.x, horizontal_velocity.z).angle() + PI / 2, 8.0 * delta)

func get_hit(damage: int) -> void:
	if not is_invulnerable:
		is_invulnerable = true
		invulnerability_timer.start(invulnerability_time)
		health -= damage
		if health <= 0:
			print("dead")

		$AnimationTree.set("parameters/GetHit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func can_stomp_enemy() -> bool:
	return was_falling