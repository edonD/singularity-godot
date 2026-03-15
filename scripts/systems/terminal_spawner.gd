extends Node2D

## Spawns terminals at intervals around the world.

const TerminalScene := preload("res://scenes/world/Terminal.tscn")
const SPAWN_DISTANCE := 200.0
const MAX_TERMINALS := 8

var _spawned: Array[Vector2] = []
var _check_timer: float = 0.0


func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer < 5.0:
		return
	_check_timer = 0.0

	if not GameManager.player or _spawned.size() >= MAX_TERMINALS:
		return

	var player_pos := GameManager.player.global_position

	# Check if any terminal is close enough
	var has_nearby := false
	for pos in _spawned:
		if player_pos.distance_to(pos) < SPAWN_DISTANCE * 1.5:
			has_nearby = true
			break

	if has_nearby:
		return

	# Spawn a terminal at a discoverable distance
	var angle := randf() * TAU
	var dist := randf_range(100.0, SPAWN_DISTANCE)
	var spawn_pos := player_pos + Vector2(cos(angle), sin(angle)) * dist

	var terminal: Area2D = TerminalScene.instantiate()
	terminal.global_position = spawn_pos
	_spawned.append(spawn_pos)
	get_parent().add_child(terminal)
