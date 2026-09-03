extends Area2D


func receive_hit(damage: float, direction: Vector2, element: String, source_name: String) -> void:
	var enemy := get_parent()
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(damage, direction, element, source_name)
