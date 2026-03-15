extends Node2D

## Spawns enemies around the player. More at night, harder over time.

const ScoutDroneScene := preload("res://scenes/enemies/ScoutDrone.tscn")
const PatrolBotScene := preload("res://scenes/enemies/PatrolBot.tscn")
const HarvesterScene := preload("res://scenes/enemies/Harvester.tscn")

const MAX_ENEMIES := 30
const SPAWN_INTERVAL := 3.0
const MIN_SPAWN_DIST := 180.0
const MAX_SPAWN_DIST := 300.0

var _spawn_timer: float = 0.0
var _enemy_count: int = 0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	_spawn_timer += delta
	_enemy_count = get_tree().get_nodes_in_group("enemies").size()

	if _spawn_timer >= SPAWN_INTERVAL and _enemy_count < MAX_ENEMIES:
		_spawn_timer = 0.0
		_spawn_enemy()


func _spawn_enemy() -> void:
	if not GameManager.player:
		return

	var player_pos := GameManager.player.global_position

	# Pick random spawn position away from player
	var angle := randf() * TAU
	var dist := randf_range(MIN_SPAWN_DIST, MAX_SPAWN_DIST)
	var spawn_pos := player_pos + Vector2(cos(angle), sin(angle)) * dist

	# Pick enemy type based on day/difficulty
	var day := GameManager.day
	var roll := randf()
	var enemy: Node2D

	if roll < 0.5:
		enemy = ScoutDroneScene.instantiate()
	elif roll < 0.8 or day < 3:
		enemy = PatrolBotScene.instantiate()
	else:
		enemy = HarvesterScene.instantiate()

	enemy.global_position = spawn_pos

	# Scale difficulty with day
	if enemy.is_in_group("enemies") or enemy.has_method("take_damage"):
		pass # Group added in _ready
	var scale_factor := 1.0 + (day - 1) * 0.15
	enemy.set("max_hp", int(enemy.get("max_hp") * scale_factor) if enemy.get("max_hp") else 30)
	enemy.set("attack_damage", int(enemy.get("attack_damage") * scale_factor) if enemy.get("attack_damage") else 8)
	enemy.set("xp_value", int(enemy.get("xp_value") * scale_factor) if enemy.get("xp_value") else 10)

	# Night spawns are more aggressive
	if GameManager.is_night:
		var det: float = enemy.get("detection_range") if enemy.get("detection_range") else 100.0
		enemy.set("detection_range", det * 1.5)

	get_parent().add_child(enemy)
