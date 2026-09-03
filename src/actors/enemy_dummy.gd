class_name EnemyDummy
extends CharacterBody2D

signal hp_changed(enemy: EnemyDummy)
signal died(enemy: EnemyDummy)
signal combat_text_requested(text: String, world_position: Vector2, color: Color)

@export var max_hp: float = 260.0
@export var move_speed: float = 92.0
@export var attack_damage: float = 18.0

var hp: float
var target: PlayerCharacter
var attack_cooldown_left: float = 0.0
var dead: bool = false
var spawn_position: Vector2
var variant: int = 0
var infused_element: String = ""
var infusion_left: float = 0.0
var reaction_lock_left: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $EnemyHurtbox


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	spawn_position = global_position
	target = get_tree().get_first_node_in_group("player") as PlayerCharacter
	queue_redraw()


func _physics_process(delta: float) -> void:
	if dead:
		return
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	infusion_left = maxf(0.0, infusion_left - delta)
	reaction_lock_left = maxf(0.0, reaction_lock_left - delta)
	if infusion_left <= 0.0:
		infused_element = ""
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as PlayerCharacter
		return
	var to_target := target.global_position - global_position
	var distance := to_target.length()
	if distance < 58.0:
		velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)
		if attack_cooldown_left <= 0.0:
			attack_cooldown_left = 1.25
			_attack()
	elif distance < 520.0:
		velocity = to_target.normalized() * move_speed
	else:
		var home_vector := spawn_position - global_position
		velocity = (
			home_vector.normalized() * move_speed * 0.55
			if home_vector.length() > 12.0
			else Vector2.ZERO
		)
	move_and_slide()
	sprite.flip_h = velocity.x < -0.1
	sprite.rotation = sin(Time.get_ticks_msec() * 0.008 + variant) * 0.045


func _attack() -> void:
	var original_scale := sprite.scale
	var lunge := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lunge.tween_property(sprite, "scale", original_scale * Vector2(1.25, 0.75), 0.12)
	lunge.tween_property(sprite, "scale", original_scale, 0.20)
	await get_tree().create_timer(0.14).timeout
	if is_instance_valid(target) and global_position.distance_to(target.global_position) < 76.0:
		target.take_damage(attack_damage)


func take_damage(damage: float, direction: Vector2, element: String, _source_name: String) -> void:
	if dead:
		return
	var total_damage := damage
	if not infused_element.is_empty() and infused_element != element and reaction_lock_left <= 0.0:
		var reaction_damage := damage * 0.45
		total_damage += reaction_damage
		reaction_lock_left = 0.55
		combat_text_requested.emit(
			"RIFT REACTION +%d" % roundi(reaction_damage),
			global_position - Vector2(0, 88),
			Color("fff29a")
		)
	infused_element = element
	infusion_left = 4.0
	hp = maxf(0.0, hp - total_damage)
	velocity += direction.normalized() * 115.0
	combat_text_requested.emit(
		"%d  %s" % [roundi(total_damage), element.to_upper()],
		global_position - Vector2(0, 66),
		Color("f8f1ce")
	)
	hp_changed.emit(self)
	queue_redraw()
	var flash := create_tween()
	flash.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.04)
	flash.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	if hp <= 0.0:
		_die()


func _die() -> void:
	dead = true
	collision.set_deferred("disabled", true)
	hurtbox.set_deferred("monitorable", false)
	died.emit(self)
	var fade := create_tween().set_parallel(true)
	(
		fade
		. tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.34)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_IN)
	)
	fade.tween_property(sprite, "modulate:a", 0.0, 0.28)
	await fade.finished
	queue_free()


func hp_ratio() -> float:
	return clampf(hp / max_hp, 0.0, 1.0)


func _draw() -> void:
	draw_rect(Rect2(-34, -57, 68, 7), Color("14182a"), true)
	draw_rect(Rect2(-32, -55, 64.0 * hp_ratio(), 3), Color("ff5578"), true)
