extends CharacterBody3D

const DAMAGE_FLASH_SHADER := preload("res://shaders/damage_flash.gdshader")

@onready var camera_yaw_pivot: Node3D = $CameraController/CameraYawPivot
@onready var model: Node3D = $Model
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var move_state_machine = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var invulnerability_timer = $InvulnerabilityTimer
@onready var jump_sound = $JumpSound

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
var damage_flash_duration := 0.5
var damage_flash_color := Color(1.0, 0.25, 0.15)
var damage_flash_materials: Array[ShaderMaterial] = []
var damage_flash_tween: Tween
signal health_changed(health: int)
signal died()

func _ready() -> void:
	setup_jump_values()
	setup_damage_flash_materials()

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
	jump_sound.play()

func jump_after_hit():
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
		flash_damage()
		print(health)
		health_changed.emit(health)
		if health <= 0:
			died.emit()

		animation_tree.set("parameters/GetHit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func setup_damage_flash_materials() -> void:
	damage_flash_materials.clear()

	for mesh_instance in get_mesh_instances(model):
		var flash_material := ShaderMaterial.new()
		flash_material.shader = DAMAGE_FLASH_SHADER
		flash_material.set_shader_parameter("flash_color", damage_flash_color)
		flash_material.set_shader_parameter("flash_strength", 0.0)
		mesh_instance.material_overlay = flash_material
		damage_flash_materials.append(flash_material)

func get_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var mesh_instances: Array[MeshInstance3D] = []

	for child in root.get_children():
		if child is MeshInstance3D:
			mesh_instances.append(child)
		mesh_instances.append_array(get_mesh_instances(child))

	return mesh_instances

func flash_damage() -> void:
	if damage_flash_tween:
		damage_flash_tween.kill()

	set_damage_flash_strength(1.0)

	damage_flash_tween = create_tween()
	damage_flash_tween.tween_method(set_damage_flash_strength, 1.0, 0.0, damage_flash_duration)

func set_damage_flash_strength(strength: float) -> void:
	for material in damage_flash_materials:
		material.set_shader_parameter("flash_strength", strength)

func can_stomp_enemy() -> bool:
	return was_falling

func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false
