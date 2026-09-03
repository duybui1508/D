extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS  ", message)
	else:
		failures.append(message)
		push_error("FAIL  " + message)


func _run() -> void:
	print("\nD: Rift Protocol — smoke tests\n")
	var resources: Array[CharacterData] = [
		load("res://data/characters/ember.tres"),
		load("res://data/characters/volt.tres"),
		load("res://data/characters/tide.tres"),
		load("res://data/characters/terra.tres"),
	]
	_check(resources.size() == 4, "four CharacterData resources load")
	_check(resources[0].skill_kind == "turret", "Ember owns the persistent turret skill")
	_check(resources[1].move_speed > resources[3].move_speed, "character stats are data-driven")

	var ember_state := CharacterRuntime.new(resources[0])
	ember_state.hp -= 31.0
	ember_state.energy = 44.0
	ember_state.skill_cooldown_left = 5.0
	ember_state.tick(1.25)
	_check(
		is_equal_approx(ember_state.hp, resources[0].max_hp - 31.0), "runtime keeps independent HP"
	)
	_check(is_equal_approx(ember_state.energy, 44.0), "runtime keeps independent energy")
	_check(is_equal_approx(ember_state.skill_cooldown_left, 3.75), "off-field cooldown ticks")

	var main_scene := load("res://scenes/main.tscn") as PackedScene
	_check(main_scene != null, "main scene loads")
	if main_scene:
		var game := main_scene.instantiate()
		root.add_child(game)
		await process_frame
		_check(
			game.get_node_or_null("PlayerCharacter") is PlayerCharacter,
			"generic PlayerCharacter spawns"
		)
		_check(game.get_node_or_null("PartyManager") is PartyManager, "PartyManager spawns")
		var manager := game.get_node("PartyManager") as PartyManager
		_check(manager.states.size() == 4, "party initializes four runtime states")
		var position_before := manager.player.global_position
		var swapped := manager.request_swap(1)
		_check(swapped and manager.active_index == 1, "realtime character swap works")
		_check(manager.player.global_position == position_before, "swap preserves world position")
		game.queue_free()

	if failures.is_empty():
		print("\nALL TESTS PASSED\n")
		quit(0)
	else:
		print("\n%d TEST(S) FAILED\n" % failures.size())
		quit(1)
