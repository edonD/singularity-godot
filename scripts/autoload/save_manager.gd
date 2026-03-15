extends Node

## Save/load game state.

const SAVE_PATH := "user://save.dat"


func _ready() -> void:
	add_to_group("save_manager")


func save_game() -> void:
	var data := {
		"player_stats": GameManager.player_stats.duplicate(),
		"day": GameManager.day,
		"time_of_day": GameManager.time_of_day,
		"kills": GameManager.kills,
		"player_pos": _get_player_pos(),
	}

	# Save inventory
	var inv := get_tree().get_first_node_in_group("inventory")
	if inv:
		data["inventory"] = []
		for slot in inv.slots:
			data["inventory"].append(slot.duplicate() if not slot.is_empty() else {})

	# Save missions
	var mm := get_tree().get_first_node_in_group("mission_manager")
	if mm:
		data["completed_missions"] = mm.completed_missions.duplicate()
		data["current_mission_idx"] = mm._current_mission_idx

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
		AudioManager.play_sfx("click")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var data: Dictionary = file.get_var()
	file.close()

	if not data:
		return

	# Restore player stats
	if data.has("player_stats"):
		for key: String in data.player_stats:
			GameManager.player_stats[key] = data.player_stats[key]

	GameManager.day = data.get("day", 1)
	GameManager.time_of_day = data.get("time_of_day", 0.0)
	GameManager.kills = data.get("kills", 0)

	# Restore player position
	if data.has("player_pos") and GameManager.player:
		GameManager.player.global_position = data.player_pos

	# Restore inventory
	if data.has("inventory"):
		var inv := get_tree().get_first_node_in_group("inventory")
		if inv:
			for i in mini(data.inventory.size(), inv.MAX_SLOTS):
				inv.slots[i] = data.inventory[i]
			inv.inventory_changed.emit()

	# Restore missions
	if data.has("completed_missions"):
		var mm := get_tree().get_first_node_in_group("mission_manager")
		if mm:
			mm.completed_missions = data.completed_missions
			mm._current_mission_idx = data.get("current_mission_idx", 0)


func _get_player_pos() -> Vector2:
	if GameManager.player:
		return GameManager.player.global_position
	return Vector2(240, 135)
