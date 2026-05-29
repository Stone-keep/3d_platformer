extends Node3D

@onready var jump_sound: AudioStreamPlayer3D = $JumpSound
@onready var bubble_sound: AudioStreamPlayer3D = $BubbleSound
@onready var footstep_sound: AudioStreamPlayer = $FootstepSound

var next_step_is_left := true

var footstep_streams := {
	"sand": {
		"left": [
			preload("res://audio/footsteps/Fantozzi-SandL1.ogg"),
			preload("res://audio/footsteps/Fantozzi-SandL2.ogg"),
			preload("res://audio/footsteps/Fantozzi-SandL3.ogg"),
		],
		"right": [
			preload("res://audio/footsteps/Fantozzi-SandR1.ogg"),
			preload("res://audio/footsteps/Fantozzi-SandR2.ogg"),
			preload("res://audio/footsteps/Fantozzi-SandR3.ogg"),
		],
	},
	"stone": {
		"left": [
			preload("res://audio/footsteps/Fantozzi-StoneL1.ogg"),
			preload("res://audio/footsteps/Fantozzi-StoneL2.ogg"),
			preload("res://audio/footsteps/Fantozzi-StoneL3.ogg"),
		],
		"right": [
			preload("res://audio/footsteps/Fantozzi-StoneR1.ogg"),
			preload("res://audio/footsteps/Fantozzi-StoneR2.ogg"),
			preload("res://audio/footsteps/Fantozzi-StoneR3.ogg"),
		],
	},
	"grass": {
		"left": [
			preload("res://audio/footsteps/sfx_step_grass_l.ogg"),
		],
		"right": [
			preload("res://audio/footsteps/sfx_step_grass_r.ogg"),
		],
	},
}

var footstep_volumes := {
	"sand": -20.0,
	"stone": -20.0,
	"grass": -8.0,
}

func play_jump_sound():
	jump_sound.pitch_scale = randf_range(0.9, 1.1)
	jump_sound.play()

func play_bubble_sound():
	bubble_sound.pitch_scale = randf_range(0.9, 1.1)
	bubble_sound.play()

func play_footstep_sound(item_id: int) -> void:
	var terrain := get_footstep_terrain(item_id)
	if terrain == "":
		return

	var foot := "left" if next_step_is_left else "right"
	var streams: Array = footstep_streams[terrain][foot]

	footstep_sound.stream = streams.pick_random()
	footstep_sound.pitch_scale = randf_range(0.95, 1.08)
	footstep_sound.volume_db = footstep_volumes[terrain] + randf_range(-2.0, 2.0)
	footstep_sound.play()

	next_step_is_left = not next_step_is_left

func get_footstep_terrain(item_id: int) -> String:
	if item_id in [
		Global.BRICK_IDS["dirt"],
		Global.BRICK_IDS["sand_A"],
		Global.BRICK_IDS["sand_B"],
	]:
		return "sand"

	if item_id in [
		Global.BRICK_IDS["grass"],
		Global.BRICK_IDS["dirt_with_grass"],
		Global.BRICK_IDS["sand_with_grass"],
		Global.BRICK_IDS["tree"],
	]:
		return "grass"

	if item_id in [
		Global.BRICK_IDS["bricks_A"],
		Global.BRICK_IDS["bricks_B"],
		Global.BRICK_IDS["metal"],
		Global.BRICK_IDS["stone"],
		Global.BRICK_IDS["wood"],
	]:
		return "stone"

	return ""
