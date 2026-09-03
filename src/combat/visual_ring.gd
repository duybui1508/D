class_name VisualRing
extends Node2D

var ring_color: Color = Color.WHITE
var max_radius: float = 160.0
var duration: float = 0.45
var elapsed: float = 0.0
var line_width: float = 5.0


func setup(color: Color, radius: float, life: float = 0.45, width: float = 5.0) -> void:
	ring_color = color
	max_radius = radius
	duration = life
	line_width = width
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		queue_free()


func _draw() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var alpha := 1.0 - progress
	draw_circle(Vector2.ZERO, max_radius * eased * 0.45, Color(ring_color, 0.10 * alpha), true)
	draw_arc(
		Vector2.ZERO,
		max_radius * eased,
		0.0,
		TAU,
		72,
		Color(ring_color, alpha),
		line_width * alpha + 1.0,
		true
	)
	draw_arc(
		Vector2.ZERO,
		max_radius * eased * 0.72,
		0.0,
		TAU,
		64,
		Color(Color.WHITE, alpha * 0.38),
		2.0,
		true
	)
