class_name SkillProjectile
extends Area2D

@export var speed: float = 660.0
@export var lifetime: float = 1.4

var source_data: CharacterData
var direction: Vector2 = Vector2.RIGHT
var damage_multiplier: float = 1.65
var hit: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func setup(data: CharacterData, travel_direction: Vector2) -> void:
	source_data = data
	direction = travel_direction.normalized()
	rotation = direction.angle()
	queue_redraw()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if hit or not source_data or not area.has_method("receive_hit"):
		return
	hit = true
	area.receive_hit(
		source_data.attack * damage_multiplier,
		direction,
		String(source_data.element),
		source_data.display_name
	)
	set_deferred("monitoring", false)
	var burst := create_tween().set_parallel(true)
	burst.tween_property(self, "scale", Vector2(2.1, 2.1), 0.10)
	burst.tween_property(self, "modulate:a", 0.0, 0.10)
	await burst.finished
	queue_free()


func _draw() -> void:
	var color := source_data.accent_color if source_data else Color.WHITE
	draw_line(Vector2(-28, 0), Vector2.ZERO, Color(color, 0.20), 13.0, true)
	draw_line(Vector2(-21, 0), Vector2.ZERO, Color(color, 0.68), 5.0, true)
	draw_circle(Vector2.ZERO, 9.0, color, true)
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE, true)
