extends Node

## Survival system — hunger, thirst, and their effects on the player.

const HUNGER_DRAIN := 1.5  # per minute
const THIRST_DRAIN := 2.0  # per minute
const STARVE_DAMAGE := 5   # HP loss per tick when starving
const DEHYDRATE_DAMAGE := 8
const DAMAGE_INTERVAL := 5.0 # seconds between starvation ticks

var _damage_timer: float = 0.0


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	var s := GameManager.player_stats

	# Drain hunger and thirst over time
	s.hunger = maxf(s.hunger - HUNGER_DRAIN * delta / 60.0, 0.0)
	s.thirst = maxf(s.thirst - THIRST_DRAIN * delta / 60.0, 0.0)

	# Update HUD
	if GameManager.player:
		if GameManager.player.has_signal("hunger_changed"):
			GameManager.player.hunger_changed.emit(s.hunger)
		if GameManager.player.has_signal("thirst_changed"):
			GameManager.player.thirst_changed.emit(s.thirst)

	# Starvation / dehydration damage
	if s.hunger <= 0 or s.thirst <= 0:
		_damage_timer += delta
		if _damage_timer >= DAMAGE_INTERVAL:
			_damage_timer = 0.0
			var dmg := 0
			if s.hunger <= 0:
				dmg += STARVE_DAMAGE
			if s.thirst <= 0:
				dmg += DEHYDRATE_DAMAGE
			if GameManager.player and GameManager.player.has_method("take_damage"):
				GameManager.player.take_damage(dmg, Vector2.ZERO)
	else:
		_damage_timer = 0.0

	# Low hunger/thirst slows player
	if s.hunger < 20 or s.thirst < 20:
		s.speed = 80.0
	elif s.speed < 120.0 and s.hunger >= 20 and s.thirst >= 20:
		s.speed = 120.0
