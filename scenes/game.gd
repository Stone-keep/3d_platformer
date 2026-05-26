extends Node3D

@export var heart_scene: PackedScene

@onready var player: CharacterBody3D = $Characters/Player
@onready var heart_container: HFlowContainer = $UI/HeartContainer

func _ready() -> void:
	update_hearts(player.health)

func update_hearts(health):
	for heart in heart_container.get_children():
		heart.queue_free()
	for h in health:
		var heart = heart_scene.instantiate()
		heart_container.add_child(heart)

func _on_player_health_changed(health: int) -> void:

	update_hearts(health)
