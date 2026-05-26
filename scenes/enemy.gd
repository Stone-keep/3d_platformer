extends CharacterBody3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var move_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var model: Node3D = $Model
@onready var attack_cooldown: Timer = $AttackCooldown

# Movement
var speed := 3.0
var friction := 8.0
var acceleration := 8.0
var direction: Vector3
var target: CharacterBody3D
var can_move := true

var player_in_attack_range := false

func _physics_process(delta: float) -> void:
	move(delta)
	animate(delta)
	attack()
	if can_move:
		move_and_slide()

func move(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if target:
		direction = target.global_position - global_position
		direction.y = 0
		direction = direction.normalized()
		var desired_velocity := direction * speed
		velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * friction)
		velocity.z = move_toward(velocity.z, 0, speed * delta * friction)
		
func attack():
	if player_in_attack_range and attack_cooldown.is_stopped():
		attack_cooldown.start()
		animation_tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func animate(delta: float) -> void:
	move_state_machine.travel("Running" if velocity and not player_in_attack_range else "Idle")
	if direction:
		model.rotation.y = rotate_toward(model.rotation.y, -Vector2(direction.x, direction.z).angle() + PI/2, 6.0 * delta)


func _on_aggro_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		target = body

func _on_aggro_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		target = null

func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = true
		can_move = false

func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = false
		can_move = true
