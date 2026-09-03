class_name CharacterRuntime
extends RefCounted

var data: CharacterData
var hp: float
var energy: float = 0.0
var skill_cooldown_left: float = 0.0


func _init(character_data: CharacterData = null) -> void:
	if character_data:
		setup(character_data)


func setup(character_data: CharacterData) -> void:
	data = character_data
	hp = float(data.max_hp)
	energy = 0.0
	skill_cooldown_left = 0.0


func tick(delta: float) -> void:
	skill_cooldown_left = maxf(0.0, skill_cooldown_left - delta)


func is_alive() -> bool:
	return hp > 0.0


func hp_ratio() -> float:
	if not data:
		return 0.0
	return clampf(hp / float(data.max_hp), 0.0, 1.0)


func energy_ratio() -> float:
	if not data:
		return 0.0
	return clampf(energy / data.ultimate_energy_cost, 0.0, 1.0)


func add_energy(amount: float) -> void:
	if data:
		energy = clampf(energy + amount, 0.0, data.ultimate_energy_cost)


func snapshot() -> Dictionary:
	return {
		"id": String(data.id) if data else "",
		"hp": hp,
		"energy": energy,
		"skill_cooldown_left": skill_cooldown_left,
	}
