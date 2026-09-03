extends Node2D

const PLAYER_DATA: Array[CharacterData] = [
	preload("res://data/characters/ember.tres"),
	preload("res://data/characters/volt.tres"),
	preload("res://data/characters/tide.tres"),
	preload("res://data/characters/terra.tres"),
]
const ENEMY_SCENE := preload("res://scenes/enemy_dummy.tscn")
const TURRET_SCENE := preload("res://scenes/field_turret.tscn")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const RING_SCENE := preload("res://scenes/visual_ring.tscn")
const COMBAT_TEXT_SCENE := preload("res://scenes/combat_text.tscn")

var spawn_points := [Vector2(510, -250), Vector2(525, 270), Vector2(-555, 285), Vector2(570, 30)]
var spawn_cursor: int = 0

@onready var player: PlayerCharacter = $PlayerCharacter
@onready var party: PartyManager = $PartyManager
@onready var enemies: Node2D = $Enemies
@onready var effects: Node2D = $Effects
@onready var hud: CombatHUD = $HUD


func _ready() -> void:
	party.party_data = PLAYER_DATA
	party.initialize(player)
	player.skill_requested.connect(_on_skill_requested)
	player.ultimate_requested.connect(_on_ultimate_requested)
	player.combat_text_requested.connect(_spawn_combat_text)
	player.defeated.connect(party.handle_active_defeated)
	player.defeated.connect(_on_player_defeated)
	hud.bind_party(party)
	hud.populate_party_cards()
	_spawn_enemy(spawn_points[0])
	_spawn_enemy(spawn_points[1])
	hud.show_notification("SIMULATION ONLINE", Color("73e9ff"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _spawn_enemy(at_position: Vector2) -> void:
	var enemy := ENEMY_SCENE.instantiate() as EnemyDummy
	enemies.add_child(enemy)
	enemy.global_position = at_position
	enemy.variant = spawn_cursor
	enemy.max_hp = 260.0 + minf(hud.kills * 8.0, 160.0)
	enemy.hp = enemy.max_hp
	enemy.attack_damage = 18.0 + minf(hud.kills * 0.5, 10.0)
	enemy.died.connect(_on_enemy_died)
	enemy.combat_text_requested.connect(_spawn_combat_text)
	hud.set_enemy_count(_living_enemy_count())


func _on_enemy_died(_enemy: EnemyDummy) -> void:
	hud.register_kill()
	hud.set_enemy_count(_living_enemy_count())
	hud.show_notification("TARGET ERASED", Color("ff7791"))
	await get_tree().create_timer(2.2).timeout
	spawn_cursor = (spawn_cursor + 1) % spawn_points.size()
	_spawn_enemy(spawn_points[spawn_cursor])


func _living_enemy_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.dead:
			count += 1
	return count


func _on_skill_requested(
	_character: PlayerCharacter, data: CharacterData, origin: Vector2, direction: Vector2
) -> void:
	hud.show_notification(data.skill_name.to_upper(), data.accent_color)
	match data.skill_kind:
		"turret":
			var turret := TURRET_SCENE.instantiate() as FieldTurret
			effects.add_child(turret)
			turret.global_position = origin + direction * 44.0
			turret.setup(data)
			_spawn_ring(turret.global_position, data.accent_color, 62.0, 0.30)
		"projectile":
			var projectile := PROJECTILE_SCENE.instantiate() as SkillProjectile
			effects.add_child(projectile)
			projectile.global_position = origin + direction * 42.0
			projectile.setup(data, direction)
			_spawn_ring(origin, data.accent_color, 58.0, 0.22)
		"heal_wave":
			player.heal(data.max_hp * 0.32)
			_damage_enemies(origin, 135.0, data.attack * 0.85, data)
			_spawn_ring(origin, data.accent_color, 135.0, 0.52, 7.0)
		"quake":
			_damage_enemies(origin, 165.0, data.attack * 1.55, data)
			_spawn_ring(origin, data.accent_color, 165.0, 0.38, 9.0)
			_spawn_ring(origin, Color.WHITE, 105.0, 0.28, 3.0)


func _on_ultimate_requested(
	_character: PlayerCharacter, data: CharacterData, origin: Vector2
) -> void:
	hud.show_notification("BURST // %s" % data.ultimate_name.to_upper(), data.accent_color)
	_damage_enemies(origin, 250.0, data.attack * 2.8, data)
	_spawn_ring(origin, data.primary_color, 250.0, 0.72, 12.0)
	_spawn_ring(origin, data.accent_color, 190.0, 0.52, 7.0)
	_spawn_ring(origin, Color.WHITE, 115.0, 0.34, 3.0)


func _damage_enemies(origin: Vector2, radius: float, damage: float, data: CharacterData) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		if origin.distance_to(enemy.global_position) <= radius:
			var direction := origin.direction_to(enemy.global_position)
			if direction == Vector2.ZERO:
				direction = Vector2.DOWN
			enemy.take_damage(damage, direction, String(data.element), data.display_name)


func _spawn_ring(
	origin: Vector2, color: Color, radius: float, duration: float, width: float = 5.0
) -> void:
	var ring := RING_SCENE.instantiate() as VisualRing
	effects.add_child(ring)
	ring.global_position = origin
	ring.setup(color, radius, duration, width)


func _spawn_combat_text(value: String, origin: Vector2, color: Color) -> void:
	var text_label := COMBAT_TEXT_SCENE.instantiate() as CombatText
	effects.add_child(text_label)
	text_label.global_position = origin
	text_label.setup(value, color)


func _on_player_defeated() -> void:
	await get_tree().process_frame
	if party.all_defeated():
		hud.show_notification("PARTY DOWN // PRESS R", Color("ff4e70"))
