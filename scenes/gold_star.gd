extends Area3D

@onready var collect_sound: AudioStreamPlayer3D = $CollectSound
signal collected()

func _process(delta: float) -> void:
	rotation.y += 1.0 * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		collected.emit()
		collect_sound.pitch_scale = randf_range(0.9, 1.1)
		collect_sound.play()
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector3(0.001, 0.001, 0.001), 0.6)
		tween.tween_callback(queue_free)