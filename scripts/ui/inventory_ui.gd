extends CanvasLayer

## Inventory screen — grid display with crafting panel. Toggle with I key.

var _panel: Control
var _is_open: bool = false
var _grid: GridContainer
var _craft_list: VBoxContainer
var _info_label: Label

var inventory: Node
var crafting: Node


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle()


func toggle() -> void:
	_is_open = not _is_open
	_panel.visible = _is_open
	if _is_open:
		get_tree().paused = true
		_refresh()
	else:
		get_tree().paused = false


func _build_ui() -> void:
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	# Background overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(overlay)

	# Main panel
	var main_panel := PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.custom_minimum_size = Vector2(380, 220)
	main_panel.position = Vector2(-190, -110)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = Color(0.3, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	main_panel.add_theme_stylebox_override("panel", style)
	_panel.add_child(main_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(hbox)

	# Left - inventory grid
	var inv_vbox := VBoxContainer.new()
	inv_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(inv_vbox)

	var inv_title := Label.new()
	inv_title.text = "INVENTORY"
	inv_title.add_theme_font_size_override("font_size", 10)
	inv_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	inv_vbox.add_child(inv_title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(200, 180)
	inv_vbox.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	scroll.add_child(_grid)

	# Separator
	var sep := VSeparator.new()
	hbox.add_child(sep)

	# Right - crafting
	var craft_vbox := VBoxContainer.new()
	craft_vbox.add_theme_constant_override("separation", 4)
	craft_vbox.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(craft_vbox)

	var craft_title := Label.new()
	craft_title.text = "CRAFTING"
	craft_title.add_theme_font_size_override("font_size", 10)
	craft_title.add_theme_color_override("font_color", Color(0.6, 0.85, 0.9))
	craft_vbox.add_child(craft_title)

	var craft_scroll := ScrollContainer.new()
	craft_scroll.custom_minimum_size = Vector2(140, 150)
	craft_vbox.add_child(craft_scroll)

	_craft_list = VBoxContainer.new()
	_craft_list.add_theme_constant_override("separation", 2)
	craft_scroll.add_child(_craft_list)

	# Info label at bottom
	_info_label = Label.new()
	_info_label.text = ""
	_info_label.add_theme_font_size_override("font_size", 8)
	_info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	craft_vbox.add_child(_info_label)


func _refresh() -> void:
	if not inventory:
		return

	# Clear grid
	for child in _grid.get_children():
		child.queue_free()

	# Populate inventory slots
	for i in inventory.MAX_SLOTS:
		var slot_btn := _create_slot_button(i)
		_grid.add_child(slot_btn)

	# Clear crafting list
	for child in _craft_list.get_children():
		child.queue_free()

	# Populate crafting recipes
	if crafting:
		for recipe_id: String in crafting.recipes:
			var recipe: Dictionary = crafting.recipes[recipe_id]
			var can: bool = crafting.can_craft(recipe_id)
			var btn := Button.new()
			btn.text = recipe.get("name", recipe_id)
			btn.add_theme_font_size_override("font_size", 8)
			btn.disabled = not can
			btn.modulate = Color.WHITE if can else Color(0.5, 0.5, 0.5)
			var rid := recipe_id # capture
			btn.pressed.connect(func() -> void:
				crafting.craft(rid)
				_refresh()
			)
			_craft_list.add_child(btn)


func _create_slot_button(idx: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(36, 36)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.16)
	style.border_color = Color(0.25, 0.25, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	btn.add_theme_stylebox_override("normal", style)

	var slot: Dictionary = inventory.slots[idx]
	if not slot.is_empty():
		var data: Dictionary = inventory.get_item_data(slot.id)
		btn.text = str(slot.amount)
		btn.add_theme_font_size_override("font_size", 7)

		# Color the button based on item
		var item_style := style.duplicate()
		item_style.bg_color = data.get("color", Color(0.3, 0.3, 0.3)).darkened(0.5)
		btn.add_theme_stylebox_override("normal", item_style)

		btn.tooltip_text = data.get("name", slot.id) + "\n" + data.get("desc", "")

		# Click to use consumables
		var slot_idx := idx
		btn.pressed.connect(func() -> void:
			inventory.use_item(slot_idx)
			_refresh()
		)

	return btn
