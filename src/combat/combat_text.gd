class_name CombatText
extends Label


func setup(text_value: String, color_value: Color) -> void:
	text = text_value
	modulate = color_value
	pivot_offset = size * 0.5
	var drift := create_tween().set_parallel(true)
	(
		drift
		. tween_property(self, "position", position - Vector2(0, 36), 0.62)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	drift.tween_property(self, "modulate:a", 0.0, 0.62).set_delay(0.22)
	await drift.finished
	queue_free()
