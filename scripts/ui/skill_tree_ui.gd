extends CanvasLayer

## Skill Tree UI — visual display of 3 branches with unlockable nodes.
## Press T to toggle. Shows Combat/Stealth/Tech branches.

var _panel: Control
var _is_open: bool = false
var _skill_tree: Node = null
var _branch_tabs: Dictionary = {} # branch_name -> container
var _current_branch: String = "combat"
var _points_label: Label
var _skill_buttons: Dictionary = {} # skill_id -> Button

const BRANCH_COLORS := {
	"combat": Color(0.9, 0.3, 0.2),
	"stealth": Color(0.3, 0.7, 0.3),
	"tech": Color(0.3, 0.5, 0.9),
}

const BRANCH_NAMES := {
	"combat": "COMBAT",
	"stealth": "STEALTH",
	"tech": "TECH",
}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T:
			_toggle()
			get_viewport().set_input_as_handled()


func _toggle() -> void:
	_is_open = not _is_open
	_panel.visible = _is_open
	if _is_open:
		_find_skill_tree()
		_refresh_all()
		get_tree().paused = true
	else:
		get_tree().paused = false


func _find_skill_tree() -> void:
	if _skill_tree:
		return
	var nodes := get_tree().get_nodes_in_group("skill_tree")
	if nodes.size() > 0:
		_skill_tree = nodes[0]


func _build_ui() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	# Dim background
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0.02, 0.75)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(overlay)

	# Main container
	var main_panel := PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.custom_minimum_size = Vector2(420, 230)
	main_panel.position = Vector2(-210, -115)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.95)
	style.border_color = Color(0.3, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	main_panel.add_theme_stylebox_override("panel", style)
	_panel.add_child(main_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	main_panel.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "SKILL TREE"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_points_label = Label.new()
	_points_label.text = "Points: 0"
	_points_label.add_theme_font_size_override("font_size", 10)
	_points_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	header.add_child(_points_label)

	var close_hint := Label.new()
	close_hint.text = "[T] Close"
	close_hint.add_theme_font_size_override("font_size", 7)
	close_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header.add_child(close_hint)

	# Branch tabs
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	vbox.add_child(tab_row)

	for branch: String in ["combat", "stealth", "tech"]:
		var btn := Button.new()
		btn.text = BRANCH_NAMES[branch]
		btn.add_theme_font_size_override("font_size", 9)
		btn.custom_minimum_size = Vector2(60, 16)
		var b := branch
		btn.pressed.connect(func() -> void: _switch_branch(b))
		tab_row.add_child(btn)
		_branch_tabs[branch] = btn

	# Skill content area — a ScrollContainer with a VBox for each branch
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(400, 160)
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "SkillContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 3)
	scroll.add_child(content)


func _switch_branch(branch: String) -> void:
	_current_branch = branch
	_refresh_all()


func _refresh_all() -> void:
	_find_skill_tree()
	if not _skill_tree:
		return

	# Update points
	_points_label.text = "Points: %d" % _skill_tree.skill_points

	# Update tab colors
	for branch: String in _branch_tabs:
		var btn: Button = _branch_tabs[branch]
		if branch == _current_branch:
			btn.modulate = BRANCH_COLORS[branch]
		else:
			btn.modulate = Color(0.5, 0.5, 0.5)

	# Rebuild skill list for current branch
	var content := _panel.get_node("PanelContainer/VBoxContainer/ScrollContainer/SkillContent") as VBoxContainer
	if not content:
		return

	# Clear old
	for child in content.get_children():
		child.queue_free()
	_skill_buttons.clear()

	var branch_skills: Array[String] = _skill_tree.get_branch_skills(_current_branch)

	for sid: String in branch_skills:
		var skill: Dictionary = _skill_tree.skills[sid]
		var is_unlocked: bool = _skill_tree.has_skill(sid)
		var can_unlock: bool = _skill_tree.can_unlock(sid)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		content.add_child(row)

		# Skill icon (colored square)
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(14, 14)
		if is_unlocked:
			icon.color = skill.icon_color
		elif can_unlock:
			icon.color = skill.icon_color * 0.6
		else:
			icon.color = Color(0.2, 0.2, 0.2)
		row.add_child(icon)

		# Skill info
		var info_vbox := VBoxContainer.new()
		info_vbox.add_theme_constant_override("separation", 0)
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_vbox)

		var name_label := Label.new()
		name_label.text = skill.name
		name_label.add_theme_font_size_override("font_size", 8)
		if is_unlocked:
			name_label.add_theme_color_override("font_color", skill.icon_color)
		elif can_unlock:
			name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		else:
			name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		info_vbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = skill.desc
		desc_label.add_theme_font_size_override("font_size", 6)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		info_vbox.add_child(desc_label)

		# Requires label
		if skill.requires.size() > 0 and not is_unlocked:
			var req_names: Array[String] = []
			for req: String in skill.requires:
				if _skill_tree.skills.has(req):
					req_names.append(_skill_tree.skills[req].name)
			var req_label := Label.new()
			req_label.text = "Requires: " + ", ".join(req_names)
			req_label.add_theme_font_size_override("font_size", 5)
			req_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3))
			info_vbox.add_child(req_label)

		# Unlock button or status
		if is_unlocked:
			var status := Label.new()
			status.text = "UNLOCKED"
			status.add_theme_font_size_override("font_size", 7)
			status.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
			row.add_child(status)
		elif can_unlock:
			var btn := Button.new()
			btn.text = "Unlock (%d)" % skill.cost
			btn.add_theme_font_size_override("font_size", 7)
			btn.custom_minimum_size = Vector2(55, 14)
			var s := sid
			btn.pressed.connect(func() -> void: _on_unlock(s))
			row.add_child(btn)
			_skill_buttons[sid] = btn
		else:
			var cost_label := Label.new()
			cost_label.text = "Cost: %d" % skill.cost
			cost_label.add_theme_font_size_override("font_size", 7)
			cost_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			row.add_child(cost_label)


func _on_unlock(skill_id: String) -> void:
	if _skill_tree and _skill_tree.unlock_skill(skill_id):
		_refresh_all()
