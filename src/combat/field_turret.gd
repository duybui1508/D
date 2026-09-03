class_name FieldTurret
extends Node2D

var source_data: CharacterData
var duration_left: float = 7.0
var fire_cooldown: float = 0.15
var pulse: float = 0.0
var beam_to: Vector2 = Vector2.ZERO
var beam_left: float = 0.0
var expiring: bool = false


func setup(data: CharacterData) -> void:
	source_data = data
	queue_redraw()


func _process(delta: float) -> void:
	if not source_data:
		return
	duration_left -= delta
	fire_cooldown -= delta
	beam_left = maxf(0.0, beam_left - delta)
	pulse += delta * 3.2
	if fire_cooldown <= 0.0:
		fire_cooldown = 0.78
		_fire_at_nearest()
	queue_redraw()
	if duration_left <= 0.0 and not expiring:
		expiring = true
		set_process(false)
		var fade := create_tween()
		fade.tween_property(self, "scale", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(
			Tween.EASE_IN
		)
		await fade.finished
		queue_free()


func _fire_at_nearest() -> void:
	var nearest: EnemyDummy
	var nearest_distance := 420.0
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(candidate) or candidate.dead:
			continue
		var distance: float = global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate as EnemyDummy
			nearest_distance = distance
	if not nearest:
		return
	beam_to = to_local(nearest.global_position)
	beam_left = 0.13
	var direction := global_position.direction_to(nearest.global_position)
	nearest.take_damage(
		source_data.attack * 0.58, direction, String(source_data.element), source_data.display_name
	)


func _draw() -> void:
	var color := source_data.accent_color if source_data else Color("ffc55f")
	draw_circle(Vector2.ZERO, 18.0 + sin(pulse) * 2.0, Color(color, 0.12), true)
	draw_arc(Vector2.ZERO, 18.0, pulse, pulse + 4.35, 28, color, 3.0, true)
	draw_circle(Vector2.ZERO, 7.0, color, true)
	draw_line(Vector2(-14, 20), Vector2(-21, 30), color, 4.0)
	draw_line(Vector2(14, 20), Vector2(21, 30), color, 4.0)
	if beam_left > 0.0:
		draw_line(Vector2.ZERO, beam_to, Color(color, beam_left / 0.13), 5.0, true)
		draw_circle(beam_to, 8.0, Color(color, 0.65), true)
