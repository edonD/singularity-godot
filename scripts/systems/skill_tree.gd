extends Node

## Skill Tree — 3 branches (Combat, Stealth, Tech) with 8-10 skills each.
## Skills genuinely change gameplay: new attacks, passive bonuses, unique abilities.

signal skill_unlocked(skill_id: String)
signal skill_points_changed(points: int)

var skill_points: int = 0
var unlocked_skills: Dictionary = {} # skill_id -> true

# Each skill: {name, desc, branch, cost, requires, effect}
# effect is a dictionary describing what changes
var skills: Dictionary = {
	# ---- COMBAT BRANCH ----
	"combat_power_strike": {
		"name": "Power Strike", "desc": "Melee attacks deal 20% more damage.",
		"branch": "combat", "cost": 1, "requires": [],
		"effect": {"melee_dmg_mult": 1.2}, "icon_color": Color(0.9, 0.3, 0.2)
	},
	"combat_berserker": {
		"name": "Berserker Rage", "desc": "Below 30% HP: +50% attack speed and damage.",
		"branch": "combat", "cost": 2, "requires": ["combat_power_strike"],
		"effect": {"berserker": true}, "icon_color": Color(1.0, 0.2, 0.1)
	},
	"combat_shield_bash": {
		"name": "Shield Bash", "desc": "Dodge into enemies to stun them for 1.5s.",
		"branch": "combat", "cost": 1, "requires": [],
		"effect": {"shield_bash": true}, "icon_color": Color(0.6, 0.6, 0.8)
	},
	"combat_counter": {
		"name": "Counter-Attack", "desc": "Perfect dodge timing triggers free counter hit (2x damage).",
		"branch": "combat", "cost": 2, "requires": ["combat_shield_bash"],
		"effect": {"counter_attack": true}, "icon_color": Color(0.8, 0.5, 0.2)
	},
	"combat_dual_wield": {
		"name": "Dual Wield", "desc": "Attack combo hits twice per swing. -10% damage per hit.",
		"branch": "combat", "cost": 2, "requires": ["combat_power_strike"],
		"effect": {"dual_wield": true}, "icon_color": Color(0.7, 0.4, 0.3)
	},
	"combat_execute": {
		"name": "Execute", "desc": "Enemies below 10% HP die instantly on hit.",
		"branch": "combat", "cost": 3, "requires": ["combat_berserker", "combat_dual_wield"],
		"effect": {"execute_threshold": 0.1}, "icon_color": Color(0.8, 0.1, 0.1)
	},
	"combat_thick_skin": {
		"name": "Thick Skin", "desc": "+5 defense, +25 max HP.",
		"branch": "combat", "cost": 1, "requires": [],
		"effect": {"defense_bonus": 5, "max_hp_bonus": 25}, "icon_color": Color(0.5, 0.5, 0.4)
	},
	"combat_war_cry": {
		"name": "War Cry", "desc": "Press 4: Frighten enemies in range, reducing their damage by 30% for 8s.",
		"branch": "combat", "cost": 2, "requires": ["combat_thick_skin"],
		"effect": {"war_cry": true}, "icon_color": Color(0.9, 0.6, 0.2)
	},
	"combat_bloodlust": {
		"name": "Bloodlust", "desc": "Each kill heals 10 HP and grants 5% attack for 10s (stacks 5x).",
		"branch": "combat", "cost": 3, "requires": ["combat_execute"],
		"effect": {"bloodlust": true}, "icon_color": Color(0.7, 0.1, 0.2)
	},

	# ---- STEALTH BRANCH ----
	"stealth_silent_move": {
		"name": "Silent Movement", "desc": "Enemy detection range reduced by 30%.",
		"branch": "stealth", "cost": 1, "requires": [],
		"effect": {"detection_reduction": 0.3}, "icon_color": Color(0.3, 0.5, 0.3)
	},
	"stealth_backstab": {
		"name": "Backstab", "desc": "Hitting unaware enemies deals 3x damage.",
		"branch": "stealth", "cost": 2, "requires": ["stealth_silent_move"],
		"effect": {"backstab_mult": 3.0}, "icon_color": Color(0.4, 0.3, 0.5)
	},
	"stealth_distraction": {
		"name": "Distraction Throw", "desc": "Press 5: Throw a noise maker to lure enemies.",
		"branch": "stealth", "cost": 1, "requires": [],
		"effect": {"distraction_throw": true}, "icon_color": Color(0.5, 0.5, 0.3)
	},
	"stealth_camouflage": {
		"name": "Camouflage", "desc": "Stand still for 2s to become invisible. Moving breaks it.",
		"branch": "stealth", "cost": 2, "requires": ["stealth_silent_move"],
		"effect": {"camouflage": true}, "icon_color": Color(0.2, 0.4, 0.2)
	},
	"stealth_pickpocket": {
		"name": "Pickpocket", "desc": "Interact with unaware enemies to steal components.",
		"branch": "stealth", "cost": 2, "requires": ["stealth_backstab"],
		"effect": {"pickpocket": true}, "icon_color": Color(0.6, 0.5, 0.3)
	},
	"stealth_runner": {
		"name": "Runner", "desc": "+25% sprint speed, +15% dodge distance.",
		"branch": "stealth", "cost": 1, "requires": [],
		"effect": {"sprint_bonus": 0.25, "dodge_bonus": 0.15}, "icon_color": Color(0.3, 0.6, 0.6)
	},
	"stealth_night_owl": {
		"name": "Night Owl", "desc": "At night: +20% speed, +15% crit chance, enemies detect 40% slower.",
		"branch": "stealth", "cost": 2, "requires": ["stealth_runner"],
		"effect": {"night_owl": true}, "icon_color": Color(0.2, 0.2, 0.5)
	},
	"stealth_shadow_strike": {
		"name": "Shadow Strike", "desc": "While camouflaged, first attack deals 5x damage and stuns 3s.",
		"branch": "stealth", "cost": 3, "requires": ["stealth_camouflage", "stealth_backstab"],
		"effect": {"shadow_strike": true}, "icon_color": Color(0.1, 0.1, 0.3)
	},
	"stealth_ghost": {
		"name": "Ghost", "desc": "Dodge leaves an afterimage that enemies attack for 2s.",
		"branch": "stealth", "cost": 3, "requires": ["stealth_shadow_strike"],
		"effect": {"ghost_dodge": true}, "icon_color": Color(0.4, 0.4, 0.6)
	},

	# ---- TECH BRANCH ----
	"tech_scanner": {
		"name": "Scanner", "desc": "Reveals all enemies and items within 200px on minimap.",
		"branch": "tech", "cost": 1, "requires": [],
		"effect": {"scanner_range": 200.0}, "icon_color": Color(0.2, 0.6, 0.8)
	},
	"tech_turret": {
		"name": "Turret Deployment", "desc": "Press 6: Place an auto-turret (30s duration, 10 dmg/shot).",
		"branch": "tech", "cost": 2, "requires": ["tech_scanner"],
		"effect": {"turret_deploy": true}, "icon_color": Color(0.4, 0.6, 0.3)
	},
	"tech_emp_upgrade": {
		"name": "EMP Upgrade", "desc": "EMP Pulse range +50%, stun duration +2s, damages machines.",
		"branch": "tech", "cost": 2, "requires": ["tech_scanner"],
		"effect": {"emp_upgrade": true}, "icon_color": Color(0.3, 0.3, 0.9)
	},
	"tech_drone_hack": {
		"name": "Drone Hijacking", "desc": "Interact with stunned Scout Drones to convert them to allies for 60s.",
		"branch": "tech", "cost": 2, "requires": ["tech_emp_upgrade"],
		"effect": {"drone_hack": true}, "icon_color": Color(0.2, 0.7, 0.5)
	},
	"tech_nexus_mimicry": {
		"name": "NEXUS Mimicry", "desc": "Press 7: Disguise as NEXUS unit for 15s. Enemies ignore you.",
		"branch": "tech", "cost": 3, "requires": ["tech_drone_hack"],
		"effect": {"nexus_mimicry": true}, "icon_color": Color(0.5, 0.2, 0.7)
	},
	"tech_scavenger": {
		"name": "Scavenger", "desc": "Enemies drop 50% more loot. Crates have double items.",
		"branch": "tech", "cost": 1, "requires": [],
		"effect": {"loot_bonus": 0.5}, "icon_color": Color(0.6, 0.6, 0.3)
	},
	"tech_repair": {
		"name": "Field Repair", "desc": "Crafting costs reduced by 25%. Can craft without workbench.",
		"branch": "tech", "cost": 2, "requires": ["tech_scavenger"],
		"effect": {"craft_discount": 0.25, "portable_craft": true}, "icon_color": Color(0.5, 0.5, 0.5)
	},
	"tech_overcharge": {
		"name": "Overcharge", "desc": "All tech abilities have 30% reduced cooldown.",
		"branch": "tech", "cost": 2, "requires": ["tech_emp_upgrade"],
		"effect": {"cooldown_reduction": 0.3}, "icon_color": Color(0.7, 0.7, 0.2)
	},
	"tech_singularity": {
		"name": "Singularity Core", "desc": "Press 8: Deploy a gravity well pulling enemies in and dealing massive damage.",
		"branch": "tech", "cost": 3, "requires": ["tech_nexus_mimicry", "tech_overcharge"],
		"effect": {"singularity_core": true}, "icon_color": Color(0.6, 0.1, 0.8)
	},
}


func _ready() -> void:
	add_to_group("skill_tree")


func has_skill(skill_id: String) -> bool:
	return unlocked_skills.has(skill_id)


func can_unlock(skill_id: String) -> bool:
	if not skills.has(skill_id):
		return false
	if has_skill(skill_id):
		return false
	var skill: Dictionary = skills[skill_id]
	if skill_points < skill.cost:
		return false
	# Check prerequisites
	for req: String in skill.requires:
		if not has_skill(req):
			return false
	return true


func unlock_skill(skill_id: String) -> bool:
	if not can_unlock(skill_id):
		return false
	var skill: Dictionary = skills[skill_id]
	skill_points -= skill.cost
	unlocked_skills[skill_id] = true
	_apply_passive_effects(skill_id)
	skill_unlocked.emit(skill_id)
	skill_points_changed.emit(skill_points)
	AudioManager.play_sfx("levelup")
	return true


func add_skill_points(amount: int) -> void:
	skill_points += amount
	skill_points_changed.emit(skill_points)


func get_branch_skills(branch: String) -> Array[String]:
	var result: Array[String] = []
	for sid: String in skills:
		if skills[sid].branch == branch:
			result.append(sid)
	return result


func get_effect_value(effect_key: String, default_value: Variant = null) -> Variant:
	## Check all unlocked skills for a specific effect
	for sid: String in unlocked_skills:
		if skills.has(sid):
			var eff: Dictionary = skills[sid].effect
			if eff.has(effect_key):
				return eff[effect_key]
	return default_value


func get_effect_sum(effect_key: String) -> float:
	## Sum up a numeric effect across all unlocked skills
	var total := 0.0
	for sid: String in unlocked_skills:
		if skills.has(sid):
			var eff: Dictionary = skills[sid].effect
			if eff.has(effect_key):
				total += float(eff[effect_key])
	return total


func _apply_passive_effects(skill_id: String) -> void:
	## Apply immediate stat changes from passive skills
	var skill: Dictionary = skills[skill_id]
	var eff: Dictionary = skill.effect
	var s := GameManager.player_stats

	if eff.has("defense_bonus"):
		s.defense += int(eff.defense_bonus)
	if eff.has("max_hp_bonus"):
		s.max_hp += int(eff.max_hp_bonus)
		s.hp = mini(s.hp + int(eff.max_hp_bonus), s.max_hp)


func get_save_data() -> Dictionary:
	return {
		"skill_points": skill_points,
		"unlocked": unlocked_skills.keys(),
	}


func load_save_data(data: Dictionary) -> void:
	skill_points = data.get("skill_points", 0)
	unlocked_skills.clear()
	for sid: String in data.get("unlocked", []):
		unlocked_skills[sid] = true
		_apply_passive_effects(sid)
	skill_points_changed.emit(skill_points)
