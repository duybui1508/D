class_name CharacterData
extends Resource

@export_group("Identity")
@export var id: StringName
@export var display_name: String = "Unit"
@export var title: String = "Rift Walker"
@export var element: StringName = &"neutral"

@export_group("Combat Stats")
@export_range(1, 9999, 1) var max_hp: int = 100
@export_range(1, 999, 1) var attack: int = 20
@export_range(0, 999, 1) var defense: int = 10
@export_range(50.0, 800.0, 5.0) var move_speed: float = 260.0

@export_group("Skill")
@export var skill_name: String = "Pulse"
@export_enum("turret", "projectile", "heal_wave", "quake") var skill_kind: String = "projectile"
@export_range(0.1, 60.0, 0.1) var skill_cooldown: float = 5.0
@export var ultimate_name: String = "Rift Break"
@export_range(1.0, 100.0, 1.0) var ultimate_energy_cost: float = 100.0

@export_group("Presentation")
@export var primary_color: Color = Color.WHITE
@export var accent_color: Color = Color.WHITE
@export var world_sprite: Texture2D
@export var portrait: Texture2D
