extends Label

var level_time := 0.0
var is_running := true

func _process(delta: float) -> void:
	if is_running:
		level_time += delta
		text = update_time(level_time)

func update_time(time) -> String:
	var minutes := floori(level_time / 60.0)
	var seconds := int(time) % 60
	var milliseconds := int((time - int(time)) * 1000)

	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]