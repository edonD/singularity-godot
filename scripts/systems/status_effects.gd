extends Node

## Status effects system — applied to player or enemies.

signal effect_applied(target: Node2D, effect_name: String)
signal effect_removed(target: Node2D, effect_name: String)

# Active effects: {node_id: {effect_name: {duration, tick_timer, ...}}}
var _active_effects: Dictionary = {}


func _ready() -> void:
	add_to_group("status_effects")


func apply_effect(target: Node2D, effect_name: String, duration: float) -> void:
	var nid := target.get_instance_id()
	if not _active_effects.has(nid):
		_active_effects[nid] = {}

	_active_effects[nid][effect_name] = {
		"duration": duration,
		"tick_timer": 0.0,
		"target": target,
	}

	effect_applied.emit(target, effect_name)

	# Apply initial effect
	match effect_name:
		"poison":
			_tint_target(target, Color(0.5, 1.0, 0.5))
		"slow":
			_tint_target(target, Color(0.5, 0.5, 1.0))
			if target.has_method("set"):
				target.set("move_speed", target.get("move_speed") * 0.4 if target.get("move_speed") else 30.0)
		"stun":
			_tint_target(target, Color(1.0, 1.0, 0.3))


func _process(delta: float) -> void:
	var to_remove: Array[Array] = []

	for nid: int in _active_effects:
		var effects: Dictionary = _active_effects[nid]
		for ename: String in effects:
			var eff: Dictionary = effects[ename]
			var target: Node2D = eff.target
			if not is_instance_valid(target):
				to_remove.append([nid, ename])
				continue

			eff.duration -= delta

			# Tick effects
			match ename:
				"poison":
					eff.tick_timer += delta
					if eff.tick_timer >= 1.0:
						eff.tick_timer = 0.0
						if target.has_method("take_damage"):
							target.take_damage(3, Vector2.ZERO)
				"stun":
					if target is CharacterBody2D:
						target.velocity = Vector2.ZERO

			if eff.duration <= 0:
				to_remove.append([nid, ename])
				_remove_effect(target, ename)

	for entry in to_remove:
		if _active_effects.has(entry[0]) and _active_effects[entry[0]].has(entry[1]):
			_active_effects[entry[0]].erase(entry[1])
			if _active_effects[entry[0]].is_empty():
				_active_effects.erase(entry[0])


func _remove_effect(target: Node2D, effect_name: String) -> void:
	if not is_instance_valid(target):
		return
	match effect_name:
		"slow":
			if target.has_method("set"):
				target.set("move_speed", target.get("move_speed") / 0.4 if target.get("move_speed") else 60.0)
		_:
			pass
	# Reset tint
	target.modulate = Color.WHITE
	effect_removed.emit(target, effect_name)


func _tint_target(target: Node2D, color: Color) -> void:
	var tween := create_tween()
	tween.tween_property(target, "modulate", color, 0.2)


func has_effect(target: Node2D, effect_name: String) -> bool:
	var nid := target.get_instance_id()
	return _active_effects.has(nid) and _active_effects[nid].has(effect_name)
