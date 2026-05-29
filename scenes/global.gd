extends Node

@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var music_normal_volume := -5.0
var music_muted_volume := -30.0

var best_time: float
var last_time: float
var final_collected_stars: int
var final_total_stars: int
var level_won := false

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

const DANGEROUS_BRICK_IDS := {
	"lava": 5,
	"water": 12
}

func fade_music_out() -> void:
	var tween = create_tween()
	tween.tween_property(background_music, "volume_db", music_muted_volume, 0.5)
	await tween.finished
	background_music.stream_paused = true

func fade_music_in() -> void:
	background_music.stream_paused = false
	var tween = create_tween()
	tween.tween_property(background_music, "volume_db", music_normal_volume, 0.5)
