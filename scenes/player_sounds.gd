extends Node3D

@onready var jump_sound: AudioStreamPlayer3D = $JumpSound
@onready var bubble_sound: AudioStreamPlayer3D = $BubbleSound

func play_jump_sound():
	jump_sound.pitch_scale = randf_range(0.9, 1.1)
	jump_sound.play()

func play_bubble_sound():
	bubble_sound.pitch_scale = randf_range(0.9, 1.1)
	bubble_sound.play()