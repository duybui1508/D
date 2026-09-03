class_name CombatHUD
extends Control

var party: PartyManager
var active_name: Label
var active_title: Label
var hp_bar: ProgressBar
var hp_value: Label
var energy_bar: ProgressBar
var skill_value: Label
var ultimate_value: Label
var enemy_value: Label
var kill_value: Label
var notification: Label
var party_cards: Array[Dictionary] = []
var notification_tween: Tween
var kills: int = 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_header()
	_build_active_panel()
	_build_party_panel()
	_build_controls()
	_build_notification()


func bind_party(manager: PartyManager) -> void:
	party = manager
	party.character_changed.connect(_on_character_changed)
	party.swap_rejected.connect(
		func(reason: String) -> void: show_notification(reason.to_upper(), Color("ff8ca1"))
	)
	_on_character_changed(party.active_index, party.get_active_state())


func _process(_delta: float) -> void:
	if not party or party.states.is_empty():
		return
	var state := party.get_active_state()
	hp_bar.max_value = state.data.max_hp
	hp_bar.value = state.hp
	hp_value.text = "%d / %d" % [ceili(state.hp), state.data.max_hp]
	energy_bar.max_value = state.data.ultimate_energy_cost
	energy_bar.value = state.energy
	ultimate_value.text = (
		"[Q] %s  %d%%" % [state.data.ultimate_name, roundi(state.energy_ratio() * 100.0)]
	)
	if state.skill_cooldown_left > 0.0:
		skill_value.text = "[E] %s  %.1fs" % [state.data.skill_name, state.skill_cooldown_left]
	else:
		skill_value.text = "[E] %s  READY" % state.data.skill_name

	for index in party.states.size():
		var card := party_cards[index]
		var card_state := party.states[index]
		card.hp.value = card_state.hp_ratio() * 100.0
		card.cooldown.text = (
			"DOWN"
			if not card_state.is_alive()
			else (
				"E %.1f" % card_state.skill_cooldown_left
				if card_state.skill_cooldown_left > 0.0
				else "E READY"
			)
		)
		var border := (
			card_state.data.accent_color if index == party.active_index else Color("344261")
		)
		card.panel.add_theme_stylebox_override(
			"panel",
			_panel_style(
				Color(0.035, 0.05, 0.09, 0.92), border, 3 if index == party.active_index else 1
			)
		)


func set_enemy_count(count: int) -> void:
	enemy_value.text = "%02d HOSTILES" % count


func register_kill() -> void:
	kills += 1
	kill_value.text = "%02d CLEARED" % kills


func show_notification(message: String, color: Color = Color.WHITE) -> void:
	notification.text = message
	notification.modulate = color
	if notification_tween and notification_tween.is_valid():
		notification_tween.kill()
	notification_tween = create_tween()
	notification_tween.tween_property(notification, "modulate:a", 1.0, 0.06).from(0.0)
	notification_tween.tween_interval(1.25)
	notification_tween.tween_property(notification, "modulate:a", 0.0, 0.35)


func _on_character_changed(_index: int, state: CharacterRuntime) -> void:
	if not state:
		return
	active_name.text = state.data.display_name
	active_name.modulate = state.data.accent_color
	active_title.text = state.data.title.to_upper()
	hp_bar.add_theme_stylebox_override("fill", _bar_style(state.data.primary_color))
	energy_bar.add_theme_stylebox_override("fill", _bar_style(state.data.accent_color))
	show_notification("LINKED // %s" % state.data.display_name, state.data.accent_color)


func _build_header() -> void:
	var brand := PanelContainer.new()
	brand.set_anchors_preset(Control.PRESET_TOP_LEFT)
	brand.position = Vector2(24, 22)
	brand.size = Vector2(330, 82)
	brand.add_theme_stylebox_override(
		"panel", _panel_style(Color(0.03, 0.045, 0.085, 0.94), Color("334b7b"), 1)
	)
	add_child(brand)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	brand.add_child(box)
	var logo := _label("D // RIFT PROTOCOL", 24, Color("f4f7ff"))
	box.add_child(logo)
	var objective := _label("OBJECTIVE  ·  CLEAR THE TEST CELL", 12, Color("7189b7"))
	box.add_child(objective)

	var enemy_panel := PanelContainer.new()
	enemy_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	enemy_panel.position = Vector2(-142, 22)
	enemy_panel.size = Vector2(284, 58)
	enemy_panel.add_theme_stylebox_override(
		"panel", _panel_style(Color(0.05, 0.035, 0.075, 0.95), Color("733755"), 1)
	)
	add_child(enemy_panel)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	enemy_panel.add_child(row)
	enemy_value = _label("00 HOSTILES", 14, Color("ff718d"))
	kill_value = _label("00 CLEARED", 14, Color("8da1c8"))
	row.add_child(enemy_value)
	row.add_child(kill_value)


func _build_active_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-235, -132)
	panel.size = Vector2(470, 110)
	panel.add_theme_stylebox_override(
		"panel", _panel_style(Color(0.025, 0.04, 0.075, 0.96), Color("435985"), 2)
	)
	add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	panel.add_child(root)
	var title_row := HBoxContainer.new()
	root.add_child(title_row)
	active_name = _label("EMBER", 23, Color.WHITE)
	active_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_title = _label("ASH VANGUARD", 11, Color("8292b5"))
	active_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(active_name)
	title_row.add_child(active_title)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 10)
	root.add_child(hp_row)
	hp_bar = _progress_bar(Color("ff5a70"), 100.0)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_value = _label("100 / 100", 11, Color("d7dff2"))
	hp_value.custom_minimum_size.x = 76
	hp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_row.add_child(hp_bar)
	hp_row.add_child(hp_value)

	energy_bar = _progress_bar(Color("72e3ff"), 100.0)
	energy_bar.custom_minimum_size.y = 8
	root.add_child(energy_bar)
	var action_row := HBoxContainer.new()
	root.add_child(action_row)
	skill_value = _label("[E] SKILL READY", 12, Color("f1f4ff"))
	skill_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ultimate_value = _label("[Q] ULTIMATE 0%", 12, Color("9aabd0"))
	action_row.add_child(skill_value)
	action_row.add_child(ultimate_value)


func _build_party_panel() -> void:
	var stack := VBoxContainer.new()
	stack.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	stack.position = Vector2(-218, -196)
	stack.size = Vector2(194, 392)
	stack.add_theme_constant_override("separation", 8)
	add_child(stack)
	for index in 4:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(194, 86)
		panel.add_theme_stylebox_override(
			"panel", _panel_style(Color(0.03, 0.045, 0.08, 0.94), Color("344261"), 1)
		)
		stack.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 9)
		panel.add_child(row)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(58, 58)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(portrait)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		row.add_child(info)
		var name_label := _label("UNIT", 14, Color.WHITE)
		var cooldown := _label("E READY", 10, Color("8fa3c9"))
		var hp := _progress_bar(Color("6fe0b0"), 100.0)
		hp.custom_minimum_size.y = 6
		info.add_child(name_label)
		info.add_child(cooldown)
		info.add_child(hp)
		var key := _label("[%d]" % (index + 1), 12, Color("8297c1"))
		row.add_child(key)
		party_cards.append(
			{
				"panel": panel,
				"portrait": portrait,
				"name": name_label,
				"cooldown": cooldown,
				"hp": hp
			}
		)


func populate_party_cards() -> void:
	if not party:
		return
	for index in mini(party.states.size(), party_cards.size()):
		var state := party.states[index]
		party_cards[index].portrait.texture = state.data.portrait
		party_cards[index].name.text = state.data.display_name
		party_cards[index].name.modulate = state.data.accent_color
		party_cards[index].hp.add_theme_stylebox_override(
			"fill", _bar_style(state.data.primary_color)
		)


func _build_controls() -> void:
	var controls := PanelContainer.new()
	controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(24, -112)
	controls.size = Vector2(260, 90)
	controls.add_theme_stylebox_override(
		"panel", _panel_style(Color(0.025, 0.04, 0.075, 0.86), Color("2d3c5e"), 1)
	)
	add_child(controls)
	var label := _label(
		"WASD  MOVE       LMB  ATTACK\nE  SKILL          Q  ULTIMATE\n1—4  SWAP         R  RESTART",
		12,
		Color("aab7d2")
	)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls.add_child(label)


func _build_notification() -> void:
	notification = _label("LINKED", 17, Color.WHITE)
	notification.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification.position = Vector2(-210, 96)
	notification.size = Vector2(420, 32)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.modulate.a = 0.0
	add_child(notification)


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.01, 0.02, 0.05, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _progress_bar(color: Color, maximum: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = maximum
	bar.value = maximum
	bar.show_percentage = false
	bar.custom_minimum_size.y = 11
	bar.add_theme_stylebox_override("background", _bar_style(Color("17213a")))
	bar.add_theme_stylebox_override("fill", _bar_style(color))
	return bar


func _panel_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style
