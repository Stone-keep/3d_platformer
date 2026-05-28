extends Node3D

@onready var game_over_label = $CanvasLayer/Control/GameOverLabel
@onready var stars_label = $CanvasLayer/Control/StarsContainer/StarsLabel
@onready var last_time_label = $CanvasLayer/Control/LastTimeLabel
@onready var best_time_label = $CanvasLayer/Control/BestTimeLabel
@onready var animation_player = $Player/AnimationPlayer

func _ready() -> void:
	if Global.level_won:
		game_over_label.text = "You Won! Congratulations!"
		animation_player.play("Cheer")
	else:
		game_over_label.text = "You Lost! Try Again!"
		animation_player.play("Sit_Floor_Idle")
	var last_time = format_time(Global.last_time)
	last_time_label.text = "Time Played: " + last_time
	if not Global.best_time:
		best_time_label.text = "Best Time: You haven't beaten this level yet"
	else:
		var best_time = format_time(Global.best_time)
		best_time_label.text = "Best Time: " + best_time

func format_time(time) -> String:
	var minutes := floori(time / 60.0)
	var seconds := int(time) % 60
	var milliseconds := int((time - int(time)) * 1000)

	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()