class_name PlayerCharacter
extends CharacterBody2D

signal health_changed
signal energy_changed
signal skill_requested(
	character: PlayerCharacter, data: CharacterData, origin: Vector2, direction: Vector2
)
signal ultimate_requested(character: PlayerCharacter, data: CharacterData, origin: Vector2)
signal combat_text_requested(text: String, world_position: Vector2, color: Color)
signal defeated

var runtime: CharacterRuntime
var facing: Vector2 = Vector2.DOWN
var action_locked: bool = false
var invulnerable_left: float = 0.0
var hit_targets: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D
@onready var aura: Polygon2D = $Aura
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	add_to_group("player")
	attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	attack_hitbox.monitoring = false


func load_runtime(new_runtime: CharacterRuntime) -> void:
	runtime = new_runtime
	sprite.texture = runtime.data.world_sprite
	sprite.modulate = Color.WHITE
	aura.color = Color(runtime.data.accent_color, 0.24)
	invulnerable_left = 0.25
	action_locked = false
	attack_hitbox.monitoring = false
	var arrival := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	arrival.tween_property(sprite, "scale", Vector2(0.58, 0.58), 0.18).from(Vector2(0.18, 0.18))
	health_changed.emit()
	energy_changed.emit()


func _physics_process(delta: float) -> void:
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	if not runtime or not runtime.is_alive():
		velocity = Vector2.ZERO
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector.length_squared() > 0.01:
		facing = input_vector.normalized()
		sprite.flip_h = facing.x < -0.05
	velocity = input_vector * runtime.data.move_speed
	if action_locked:
		velocity *= 0.28
	move_and_slide()

	var target_rotation := (
		0.035 * sin(Time.get_ticks_msec() * 0.012) if input_vector.length_squared() > 0.01 else 0.0
	)
	sprite.rotation = lerpf(sprite.rotation, target_rotation, delta * 12.0)


func _unhandled_input(event: InputEvent) -> void:
	if not runtime or not runtime.is_alive():
		return
	if event.is_action_pressed("attack"):
		perform_basic_attack()
	elif event.is_action_pressed("skill"):
		perform_skill()
	elif event.is_action_pressed("ultimate"):
		perform_ultimate()


func perform_basic_attack() -> void:
	if action_locked:
		return
	action_locked = true
	hit_targets.clear()
	attack_hitbox.position = facing * 48.0
	attack_hitbox.monitoring = true

	var slash := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	slash.tween_property(
		sprite, "rotation", signf(facing.x if absf(facing.x) > 0.01 else 1.0) * 0.24, 0.08
	)
	slash.parallel().tween_property(sprite, "scale", Vector2(0.66, 0.52), 0.08)
	slash.tween_property(sprite, "rotation", 0.0, 0.14)
	slash.parallel().tween_property(sprite, "scale", Vector2(0.58, 0.58), 0.14)

	await get_tree().create_timer(0.12).timeout
	attack_hitbox.monitoring = false
	await get_tree().create_timer(0.13).timeout
	action_locked = false


func perform_skill() -> void:
	if action_locked:
		return
	if runtime.skill_cooldown_left > 0.0:
		combat_text_requested.emit(
			"COOLDOWN %.1fs" % runtime.skill_cooldown_left,
			global_position - Vector2(0, 58),
			runtime.data.accent_color
		)
		return
	action_locked = true
	runtime.skill_cooldown_left = runtime.data.skill_cooldown
	runtime.add_energy(22.0)
	skill_requested.emit(self, runtime.data, global_position, facing)
	energy_changed.emit()
	var cast := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cast.tween_property(sprite, "scale", Vector2(0.76, 0.76), 0.10)
	cast.tween_property(sprite, "scale", Vector2(0.58, 0.58), 0.20)
	await get_tree().create_timer(0.28).timeout
	action_locked = false


func perform_ultimate() -> void:
	if action_locked:
		return
	if runtime.energy < runtime.data.ultimate_energy_cost:
		combat_text_requested.emit("NEED ENERGY", global_position - Vector2(0, 58), Color("8ea1c9"))
		return
	action_locked = true
	runtime.energy = 0.0
	ultimate_requested.emit(self, runtime.data, global_position)
	energy_changed.emit()
	var burst := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	burst.tween_property(sprite, "scale", Vector2(0.92, 0.92), 0.12)
	burst.tween_property(sprite, "scale", Vector2(0.58, 0.58), 0.42)
	await get_tree().create_timer(0.48).timeout
	action_locked = false


func take_damage(raw_damage: float) -> void:
	if not runtime or not runtime.is_alive() or invulnerable_left > 0.0:
		return
	var mitigated := maxf(1.0, raw_damage * 100.0 / (100.0 + runtime.data.defense))
	runtime.hp = maxf(0.0, runtime.hp - mitigated)
	health_changed.emit()
	combat_text_requested.emit(
		"-%d" % roundi(mitigated), global_position - Vector2(0, 54), Color("ff6b7d")
	)
	invulnerable_left = 0.35
	var flash := create_tween()
	flash.tween_property(sprite, "modulate", Color("ff718b"), 0.04)
	flash.tween_property(sprite, "modulate", Color.WHITE, 0.16)
	if runtime.hp <= 0.0:
		action_locked = true
		defeated.emit()


func heal(amount: float) -> void:
	if not runtime or not runtime.is_alive():
		return
	var actual := minf(amount, float(runtime.data.max_hp) - runtime.hp)
	runtime.hp += actual
	health_changed.emit()
	combat_text_requested.emit(
		"+%d" % roundi(actual), global_position - Vector2(0, 54), Color("67f6c3")
	)


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if hit_targets.has(area):
		return
	if not area.has_method("receive_hit"):
		return
	hit_targets[area] = true
	var damage := float(runtime.data.attack)
	area.receive_hit(damage, facing, String(runtime.data.element), runtime.data.display_name)
	runtime.add_energy(9.0)
	energy_changed.emit()
