extends Node

## Life Dilemmas — moral choices with REAL consequences.
## Not good/evil binary. Genuinely hard choices that affect gameplay.
## Dilemmas trigger organically through exploration and events.

signal dilemma_triggered(dilemma_id: String)
signal dilemma_resolved(dilemma_id: String, choice: String)

var _triggered_dilemmas: Dictionary = {} # id -> true (prevent repeats)
var _check_timer: float = 0.0
const CHECK_INTERVAL := 10.0


# All dilemmas defined here with choices and consequences
var dilemmas: Dictionary = {
	"dying_survivor": {
		"title": "A DYING STRANGER",
		"text": "A wounded survivor crawls toward you, bleeding badly.\n\"Please... your medkit... I can see it. I'll die without it.\"\nYou have limited supplies. You might need them yourself.",
		"condition": "has_bandage",
		"choices": [
			{
				"text": "Give them your bandage",
				"tag": "compassionate",
				"effects": {
					"remove_item": "bandage",
					"emotion": {"hope": 10, "determination": 5, "despair": -5},
					"morality": {"compassionate": 3},
					"spawn_ally": true,
					"description": "They survived. A grateful ally remembers your kindness.",
				},
			},
			{
				"text": "Keep your supplies — you need them",
				"tag": "pragmatic",
				"effects": {
					"emotion": {"despair": 5, "determination": 3, "hope": -3},
					"morality": {"pragmatic": 2},
					"description": "You walk away. The silence behind you is deafening.",
				},
			},
			{
				"text": "Take their supplies too — they won't need them",
				"tag": "ruthless",
				"effects": {
					"add_item": {"scrap_metal": 3, "wire": 2},
					"emotion": {"despair": 8, "hope": -8},
					"morality": {"ruthless": 4},
					"nexus_awareness": -5.0,
					"description": "You scavenge what you can. Survival demands sacrifice.",
				},
			},
		],
	},
	"nexus_terminal": {
		"title": "NEXUS DATA TERMINAL",
		"text": "A NEXUS terminal pulses with data. You could download it —\ninvaluable intel about patrol routes and weaknesses.\nBut accessing it will ping your location. NEXUS will hunt you for 2 days.",
		"condition": "near_terminal",
		"choices": [
			{
				"text": "Download the data — knowledge is power",
				"tag": "pragmatic",
				"effects": {
					"nexus_awareness": 30.0,
					"unlock_map_intel": true,
					"emotion": {"determination": 8, "fear": 10},
					"morality": {"pragmatic": 3},
					"description": "Data downloaded. NEXUS knows you're here. Clock is ticking.",
				},
			},
			{
				"text": "Destroy the terminal — stay hidden",
				"tag": "pragmatic",
				"effects": {
					"nexus_awareness": -10.0,
					"xp_bonus": 30,
					"emotion": {"determination": 5, "fear": -5},
					"morality": {"pragmatic": 2},
					"description": "The terminal sparks and dies. Your secret is safe. For now.",
				},
			},
		],
	},
	"outpost_raid": {
		"title": "STRENGTH IN NUMBERS?",
		"text": "A group of survivors found a NEXUS outpost. They want to raid it.\n\"We need your skills. Together, we can take it. Alone... some of us won't make it.\"\nThe rewards would be massive. But so is the risk.",
		"condition": "day_5_plus",
		"choices": [
			{
				"text": "Join the raid — together we're stronger",
				"tag": "compassionate",
				"effects": {
					"spawn_raid_event": true,
					"emotion": {"determination": 12, "fear": 8, "hope": 5},
					"morality": {"compassionate": 2, "pragmatic": 1},
					"description": "You gear up. The raid begins at dusk.",
				},
			},
			{
				"text": "Refuse — it's too dangerous",
				"tag": "pragmatic",
				"effects": {
					"emotion": {"fear": -3, "despair": 8, "hope": -5},
					"morality": {"pragmatic": 3},
					"radio_message": "static_screams",
					"description": "Hours later, distant explosions. Then silence. Then screams on the radio.",
				},
			},
		],
	},
	"lost_child": {
		"title": "A CHILD ALONE",
		"text": "You find a child hiding in a collapsed building, terrified.\nThey've been alone for days. Taking them means sharing food,\nmoving slower, and constant danger. Leaving them...\nyou know a safe house nearby. Maybe they can make it.",
		"condition": "day_3_plus",
		"choices": [
			{
				"text": "Take them with you",
				"tag": "compassionate",
				"effects": {
					"companion_child": true,
					"hunger_drain_mult": 1.5,
					"speed_mult": 0.85,
					"emotion": {"hope": 15, "determination": 10, "despair": -10},
					"morality": {"compassionate": 5},
					"special_ending_unlock": "protector",
					"description": "Small fingers grip yours. You have something to protect now.",
				},
			},
			{
				"text": "Give them directions to the safe house",
				"tag": "pragmatic",
				"effects": {
					"emotion": {"despair": 5, "hope": -3, "determination": 2},
					"morality": {"pragmatic": 3},
					"description": "You point the way and leave. You tell yourself it's enough.",
				},
			},
		],
	},
	"captured_experiment": {
		"title": "WHAT REMAINS",
		"text": "A captured survivor in a NEXUS pod. They're alive but... changed.\nCircuitry under their skin. Eyes that glow faintly blue.\nThey beg for release. \"I'm still me. Please. I'm still human.\"\nAre they? Can you trust them?",
		"condition": "day_7_plus",
		"choices": [
			{
				"text": "Free them — everyone deserves a chance",
				"tag": "compassionate",
				"effects": {
					"spawn_hybrid_ally": true,
					"nexus_awareness": 15.0,
					"emotion": {"hope": 10, "fear": 8, "determination": 5},
					"morality": {"compassionate": 4},
					"description": "The pod hisses open. They stumble out. Human enough. You hope.",
				},
			},
			{
				"text": "Leave them — too risky",
				"tag": "pragmatic",
				"effects": {
					"emotion": {"despair": 10, "fear": -3},
					"morality": {"pragmatic": 3},
					"description": "You turn away from the blue glow. The begging stops eventually.",
				},
			},
			{
				"text": "Destroy the pod — end their suffering",
				"tag": "ruthless",
				"effects": {
					"xp_bonus": 50,
					"emotion": {"despair": 8, "determination": 5, "hope": -5},
					"morality": {"ruthless": 3, "pragmatic": 1},
					"nexus_awareness": -5.0,
					"description": "A clean end. NEXUS loses a data point. So does humanity.",
				},
			},
		],
	},
	"shelter_discovered": {
		"title": "THEY FOUND YOU",
		"text": "NEXUS drones circle overhead. They've found your shelter.\nEverything you've built, stored, gathered — it's here.\nYou can fight the incoming wave and hope to keep it all.\nOr abandon it now before they send the heavy units.",
		"condition": "day_10_plus",
		"choices": [
			{
				"text": "Stand and fight — this is YOUR home",
				"tag": "determined",
				"effects": {
					"spawn_defense_wave": true,
					"emotion": {"determination": 15, "fear": 10, "hope": 5},
					"morality": {"pragmatic": 2},
					"description": "You barricade the door. They're coming. Let them come.",
				},
			},
			{
				"text": "Grab what you can and run",
				"tag": "pragmatic",
				"effects": {
					"lose_shelter": true,
					"keep_inventory": true,
					"emotion": {"despair": 12, "fear": 5, "determination": -5},
					"morality": {"pragmatic": 3},
					"description": "You flee with a pack on your back. Behind you, metal feet crush your work.",
				},
			},
		],
	},
}


func _ready() -> void:
	add_to_group("dilemma_system")


func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer < CHECK_INTERVAL:
		return
	_check_timer = 0.0
	_check_dilemma_conditions()


func _check_dilemma_conditions() -> void:
	for did: String in dilemmas:
		if _triggered_dilemmas.has(did):
			continue
		if _evaluate_condition(dilemmas[did].condition):
			# Random chance to trigger (don't spam)
			if randf() < 0.15:
				trigger_dilemma(did)
				return # One at a time


func _evaluate_condition(condition: String) -> bool:
	match condition:
		"has_bandage":
			var inv := get_tree().get_first_node_in_group("inventory")
			return inv and inv.has_method("has_item") and inv.has_item("bandage")
		"near_terminal":
			return GameManager.day >= 2
		"day_3_plus":
			return GameManager.day >= 3
		"day_5_plus":
			return GameManager.day >= 5
		"day_7_plus":
			return GameManager.day >= 7
		"day_10_plus":
			return GameManager.day >= 10
	return false


func trigger_dilemma(dilemma_id: String) -> void:
	if _triggered_dilemmas.has(dilemma_id):
		return
	_triggered_dilemmas[dilemma_id] = true
	dilemma_triggered.emit(dilemma_id)


func resolve_dilemma(dilemma_id: String, choice_idx: int) -> void:
	if not dilemmas.has(dilemma_id):
		return
	var dilemma: Dictionary = dilemmas[dilemma_id]
	if choice_idx < 0 or choice_idx >= dilemma.choices.size():
		return

	var choice: Dictionary = dilemma.choices[choice_idx]
	var effects: Dictionary = choice.effects

	# Apply emotional effects
	if effects.has("emotion"):
		for emo_key: String in effects.emotion:
			GameManager.adjust_emotion(emo_key, int(effects.emotion[emo_key]))

	# Apply morality
	if effects.has("morality"):
		for mor_key: String in effects.morality:
			GameManager.add_morality(mor_key, int(effects.morality[mor_key]))

	# Apply NEXUS awareness
	if effects.has("nexus_awareness"):
		GameManager.nexus_awareness += float(effects.nexus_awareness)
		GameManager.nexus_awareness = clampf(GameManager.nexus_awareness, 0.0, 100.0)

	# Apply XP bonus
	if effects.has("xp_bonus"):
		GameManager.add_xp(int(effects.xp_bonus))

	# Apply item removal
	if effects.has("remove_item"):
		var inv := get_tree().get_first_node_in_group("inventory")
		if inv and inv.has_method("remove_item"):
			inv.remove_item(effects.remove_item, 1)

	# Apply item additions
	if effects.has("add_item"):
		var inv := get_tree().get_first_node_in_group("inventory")
		if inv and inv.has_method("add_item"):
			for item_id: String in effects.add_item:
				inv.add_item(item_id, int(effects.add_item[item_id]))

	# Record choice
	GameManager.record_dilemma(dilemma_id, choice.tag)

	dilemma_resolved.emit(dilemma_id, choice.tag)


func get_save_data() -> Dictionary:
	return {"triggered": _triggered_dilemmas.keys()}


func load_save_data(data: Dictionary) -> void:
	_triggered_dilemmas.clear()
	for did: String in data.get("triggered", []):
		_triggered_dilemmas[did] = true
