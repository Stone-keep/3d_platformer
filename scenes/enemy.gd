extends CharacterBody3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var move_state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/MoveStateMachine/playback")
@onready var model: Node3D = $Model
@onready var collision_alive: CollisionShape3D = $CollisionShapeAlive
@onready var collision_dead: CollisionShape3D = $CollisionShapeDead
@onready var attack_cooldown_timer: Timer = $AttackCooldown
@onready var attack_delay_timer: Timer = $AttackDelay
@onready var death_despawn_timer: Timer = $DeathDespawnTimer

var player: CharacterBody3D

# Movement
var speed := 3.0
var friction := 8.0
var acceleration := 8.0
var idle_when_player_above_height := 1.2
var idle_when_player_above_radius := 1.5
var direction: Vector3
var can_move := true

# Idle Wandering
var home_position: Vector3
var wander_target: Vector3
var wander_wait_time := 0.0
var wander_speed := 1.0
var wander_radius := 3.0
var wander_reach_distance := 0.25
var wander_pause_min := 4.0
var wander_pause_max := 7.0
var wander_after_chase_delay := 5.0
var wander_after_chase_wait_time := 0.0
var is_wandering := false
var was_chasing_player := false
var returning_home := false

# Attack/Damage
var attack_animation_name := "1H_Melee_Attack_Slice_Horizontal"
var player_in_attack_range := false
var attack_delay := false
var attack_damage := 1
var is_attacking := false
var dead := false

func _ready() -> void:
	home_position = global_position
	wander_wait_time = randf_range(wander_pause_min, wander_pause_max)

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

	if can_chase_player():
		was_chasing_player = true
		returning_home = false
		wander_after_chase_wait_time = wander_after_chase_delay
		is_wandering = false
		move_towards(player.global_position, speed, delta)
	elif was_chasing_player:
		handle_lost_player(delta)
	elif can_wander():
		wander(delta)
	else:
		slow_down(delta)

func can_chase_player() -> bool:
	return can_move and player and can_see_player() and is_on_floor() and not is_player_above()

func can_wander() -> bool:
	return can_move and is_on_floor() and not player_in_attack_range and not is_player_above()

func handle_lost_player(delta: float) -> void:
	is_wandering = false

	if wander_after_chase_wait_time > 0.0:
		wander_after_chase_wait_time -= delta
		slow_down(delta)

		if wander_after_chase_wait_time <= 0.0:
			returning_home = true

		return

	if returning_home:
		var distance_to_home := Vector2(
			home_position.x - global_position.x,
			home_position.z - global_position.z
		).length()

		if distance_to_home <= wander_reach_distance:
			returning_home = false
			was_chasing_player = false
			wander_wait_time = randf_range(wander_pause_min, wander_pause_max)
			slow_down(delta)
			return

		move_towards(home_position, wander_speed, delta)
		return

	was_chasing_player = false
	slow_down(delta)

func move_towards(target_position: Vector3, move_speed: float, delta: float) -> void:
	direction = target_position - global_position
	direction.y = 0
	direction = direction.normalized()

	var desired_velocity := direction * move_speed
	velocity.x = move_toward(velocity.x, desired_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_velocity.z, acceleration * delta)

func wander(delta: float) -> void:
	if not is_wandering:
		wander_wait_time -= delta
		slow_down(delta)

		if wander_wait_time <= 0.0:
			pick_wander_target()

		return

	var to_target := wander_target - global_position
	to_target.y = 0

	if to_target.length() <= wander_reach_distance:
		is_wandering = false
		wander_wait_time = randf_range(wander_pause_min, wander_pause_max)
		slow_down(delta)
		return

	move_towards(wander_target, wander_speed, delta)

func pick_wander_target() -> void:
	var random_angle := randf_range(0.0, TAU)
	var random_distance := randf_range(0.0, wander_radius)
	var random_offset := Vector3(cos(random_angle), 0, sin(random_angle)) * random_distance

	wander_target = home_position + random_offset
	is_wandering = true

func slow_down(delta: float) -> void:
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
	if player_in_attack_range and attack_cooldown_timer.is_stopped() and not attack_delay and not is_attacking:
		attack_delay = true
		attack_delay_timer.start()

func animate(delta: float) -> void:
	# Animation Tree
	if can_chase_player():
		move_state_machine.travel("Running_01")
	elif returning_home:
		move_state_machine.travel("Walking_B")
	elif is_wandering:
		move_state_machine.travel("Walking_B")
	else:
		move_state_machine.travel("Idle")
	
	# Rotation
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

		if not returning_home:
			was_chasing_player = true
			wander_after_chase_wait_time = wander_after_chase_delay
			is_wandering = false

func _on_attack_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = true
		attack_delay = false
		can_move = false

func _on_attack_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = false
		attack_delay = false
		can_move = not is_attacking

func _on_attack_delay_timeout() -> void:
	attack_delay = false
	if player and player_in_attack_range and can_see_player():
		player.get_hit(attack_damage)
		attack_cooldown_timer.wait_time = randf_range(2.5, 4.5)
		attack_cooldown_timer.start()
		animation_tree.set("parameters/Attack/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		lock_movement_for_attack()

func lock_movement_for_attack() -> void:
	is_attacking = true
	can_move = false

	var attack_duration := 1.0
	var attack_animation := animation_player.get_animation(attack_animation_name)
	if attack_animation:
		attack_duration = attack_animation.length

	await get_tree().create_timer(attack_duration).timeout

	if dead:
		return

	is_attacking = false
	can_move = not player_in_attack_range

func _on_stomp_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.can_stomp_enemy():
		die()

func _on_death_despawn_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 1, 2.0)
	tween.tween_callback(queue_free)
