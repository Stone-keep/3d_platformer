extends Node

@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var music_normal_volume := -5.0
var music_muted_volume := -30.0

var best_time: float
var last_time: float
var final_collected_stars: int
var final_total_stars: int
var level_won := false


func fade_music_out() -> void:
	var tween = create_tween()
	tween.tween_property(background_music, "volume_db", music_muted_volume, 0.5)
	await tween.finished
	background_music.stream_paused = true

func fade_music_in() -> void:
	background_music.stream_paused = false
	var tween = create_tween()
	tween.tween_property(background_music, "volume_db", music_normal_volume, 0.5)
