extends CanvasLayer

## Quest Journal UI — shows active/completed quests, objectives, and lore.
## Press J to toggle.

var _panel: Control
var _is_open: bool = false
var _journal: Node = null
var _tab: String = "quests" # "quests" or "lore"
var _content_vbox: VBoxContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_J:
			_toggle()
			get_viewport().set_input_as_handled()


func _toggle() -> void:
	_is_open = not _is_open
	_panel.visible = _is_open
	if _is_open:
		_find_journal()
		_refresh()
		get_tree().paused = true
	else:
		get_tree().paused = false


func _find_journal() -> void:
	if _journal:
		return
	var nodes := get_tree().get_nodes_in_group("quest_journal")
	if nodes.size() > 0:
		_journal = nodes[0]


func _build_ui() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0.02, 0.75)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_child(overlay)

	var main := PanelContainer.new()
	main.set_anchors_preset(Control.PRESET_CENTER)
	main.custom_minimum_size = Vector2(380, 220)
	main.position = Vector2(-190, -110)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.06, 0.95)
	style.border_color = Color(0.5, 0.4, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	main.add_theme_stylebox_override("panel", style)
	_panel.add_child(main)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	main.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "JOURNAL"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	# Tab buttons
	var quest_btn := Button.new()
	quest_btn.text = "Quests"
	quest_btn.add_theme_font_size_override("font_size", 8)
	quest_btn.pressed.connect(func() -> void: _tab = "quests"; _refresh())
	header.add_child(quest_btn)

	var lore_btn := Button.new()
	lore_btn.text = "Lore"
	lore_btn.add_theme_font_size_override("font_size", 8)
	lore_btn.pressed.connect(func() -> void: _tab = "lore"; _refresh())
	header.add_child(lore_btn)

	var close := Label.new()
	close.text = "[J] Close"
	close.add_theme_font_size_override("font_size", 7)
	close.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header.add_child(close)

	# Scrollable content
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(360, 170)
	vbox.add_child(scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(_content_vbox)


func _refresh() -> void:
	_find_journal()
	for child in _content_vbox.get_children():
		child.queue_free()

	if not _journal:
		return

	if _tab == "quests":
		_show_quests()
	else:
		_show_lore()


func _show_quests() -> void:
	# Active quests first
	if _journal.active_quests.size() > 0:
		var active_header := Label.new()
		active_header.text = "— ACTIVE —"
		active_header.add_theme_font_size_override("font_size", 8)
		active_header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4))
		active_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content_vbox.add_child(active_header)

		for qid: String in _journal.active_quests:
			var quest: Dictionary = _journal.active_quests[qid]
			_add_quest_entry(quest, false)

	# Completed quests
	if _journal.completed_quests.size() > 0:
		var comp_header := Label.new()
		comp_header.text = "— COMPLETED —"
		comp_header.add_theme_font_size_override("font_size", 8)
		comp_header.add_theme_color_override("font_color", Color(0.4, 0.6, 0.4))
		comp_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content_vbox.add_child(comp_header)

		for qid: String in _journal.completed_quests:
			if _journal.quest_db.has(qid):
				var quest: Dictionary = _journal.quest_db[qid]
				_add_quest_entry(quest, true)

	if _journal.active_quests.is_empty() and _journal.completed_quests.is_empty():
		var empty := Label.new()
		empty.text = "No quests yet. Explore the world."
		empty.add_theme_font_size_override("font_size", 7)
		empty.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		_content_vbox.add_child(empty)


func _add_quest_entry(quest: Dictionary, completed: bool) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.09)
	style.border_color = Color(0.3, 0.3, 0.35) if not completed else Color(0.2, 0.4, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	_content_vbox.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	panel.add_child(vbox)

	# Title + category
	var cat_str := "[Main]" if quest.get("category", "side") == "main" else "[Side]"
	var title := Label.new()
	title.text = "%s %s" % [cat_str, quest.title]
	title.add_theme_font_size_override("font_size", 8)
	var title_color := Color(0.4, 0.6, 0.4) if completed else Color(0.8, 0.8, 0.7)
	title.add_theme_color_override("font_color", title_color)
	vbox.add_child(title)

	# Description
	var desc := Label.new()
	desc.text = quest.desc
	desc.add_theme_font_size_override("font_size", 6)
	desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	# Objectives
	if not completed and quest.has("objectives"):
		for i in quest.objectives.size():
			var obj_done: bool = quest.get("obj_completed", [])[i] if i < quest.get("obj_completed", []).size() else false
			var obj := Label.new()
			var marker := "[x]" if obj_done else "[ ]"
			obj.text = "  %s %s" % [marker, quest.objectives[i]]
			obj.add_theme_font_size_override("font_size", 6)
			obj.add_theme_color_override("font_color", Color(0.3, 0.6, 0.3) if obj_done else Color(0.6, 0.6, 0.5))
			vbox.add_child(obj)


func _show_lore() -> void:
	if _journal.discovered_lore.is_empty():
		var empty := Label.new()
		empty.text = "No lore discovered yet. Search terminals and explore."
		empty.add_theme_font_size_override("font_size", 7)
		empty.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		_content_vbox.add_child(empty)
		return

	for entry in _journal.discovered_lore:
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.06, 0.09)
		style.border_color = Color(0.3, 0.3, 0.5)
		style.set_border_width_all(1)
		style.set_corner_radius_all(2)
		style.set_content_margin_all(6)
		panel.add_theme_stylebox_override("panel", style)
		_content_vbox.add_child(panel)

		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 1)
		panel.add_child(vbox)

		var title := Label.new()
		title.text = entry.title + " (Day %d)" % entry.day
		title.add_theme_font_size_override("font_size", 8)
		title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
		vbox.add_child(title)

		var text := Label.new()
		text.text = entry.text
		text.add_theme_font_size_override("font_size", 6)
		text.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		text.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(text)
