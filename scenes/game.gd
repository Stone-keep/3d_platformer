extends Node3D

@export var heart_scene: PackedScene
@onready var player: CharacterBody3D = $Characters/Player
@onready var player_hazard_detector: Marker3D = $Characters/Player/HazardDetector
@onready var heart_container: HFlowContainer = $UI/HeartContainer
@onready var gridmap: GridMap = $GridMap

const BRICK_IDS := {
	"bricks_A": 0,
	"bricks_B": 1,
	"dirt": 2,
	"dirt_with_grass": 3,
	"grass": 4,
	"lava": 5,
	"metal": 6,
	"sand_A": 7,
	"sand_B": 8,
	"sand_with_grass": 9,
	"stone": 10,
	"tree": 11,
	"water": 12,
	"wood": 13,
}

func _ready() -> void:
	player.health_changed.connect(_on_player_health_changed)
	update_hearts(player.health)
	
func _physics_process(_delta: float) -> void:
	check_brick_under_player()

func update_hearts(health):
	for heart in heart_container.get_children():
		heart.queue_free()
	for h in health:
		var heart = heart_scene.instantiate()
		heart_container.add_child(heart)

func check_brick_under_player():
	var check_position := player_hazard_detector.global_position
	var cell := gridmap.local_to_map(gridmap.to_local(check_position))
	var item_id := gridmap.get_cell_item(cell)

	if item_id == BRICK_IDS["water"]:
		print("Player is on water")

	if item_id == BRICK_IDS["lava"]:
		player.get_hit(1)


func _on_player_health_changed(health: int) -> void:
	update_hearts(health)
