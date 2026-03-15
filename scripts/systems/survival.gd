extends Node

## Survival system — hunger, thirst, temperature, injuries, sleep, food spoilage.
## Interconnected systems that create real survival pressure.

signal injury_added(injury: String)
signal temperature_changed(temp: float)
signal sleep_changed(sleep: float)

const HUNGER_DRAIN := 1.5  # per minute
const THIRST_DRAIN := 2.0  # per minute
const STARVE_DAMAGE := 5   # HP loss per tick when starving
const DEHYDRATE_DAMAGE := 8
const DAMAGE_INTERVAL := 5.0 # seconds between starvation ticks
const SLEEP_DRAIN := 0.8 # per minute — need to rest every ~2 hours game time

var _damage_timer: float = 0.0
var _spoil_timer: float = 0.0
var _temp_update_timer: float = 0.0

# Temperature system — 0=freezing, 50=comfortable, 100=burning
var temperature: float = 50.0
var body_temp: float = 50.0 # What the player feels
var near_fire: bool = false

# Sleep system — 0=hallucinating, 100=fully rested
var sleep_level: float = 100.0
var is_resting: bool = false

# Injury system
var injuries: Array[Dictionary] = []
# Each injury: {type, severity, timer, effect}
# Types: bleeding, broken_limb, infection, burn, frostbite

# Spoilable food tracking — items that decay over time
var _spoil_timers: Dictionary = {} # item_id -> seconds_remaining


func _ready() -> void:
	add_to_group("survival")


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	var s := GameManager.player_stats

	# Drain hunger and thirst over time
	var hunger_mult := 1.0
	# Cold increases hunger drain
	if body_temp < 30.0:
		hunger_mult = 1.5
	s.hunger = maxf(s.hunger - HUNGER_DRAIN * hunger_mult * delta / 60.0, 0.0)
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
			# Emotional impact
			var emo := get_tree().get_first_node_in_group("emotional_state")
			if emo and emo.has_method("on_starvation"):
				emo.on_starvation()
	else:
		_damage_timer = 0.0

	# Low hunger/thirst slows player
	if s.hunger < 20 or s.thirst < 20:
		s.speed = 80.0
	elif s.speed < 120.0 and s.hunger >= 20 and s.thirst >= 20:
		s.speed = 120.0

	# Temperature system
	_update_temperature(delta)

	# Sleep system
	_update_sleep(delta)

	# Injury system
	_update_injuries(delta)

	# Food spoilage
	_update_spoilage(delta)


# ---- TEMPERATURE ----

func _update_temperature(delta: float) -> void:
	_temp_update_timer += delta
	if _temp_update_timer < 2.0:
		return
	_temp_update_timer = 0.0

	# Calculate ambient temperature based on biome, time, weather
	var ambient := 50.0

	# Night is cold
	if GameManager.is_night:
		ambient -= 20.0

	# Near fire warms you
	if near_fire:
		ambient += 30.0

	# Body temp moves toward ambient
	body_temp = lerpf(body_temp, ambient, 0.1)
	body_temp = clampf(body_temp, 0.0, 100.0)
	temperature_changed.emit(body_temp)

	# Cold effects
	if body_temp < 20.0:
		# Freezing — take damage
		if GameManager.player and GameManager.player.has_method("take_damage"):
			GameManager.player.take_damage(3, Vector2.ZERO)
		# Risk of frostbite
		if body_temp < 10.0 and randf() < 0.1:
			add_injury("frostbite", 1)

	# Heat effects (near fire + daytime in ruins)
	if body_temp > 85.0:
		if randf() < 0.05:
			add_injury("burn", 1)


# ---- SLEEP ----

func _update_sleep(delta: float) -> void:
	if is_resting:
		sleep_level = minf(sleep_level + 15.0 * delta / 60.0, 100.0)
		# Resting also heals slightly
		var s := GameManager.player_stats
		s.hp = mini(s.hp + 1, s.max_hp)
	else:
		sleep_level = maxf(sleep_level - SLEEP_DRAIN * delta / 60.0, 0.0)

	sleep_changed.emit(sleep_level)

	var s := GameManager.player_stats

	# Sleep deprivation effects
	if sleep_level < 30.0:
		# Reduced performance
		s.crit_chance = maxf(s.crit_chance - 0.001 * delta, 0.0)

	if sleep_level < 15.0:
		# Hallucinations — camera shake, occasional phantom enemies
		if randf() < 0.001 * delta:
			CameraManager.shake(3.0)

	if sleep_level <= 0.0:
		# Collapse — take damage
		if GameManager.player and GameManager.player.has_method("take_damage"):
			GameManager.player.take_damage(2, Vector2.ZERO)


func start_resting() -> void:
	is_resting = true


func stop_resting() -> void:
	is_resting = false


# ---- INJURIES ----

func add_injury(injury_type: String, severity: int) -> void:
	# Check if already have this injury
	for inj in injuries:
		if inj.type == injury_type:
			inj.severity = mini(inj.severity + severity, 3)
			return

	var duration := 0.0
	match injury_type:
		"bleeding":
			duration = 60.0 # 1 minute, needs bandage
		"broken_limb":
			duration = 300.0 # 5 minutes, severe
		"infection":
			duration = 180.0 # 3 minutes, needs antibiotics
		"burn":
			duration = 90.0
		"frostbite":
			duration = 120.0

	injuries.append({
		"type": injury_type,
		"severity": severity,
		"timer": duration,
		"max_timer": duration,
	})
	injury_added.emit(injury_type)
	AudioManager.play_sfx("hurt")


func heal_injury(injury_type: String) -> bool:
	for i in injuries.size():
		if injuries[i].type == injury_type:
			injuries.remove_at(i)
			return true
	return false


func has_injury(injury_type: String) -> bool:
	for inj in injuries:
		if inj.type == injury_type:
			return true
	return false


func _update_injuries(delta: float) -> void:
	var s := GameManager.player_stats
	var to_remove: Array[int] = []

	for i in injuries.size():
		var inj: Dictionary = injuries[i]
		inj.timer -= delta

		# Apply injury effects
		match inj.type:
			"bleeding":
				# Lose HP over time
				if fmod(inj.timer, 3.0) < delta:
					s.hp = maxi(s.hp - 2 * inj.severity, 1)
			"broken_limb":
				# Speed reduction (applied elsewhere via check)
				pass
			"infection":
				# Periodic damage, worsens over time
				if fmod(inj.timer, 5.0) < delta:
					s.hp = maxi(s.hp - 3 * inj.severity, 1)
			"burn":
				# Pain — stamina regen reduced (applied elsewhere)
				pass
			"frostbite":
				# Reduced attack speed (applied elsewhere)
				pass

		if inj.timer <= 0:
			to_remove.append(i)

	# Remove expired injuries (reverse order)
	to_remove.reverse()
	for idx in to_remove:
		injuries.remove_at(idx)


func get_speed_modifier() -> float:
	var mod := 1.0
	for inj in injuries:
		if inj.type == "broken_limb":
			mod -= 0.3 * inj.severity
		if inj.type == "frostbite":
			mod -= 0.1 * inj.severity
	# Sleep deprivation
	if sleep_level < 30.0:
		mod -= 0.15
	return maxf(mod, 0.3)


func get_attack_modifier() -> float:
	var mod := 1.0
	for inj in injuries:
		if inj.type == "frostbite":
			mod -= 0.15 * inj.severity
		if inj.type == "burn":
			mod -= 0.1 * inj.severity
	if sleep_level < 20.0:
		mod -= 0.2
	return maxf(mod, 0.3)


# ---- FOOD SPOILAGE ----

func _update_spoilage(delta: float) -> void:
	_spoil_timer += delta
	if _spoil_timer < 30.0: # Check every 30s
		return
	_spoil_timer = 0.0

	var inv := get_tree().get_first_node_in_group("inventory")
	if not inv:
		return

	# Cooked meat and canned food spoil over time
	# In real game time: cooked meat lasts ~10 min, canned food lasts ~30 min
	for item_id: String in ["cooked_meat"]:
		if not _spoil_timers.has(item_id):
			if inv.has_method("has_item") and inv.has_item(item_id):
				_spoil_timers[item_id] = 600.0 # 10 minutes
		else:
			_spoil_timers[item_id] -= 30.0
			if _spoil_timers[item_id] <= 0:
				# Food spoiled — remove it
				if inv.has_method("remove_item"):
					inv.remove_item(item_id, 1)
				_spoil_timers.erase(item_id)


func get_save_data() -> Dictionary:
	return {
		"temperature": body_temp,
		"sleep": sleep_level,
		"injuries": injuries.duplicate(),
		"spoil_timers": _spoil_timers.duplicate(),
	}


func load_save_data(data: Dictionary) -> void:
	body_temp = data.get("temperature", 50.0)
	sleep_level = data.get("sleep", 100.0)
	injuries.assign(data.get("injuries", []))
	_spoil_timers = data.get("spoil_timers", {})
