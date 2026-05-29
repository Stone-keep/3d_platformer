extends Node3D

@export var heart_scene: PackedScene
@onready var player: CharacterBody3D = $Characters/Player
@onready var player_hazard_detector: Marker3D = $Characters/Player/HazardDetector
@onready var heart_container: HFlowContainer = $UI/HeartContainer
@onready var black_screen: ColorRect = $UI/BlackScreen
@onready var gridmap: GridMap = $GridMap
@onready var stars: Node3D = $Stars
@onready var stars_label: Label = $UI/StarContainer/StarLabel
@onready var timer_label: Label = $UI/TimerLabel

var total_stars: int
var collected_stars := 0

var last_safe_brick: Vector3i

func _ready() -> void:
	Global.level_won = false
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_death)
	update_hearts(player.health)
	var gold_stars = stars.get_children()
	total_stars = gold_stars.size()
	for star in gold_stars:
		star.collected.connect(_on_gold_star_collected)
	update_stars_label()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.gridmap = gridmap
		

func _physics_process(_delta: float) -> void:
	check_brick_under_player()
	test_game_over()

func update_hearts(health):
	for heart in heart_container.get_children():
		heart.queue_free()
	for h in health:
		var heart = heart_scene.instantiate()
		heart_container.add_child(heart)

func update_stars_label():
	stars_label.text = str(collected_stars, " / ", total_stars)

func check_brick_under_player():
	var check_position := player_hazard_detector.global_position
	var cell := gridmap.local_to_map(gridmap.to_local(check_position))
	var item_id := gridmap.get_cell_item(cell)
	player.current_ground_item_id = item_id
	if item_id != GridMap.INVALID_CELL_ITEM and item_id not in Global.DANGEROUS_BRICK_IDS.values() and player.is_on_floor():
		last_safe_brick = cell
	if item_id == Global.BRICK_IDS["water"]:
		if not player.is_drowning:
			start_drowning_sequence()
	elif item_id == Global.BRICK_IDS["lava"]:
		player.get_hit(1)

func respawn_player_on_cell(cell_id: Vector3i):
	var respawn_position := gridmap.to_global(gridmap.map_to_local(cell_id))
	respawn_position.y += 1.0

	player.global_position = respawn_position
	player.velocity = Vector3.ZERO

func start_drowning_sequence():
	Global.fade_music_out()
	await player.drown()
	await fade_to_black()
	
	player.get_hit(1)
	respawn_player_on_cell(last_safe_brick)
	player.reset_after_drowning()

	await get_tree().create_timer(0.5).timeout

	Global.fade_music_in()
	await fade_from_black()
	player.can_move = true
	

func fade_to_black():
	var tween = create_tween()
	tween.tween_property(black_screen, "modulate", Color(1, 1, 1, 1), 0.5)
	await tween.finished

func fade_from_black():
	var tween = create_tween()
	tween.tween_property(black_screen, "modulate", Color(1, 1, 1, 0), 0.5)
	await tween.finished

func _on_player_health_changed(health: int) -> void:
	update_hearts(health)

func _on_gold_star_collected() -> void:
	collected_stars += 1
	update_stars_label()
	if collected_stars == total_stars:
		trigger_game_over(true)

func _on_player_death():
	trigger_game_over(false)

func test_game_over():
	if Input.is_action_just_pressed("Test01"):
		trigger_game_over(true)
	if Input.is_action_just_pressed("Test02"):
		trigger_game_over(false)

func trigger_game_over(won: bool):
	timer_label.is_running = false
	Global.level_won = won
	Global.final_collected_stars = collected_stars
	Global.final_total_stars = total_stars
	Global.last_time = timer_label.level_time
	if won:
		if not Global.best_time:
			Global.best_time = Global.last_time
		if Global.last_time < Global.best_time:
			Global.best_time = Global.last_time
	get_tree().change_scene_to_file.call_deferred("res://scenes/game_over.tscn")
