extends CharacterBody3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var move_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var model: Node3D = $Model
@onready var collision_alive: CollisionShape3D = $CollisionShapeAlive
@onready var collision_dead: CollisionShape3D = $CollisionShapeDead
@onready var attack_cooldown_timer: Timer = $AttackCooldown
@onready var attack_delay_timer: Timer = $AttackDelay
@onready var death_despawn_timer: Timer = $DeathDespawnTimer

# Movement
var speed := 3.0
var friction := 8.0
var acceleration := 8.0
var idle_when_player_above_height := 1.2
var idle_when_player_above_radius := 1.5
var direction: Vector3
var player: CharacterBody3D
var can_move := true

# Attack/Damage
var player_in_attack_range := false
var attack_delay := false
var attack_damage := 1
var dead := false

func _physics_process(delta: float) -> void:
	if not dead:
		move(delta)
		animate(delta)
		attack()
		if can_move:
			move_and_slide()

func move(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player and can_see_player() and is_on_floor() and not is_player_above():
		direction = player.global_position - global_position
		direction.y = 0
		direction = direction.normalized()
		var desired_velocity := direction * speed
		velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta * friction)
		velocity.z = move_toward(velocity.z, 0, speed * delta * friction)

func is_player_above() -> bool:
	if not player:
		return false

	var horizontal_distance := Vector2(
		player.global_position.x - global_position.x,
		player.global_position.z - global_position.z
	).length()

	return (
		player.global_position.y > global_position.y + idle_when_player_above_height
		and horizontal_distance < idle_when_player_above_radius
	)
		
func can_see_player() -> bool:
	if not player:
		return false
	
	var space_state := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, 1.2, 0)
	var to := player.global_position + Vector3(0, 1, 0)
	
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [self]

	var result := space_state.intersect_ray(query)

	return result.is_empty()

func die() -> void:
	dead = true
	death_despawn_timer.start()
	collision_alive.set_deferred("disabled", true)
	collision_dead.set_deferred("disabled", false)
	var tween = create_tween()
	tween.tween_property(animation_tree, "parameters/DeathBlend/blend_amount", 1.0, 0.8)

func attack() -> void:
	if player_in_attack_range and attack_cooldown_timer.is_stopped() and not attack_delay:
		attack_delay = true
		attack_delay_timer.start()

func animate(delta: float) -> void:
	move_state_machine.travel("Running_01" if velocity and not player_in_attack_range and not is_player_above() else "Idle")
	if direction:
		rotation.y = rotate_toward(
			rotation.y,
			-Vector2(direction.x, direction.z).angle() + PI/2,
			6.0 * delta
			)
	if player_in_attack_range:
		rotation.y = rotate_toward(
			rotation.y,
			-Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z).angle() + PI/2,
			6.0 * delta
			)

func _on_aggro_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_aggro_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = null

func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = true
		attack_delay = false
		can_move = false

func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = false
		attack_delay = false
		can_move = true

func _on_attack_delay_timeout() -> void:
	attack_delay = false
	if player and player_in_attack_range and can_see_player():
		player.get_hit(attack_damage)
		attack_cooldown_timer.wait_time = randf_range(2.5, 4.5)
		attack_cooldown_timer.start()
		animation_tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_stomp_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.can_stomp_enemy():
		die()

func _on_death_despawn_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 1, 2.0)
	tween.tween_callback(queue_free)
