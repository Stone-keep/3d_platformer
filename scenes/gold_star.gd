extends Area3D

signal collected()

func _process(delta: float) -> void:
	rotation.y += 1.0 * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		collected.emit()
		queue_free()