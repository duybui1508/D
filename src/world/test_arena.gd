class_name TestArena
extends Node2D

const ARENA_RECT := Rect2(-760, -440, 1520, 880)
const WALL_COLOR := Color("202b48")
const WALL_EDGE := Color("4d6a9f")

var dust_points: PackedVector2Array = []


func _ready() -> void:
	seed(7331)
	for index in 80:
		dust_points.append(
			Vector2(
				randf_range(ARENA_RECT.position.x, ARENA_RECT.end.x),
				randf_range(ARENA_RECT.position.y, ARENA_RECT.end.y)
			)
		)
	_build_collision()
	queue_redraw()


func _build_collision() -> void:
	_make_wall(Rect2(-800, -480, 1600, 40))
	_make_wall(Rect2(-800, 440, 1600, 40))
	_make_wall(Rect2(-800, -440, 40, 880))
	_make_wall(Rect2(760, -440, 40, 880))
	_make_wall(Rect2(-315, -155, 120, 310))
	_make_wall(Rect2(220, -295, 170, 70))
	_make_wall(Rect2(290, 205, 170, 70))
	_make_wall(Rect2(-25, 270, 80, 130))


func _make_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)

	var visual := Polygon2D.new()
	var half := rect.size * 0.5
	visual.polygon = PackedVector2Array(
		[
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		]
	)
	visual.color = WALL_COLOR
	visual.position = rect.get_center()
	visual.z_index = 3
	add_child(visual)

	var edge := Line2D.new()
	edge.points = PackedVector2Array(
		[
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
			Vector2(-half.x, -half.y),
		]
	)
	edge.width = 2.0
	edge.default_color = WALL_EDGE
	edge.position = rect.get_center()
	edge.z_index = 4
	add_child(edge)


func _draw() -> void:
	draw_rect(ARENA_RECT, Color("0c1324"), true)
	for x in range(int(ARENA_RECT.position.x), int(ARENA_RECT.end.x) + 1, 64):
		draw_line(
			Vector2(x, ARENA_RECT.position.y),
			Vector2(x, ARENA_RECT.end.y),
			Color(0.22, 0.35, 0.55, 0.08),
			1.0
		)
	for y in range(int(ARENA_RECT.position.y), int(ARENA_RECT.end.y) + 1, 64):
		draw_line(
			Vector2(ARENA_RECT.position.x, y),
			Vector2(ARENA_RECT.end.x, y),
			Color(0.22, 0.35, 0.55, 0.08),
			1.0
		)
	for point in dust_points:
		draw_circle(point, 1.5, Color(0.45, 0.68, 0.95, 0.20), true)

	_draw_spawn_pad(Vector2.ZERO, Color("52e1ff"))
	_draw_spawn_pad(Vector2(510, -250), Color("ff5578"))
	_draw_spawn_pad(Vector2(525, 270), Color("ff5578"))
	draw_string(
		ThemeDB.fallback_font,
		Vector2(-720, -390),
		"COMBAT CELL 07 // LIVE SIMULATION",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		18,
		Color("6e86b5")
	)


func _draw_spawn_pad(center: Vector2, color: Color) -> void:
	draw_circle(center, 74.0, Color(color, 0.025), true)
	draw_arc(center, 74.0, 0.0, TAU, 52, Color(color, 0.28), 2.0, true)
	draw_arc(center, 54.0, 0.0, TAU, 52, Color(color, 0.10), 1.0, true)
	for index in 4:
		var angle := PI * 0.25 + index * PI * 0.5
		var tangent := Vector2.from_angle(angle)
		draw_line(center + tangent * 58.0, center + tangent * 73.0, color, 3.0, true)
