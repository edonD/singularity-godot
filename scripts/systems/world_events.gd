extends Node

## World Events — spawns dynamic events triggered by NEXUS Director.
## Supply drops, patrol sweeps, survivor distress, EMP storms, bombardments.

signal event_started(event_type: String, position: Vector2)
signal event_completed(event_type: String)

var _director: Node = null
var _active_events: Array[Dictionary] = []
var _event_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("world_events")
	_connect_director.call_deferred()


func _connect_director() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var nodes := get_tree().get_nodes_in_group("nexus_director")
	if nodes.size() > 0:
		_director = nodes[0]
		_director.nexus_event.connect(_on_nexus_event)


func _on_nexus_event(event_type: String) -> void:
	if _event_cooldown > 0:
		return
	_event_cooldown = 30.0 # Min 30s between events

	if not GameManager.player:
		return

	var player_pos := GameManager.player.global_position
	var event_pos := player_pos + Vector2(randf_range(-200, 200), randf_range(-200, 200))

	match event_type:
		"supply_drop":
			_spawn_supply_drop(event_pos)
		"patrol_sweep":
			_spawn_patrol_sweep(player_pos)
		"survivor_distress":
			_spawn_distress_event(event_pos)
		"emp_storm":
			_trigger_emp_storm()
		"bombardment_warning":
			_spawn_bombardment_warning(player_pos)

	event_started.emit(event_type, event_pos)
	_show_event_notification(event_type)


func _process(delta: float) -> void:
	if _event_cooldown > 0:
		_event_cooldown -= delta

	# Update timed events
	var to_remove: Array[int] = []
	for i in _active_events.size():
		_active_events[i].timer -= delta
		if _active_events[i].timer <= 0:
			to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		if idx < _active_events.size():
			event_completed.emit(_active_events[idx].type)
			_active_events.remove_at(idx)


func _spawn_supply_drop(pos: Vector2) -> void:
	## Supply crate falls from the sky with good loot.
	var ItemDropScene := preload("res://scenes/items/ItemDrop.tscn")
	var items: Array[Array] = [
		["bandage", 3, Color(0.9, 0.9, 0.9)],
		["canned_food", 2, Color(0.6, 0.5, 0.3)],
		["water_bottle", 2, Color(0.3, 0.5, 0.8)],
		["circuit_board", 2, Color(0.2, 0.6, 0.3)],
		["battery", 1, Color(0.7, 0.7, 0.2)],
		["arrow", 10, Color(0.5, 0.4, 0.3)],
	]

	for item_data in items:
		var drop: Area2D = ItemDropScene.instantiate()
		drop.global_position = pos + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		drop.call_deferred("setup", item_data[0], int(item_data[1]), item_data[2])
		GameManager.player.get_parent().call_deferred("add_child", drop)

	# Visual: flash at drop point
	CameraManager.shake(3.0)
	AudioManager.play_sfx("pickup")

	_active_events.append({"type": "supply_drop", "timer": 120.0})


func _spawn_patrol_sweep(player_pos: Vector2) -> void:
	## Spawn extra enemies converging on player's area.
	var enemy_scenes: Array[String] = [
		"res://scenes/enemies/ScoutDrone.tscn",
		"res://scenes/enemies/PatrolBot.tscn",
	]

	var count: int = 3 + (_director.threat_level if _director else 1)
	for i in count:
		var scene_path: String = enemy_scenes[randi() % enemy_scenes.size()]
		var scene := load(scene_path)
		if scene:
			var enemy: CharacterBody2D = scene.instantiate()
			var angle := randf() * TAU
			var dist := randf_range(200, 350)
			enemy.global_position = player_pos + Vector2(cos(angle), sin(angle)) * dist
			GameManager.player.get_parent().call_deferred("add_child", enemy)

	AudioManager.play_sfx("alert")
	CameraManager.shake(4.0)

	_active_events.append({"type": "patrol_sweep", "timer": 60.0})


func _spawn_distress_event(pos: Vector2) -> void:
	## A timed rescue — NPC spawns under threat, player must reach them.
	var NPCScene := preload("res://scenes/world/NPC.tscn")
	var npc: Area2D = NPCScene.instantiate()
	npc.global_position = pos
	npc.npc_name = "Distressed Survivor"
	GameManager.player.get_parent().call_deferred("add_child", npc)

	# Spawn enemies near the NPC
	var EnemyScene := load("res://scenes/enemies/ScoutDrone.tscn")
	for i in 3:
		if EnemyScene:
			var enemy: CharacterBody2D = EnemyScene.instantiate()
			enemy.global_position = pos + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			GameManager.player.get_parent().call_deferred("add_child", enemy)

	_active_events.append({"type": "survivor_distress", "timer": 90.0})


func _trigger_emp_storm() -> void:
	## Temporary EMP effect — stuns all enemies briefly.
	CameraManager.shake(8.0)
	AudioManager.play_sfx("shoot")

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is CharacterBody2D:
			enemy.velocity = Vector2.ZERO
			var tween := create_tween()
			tween.tween_property(enemy, "modulate", Color(0.3, 0.3, 1.0), 0.2)
			tween.tween_interval(5.0)
			tween.tween_property(enemy, "modulate", Color.WHITE, 0.5)

	_active_events.append({"type": "emp_storm", "timer": 5.0})


func _spawn_bombardment_warning(player_pos: Vector2) -> void:
	## Warning: NEXUS incoming bombardment. Must move!
	AudioManager.play_sfx("alert")

	# Create danger zone markers
	for i in 5:
		var marker := Node2D.new()
		marker.global_position = player_pos + Vector2(randf_range(-60, 60), randf_range(-60, 60))
		marker.add_to_group("bombardment_markers")

		var tween := marker.create_tween()
		tween.tween_interval(8.0) # Warning period
		tween.tween_callback(func() -> void:
			# Damage anything at marker position
			if GameManager.player:
				var dist := marker.global_position.distance_to(GameManager.player.global_position)
				if dist < 40:
					GameManager.player.take_damage(30, (GameManager.player.global_position - marker.global_position).normalized())
			CameraManager.shake(10.0)
			AudioManager.play_sfx("critical")
			marker.queue_free()
		)
		GameManager.player.get_parent().call_deferred("add_child", marker)

	_active_events.append({"type": "bombardment_warning", "timer": 10.0})


func _show_event_notification(event_type: String) -> void:
	var messages := {
		"supply_drop": "SUPPLY DROP INCOMING — Check your area!",
		"patrol_sweep": "NEXUS PATROL SWEEP — Enemies inbound!",
		"survivor_distress": "DISTRESS SIGNAL — A survivor needs help!",
		"emp_storm": "EMP STORM — All machines temporarily disabled!",
		"bombardment_warning": "BOMBARDMENT WARNING — MOVE! You have 8 seconds!",
	}

	var text: String = messages.get(event_type, "EVENT: " + event_type)

	var popup := CanvasLayer.new()
	popup.layer = 26

	var label := Label.new()
	label.text = text
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.position = Vector2(-150, 30)
	label.custom_minimum_size = Vector2(300, 20)
	label.add_theme_font_size_override("font_size", 9)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Color based on urgency
	match event_type:
		"bombardment_warning":
			label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		"patrol_sweep":
			label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
		"supply_drop":
			label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
		"emp_storm":
			label.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
		_:
			label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))

	popup.add_child(label)
	get_tree().root.add_child(popup)

	var tween := get_tree().create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(popup.queue_free)
