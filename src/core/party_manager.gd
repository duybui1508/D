class_name PartyManager
extends Node

signal character_changed(index: int, runtime: CharacterRuntime)
signal party_updated
signal swap_rejected(reason: String)

@export var party_data: Array[CharacterData] = []

var states: Array[CharacterRuntime] = []
var active_index: int = 0
var player: PlayerCharacter
var swap_cooldown_left: float = 0.0


func initialize(player_character: PlayerCharacter) -> void:
	player = player_character
	states.clear()
	for character_data in party_data:
		states.append(CharacterRuntime.new(character_data))
	assert(not states.is_empty(), "PartyManager needs at least one CharacterData resource.")
	active_index = 0
	player.load_runtime(states[active_index])
	character_changed.emit(active_index, states[active_index])
	party_updated.emit()


func _process(delta: float) -> void:
	for state in states:
		state.tick(delta)
	swap_cooldown_left = maxf(0.0, swap_cooldown_left - delta)

	for index in states.size():
		if Input.is_action_just_pressed("swap_%d" % (index + 1)):
			request_swap(index)


func request_swap(index: int) -> bool:
	if index < 0 or index >= states.size():
		return false
	if index == active_index:
		return false
	if not states[index].is_alive():
		swap_rejected.emit("%s is down" % states[index].data.display_name)
		return false
	if swap_cooldown_left > 0.0 or (player and player.action_locked):
		swap_rejected.emit("Swap locked")
		return false

	active_index = index
	swap_cooldown_left = 0.35
	player.load_runtime(states[active_index])
	character_changed.emit(active_index, states[active_index])
	party_updated.emit()
	return true


func handle_active_defeated() -> void:
	for offset in range(1, states.size() + 1):
		var candidate := (active_index + offset) % states.size()
		if states[candidate].is_alive():
			player.action_locked = false
			swap_cooldown_left = 0.0
			request_swap(candidate)
			return
	party_updated.emit()


func all_defeated() -> bool:
	for state in states:
		if state.is_alive():
			return false
	return true


func get_active_state() -> CharacterRuntime:
	if states.is_empty():
		return null
	return states[active_index]
