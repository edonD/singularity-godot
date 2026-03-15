extends Node

## NEXUS AI Director — adapts to player playstyle and escalates threat over time.
## Stealth too much? Thermal sensors. Fight too much? Sentinels.
## Hoard supplies? Harvesters target your location.

signal threat_level_changed(level: int)
signal adaptation_triggered(type: String)
signal nexus_event(event_type: String)

# Playstyle tracking
var stealth_actions: int = 0  # dodges, camouflage uses, backstabs
var combat_actions: int = 0   # attacks, kills, abilities used
var hoard_score: float = 0.0  # inventory fullness over time
var tech_actions: int = 0     # hacking, turrets, tech skills

# Escalation
var threat_level: int = 1  # 1-10
var _escalation_timer: float = 0.0
var _adaptation_timer: float = 0.0
var _event_timer: float = 0.0
const ESCALATION_INTERVAL := 120.0 # 2 min
const ADAPTATION_CHECK := 60.0 # 1 min
const EVENT_CHECK := 45.0

# Active adaptations
var active_adaptations: Array[String] = []

# Escalation tiers - what NEXUS deploys at each threat level
var escalation_tiers: Dictionary = {
	1: {"name": "Scout Phase", "desc": "Light drone patrols", "enemy_mult": 1.0, "extra_enemies": []},
	2: {"name": "Surveillance", "desc": "Increased patrols, drones in pairs", "enemy_mult": 1.2, "extra_enemies": ["scout_drone"]},
	3: {"name": "Patrol Sweep", "desc": "Patrol bots added to rotation", "enemy_mult": 1.3, "extra_enemies": ["patrol_bot"]},
	4: {"name": "Active Search", "desc": "NEXUS is looking for you", "enemy_mult": 1.5, "extra_enemies": ["patrol_bot", "scout_drone"]},
	5: {"name": "Containment", "desc": "Harvesters deployed", "enemy_mult": 1.7, "extra_enemies": ["harvester"]},
	6: {"name": "Suppression", "desc": "All enemy types active", "enemy_mult": 2.0, "extra_enemies": ["mind_probe"]},
	7: {"name": "Elimination", "desc": "Sentinels join the hunt", "enemy_mult": 2.2, "extra_enemies": ["sentinel"]},
	8: {"name": "Scorched Earth", "desc": "Maximum aggression", "enemy_mult": 2.5, "extra_enemies": ["sentinel", "harvester"]},
	9: {"name": "Convergence", "desc": "NEXUS focuses everything on you", "enemy_mult": 3.0, "extra_enemies": ["sentinel"]},
	10: {"name": "SINGULARITY PROTOCOL", "desc": "Run.", "enemy_mult": 4.0, "extra_enemies": ["sentinel", "sentinel"]},
}


func _ready() -> void:
	add_to_group("nexus_director")
	GameManager.day_changed.connect(_on_day_changed)


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	_escalation_timer += delta
	_adaptation_timer += delta
	_event_timer += delta

	# Threat escalation over time
	if _escalation_timer >= ESCALATION_INTERVAL:
		_escalation_timer = 0.0
		_check_escalation()

	# Adaptation check
	if _adaptation_timer >= ADAPTATION_CHECK:
		_adaptation_timer = 0.0
		_check_adaptations()

	# Dynamic events
	if _event_timer >= EVENT_CHECK:
		_event_timer = 0.0
		_check_events()

	# Track hoarding
	var inv := get_tree().get_first_node_in_group("inventory")
	if inv and inv.has_method("get_total_weight"):
		hoard_score += inv.get_total_weight() * delta * 0.001


func _on_day_changed(day: int) -> void:
	# Day-based threat escalation
	var new_level := clampi(1 + day / 3, 1, 10)
	if new_level > threat_level:
		threat_level = new_level
		threat_level_changed.emit(threat_level)


func _check_escalation() -> void:
	# NEXUS awareness also drives escalation
	var awareness := GameManager.nexus_awareness
	if awareness > 70 and threat_level < 8:
		threat_level = mini(threat_level + 1, 10)
		threat_level_changed.emit(threat_level)


func _check_adaptations() -> void:
	var total := stealth_actions + combat_actions + tech_actions
	if total < 10:
		return

	var stealth_pct := float(stealth_actions) / total
	var combat_pct := float(combat_actions) / total

	# Stealth-heavy player: deploy thermal sensors
	if stealth_pct > 0.5 and not "thermal_sensors" in active_adaptations:
		active_adaptations.append("thermal_sensors")
		adaptation_triggered.emit("thermal_sensors")
		GameManager.nexus_adaptation.stealth_counter += 1

	# Combat-heavy player: send tougher enemies
	if combat_pct > 0.5 and not "combat_response" in active_adaptations:
		active_adaptations.append("combat_response")
		adaptation_triggered.emit("combat_response")
		GameManager.nexus_adaptation.combat_counter += 1

	# Hoarding player: send harvesters to base
	if hoard_score > 50 and not "harvester_raid" in active_adaptations:
		active_adaptations.append("harvester_raid")
		adaptation_triggered.emit("harvester_raid")
		GameManager.nexus_adaptation.hoard_counter += 1


func _check_events() -> void:
	if randf() > 0.2:
		return

	var possible_events: Array[String] = []

	# Supply drop
	if GameManager.day >= 2:
		possible_events.append("supply_drop")

	# NEXUS patrol sweep
	if threat_level >= 3:
		possible_events.append("patrol_sweep")

	# Survivor distress (timed rescue)
	if GameManager.day >= 3 and randf() < 0.3:
		possible_events.append("survivor_distress")

	# EMP storm (temporary advantage)
	if GameManager.day >= 5 and randf() < 0.15:
		possible_events.append("emp_storm")

	# NEXUS bombardment warning
	if threat_level >= 7:
		possible_events.append("bombardment_warning")

	if possible_events.size() > 0:
		var event: String = possible_events[randi() % possible_events.size()]
		nexus_event.emit(event)


func track_action(action_type: String) -> void:
	match action_type:
		"stealth":
			stealth_actions += 1
		"combat":
			combat_actions += 1
		"tech":
			tech_actions += 1


func get_enemy_multiplier() -> float:
	var tier: Dictionary = escalation_tiers.get(threat_level, escalation_tiers[1])
	return tier.enemy_mult


func get_enemy_hp_bonus() -> float:
	# Enemies get tougher as threat rises
	return (threat_level - 1) * 0.1 # 0% to 90% bonus HP


func get_enemy_damage_bonus() -> float:
	return (threat_level - 1) * 0.08 # 0% to 72% bonus damage


func get_detection_modifier() -> float:
	## How much easier it is for enemies to detect the player.
	var mod := 1.0
	if "thermal_sensors" in active_adaptations:
		mod += 0.3 # 30% better detection for enemies
	mod += threat_level * 0.05
	return mod


func get_current_tier_name() -> String:
	var tier: Dictionary = escalation_tiers.get(threat_level, escalation_tiers[1])
	return tier.name


func get_save_data() -> Dictionary:
	return {
		"stealth": stealth_actions,
		"combat": combat_actions,
		"tech": tech_actions,
		"hoard": hoard_score,
		"threat": threat_level,
		"adaptations": active_adaptations.duplicate(),
	}


func load_save_data(data: Dictionary) -> void:
	stealth_actions = data.get("stealth", 0)
	combat_actions = data.get("combat", 0)
	tech_actions = data.get("tech", 0)
	hoard_score = data.get("hoard", 0.0)
	threat_level = data.get("threat", 1)
	active_adaptations.assign(data.get("adaptations", []))
