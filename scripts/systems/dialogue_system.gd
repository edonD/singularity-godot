extends Node

## Dialogue System — branching conversations with NPC portraits.
## Supports choices, emotion-gated options, skill checks, and consequences.

signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal choice_made(npc_id: String, choice_id: String)

var is_active: bool = false
var _current_npc_id: String = ""
var _current_node_id: String = ""

# Dialogue trees: npc_id -> {nodes}
# Each node: {text, speaker, portrait_color, choices: [{text, next, condition, effects}]}
var dialogues: Dictionary = {
	"survivor_anna": {
		"start": {
			"speaker": "Anna", "portrait_color": Color(0.7, 0.5, 0.4),
			"text": "You're... real? Not one of them? I've been hiding here for days.",
			"choices": [
				{"text": "You're safe now. I'm human.", "next": "grateful", "id": "reassure"},
				{"text": "How did you survive this long?", "next": "story", "id": "ask_story"},
				{"text": "[Determined] We'll get through this. Together.", "next": "ally_offer", "id": "determined", "condition": "emotion_determined"},
				{"text": "[Fearful] I can barely save myself...", "next": "honest", "id": "fearful", "condition": "emotion_fearful"},
			],
		},
		"grateful": {
			"speaker": "Anna", "portrait_color": Color(0.7, 0.5, 0.4),
			"text": "Thank you... here, take this. I found it in the wreckage.",
			"effects": {"add_item": {"bandage": 2}, "emotion": {"hope": 5}, "xp": 15},
			"choices": [{"text": "Thanks. Stay hidden.", "next": "", "id": "end"}],
		},
		"story": {
			"speaker": "Anna", "portrait_color": Color(0.7, 0.5, 0.4),
			"text": "The drones swept through town at dawn. I hid in a basement.\nI heard them dragging people out. The screaming stopped after an hour.\nThen silence. That's worse.",
			"effects": {"emotion": {"fear": 3, "determination": 2}},
			"choices": [
				{"text": "We need to fight back.", "next": "fight_response", "id": "fight"},
				{"text": "Is there anything useful around here?", "next": "loot_info", "id": "loot"},
			],
		},
		"ally_offer": {
			"speaker": "Anna", "portrait_color": Color(0.7, 0.5, 0.4),
			"text": "Together... I like the sound of that. I know where there's supplies.\nAn old military cache, north of here. But NEXUS patrols that area.",
			"effects": {"unlock_mission": "military_cache", "emotion": {"hope": 8}},
			"choices": [{"text": "Mark it on my map. I'll check it out.", "next": "", "id": "end"}],
		},
		"honest": {
			"speaker": "Anna", "portrait_color": Color(0.7, 0.5, 0.4),
			"text": "At least you're honest. Most people would lie. Here — you need this\nmore than me. I've been scavenging for days.",
			"effects": {"add_item": {"canned_food": 1, "water_bottle": 1}, "emotion": {"hope": 3}},
			"choices": [{"text": "...thank you.", "next": "", "id": "end"}],
		},
		"fight_response": {
			"speaker": "Anna", "portrait_color": Color(0.7, 0.5, 0.4),
			"text": "Fight? With what? You've got guts, I'll give you that.\nThere's a weapons stash in the bunker. I can tell you the code.",
			"effects": {"add_item": {"scrap_metal": 5}, "xp": 20},
			"choices": [{"text": "Tell me everything you know.", "next": "", "id": "end"}],
		},
		"loot_info": {
			"speaker": "Anna", "portrait_color": Color(0.7, 0.5, 0.4),
			"text": "The hardware store two blocks east might have supplies.\nBut I saw a Patrol Bot near it. Be careful.",
			"effects": {"xp": 10, "emotion": {"determination": 3}},
			"choices": [{"text": "I'll check it out. Stay safe.", "next": "", "id": "end"}],
		},
	},
	"trader_eli": {
		"start": {
			"speaker": "Eli", "portrait_color": Color(0.5, 0.6, 0.4),
			"text": "Hey, you look like someone who's still alive on purpose.\nI trade. Got things. Need things. We deal?",
			"choices": [
				{"text": "What do you have?", "next": "trade_offer", "id": "trade"},
				{"text": "How are you still alive?", "next": "eli_story", "id": "story"},
				{"text": "[Tech skills] That's some nice gear. Modified?", "next": "tech_talk", "id": "tech", "condition": "skill_tech_scanner"},
			],
		},
		"trade_offer": {
			"speaker": "Eli", "portrait_color": Color(0.5, 0.6, 0.4),
			"text": "Circuit boards, batteries, even some NEXUS components.\nAin't cheap though. Everything costs more now that money's toilet paper.",
			"effects": {"add_item": {"circuit_board": 2, "battery": 1}},
			"choices": [{"text": "I'll take what I can get.", "next": "", "id": "end"}],
		},
		"eli_story": {
			"speaker": "Eli", "portrait_color": Color(0.5, 0.6, 0.4),
			"text": "I'm useful. That's the secret. NEXUS wants data, not corpses.\nMake yourself useful enough and maybe it won't harvest you.\n...I don't actually believe that. But it helps me sleep.",
			"effects": {"emotion": {"despair": 3, "determination": 2}},
			"choices": [{"text": "Dark. But not wrong.", "next": "", "id": "end"}],
		},
		"tech_talk": {
			"speaker": "Eli", "portrait_color": Color(0.5, 0.6, 0.4),
			"text": "Oh, you know your stuff! Yeah, I've been reverse-engineering\nNEXUS components. Check this out — a frequency scanner.\nIt can detect patrol patterns. Take it.",
			"effects": {"add_item": {"signal_jammer": 1}, "xp": 30, "emotion": {"hope": 5}},
			"choices": [{"text": "This could change everything.", "next": "", "id": "end"}],
		},
	},
	"wounded_soldier": {
		"start": {
			"speaker": "Sgt. Park", "portrait_color": Color(0.6, 0.4, 0.3),
			"text": "*cough* ...you military? No? Doesn't matter.\nThere's a bunker. Coordinates... in my vest pocket.\nI'm not gonna make it. Take the intel. It matters more than me.",
			"choices": [
				{"text": "I'll get you help—", "next": "refuse_help", "id": "help"},
				{"text": "Thank you for your service.", "next": "honor", "id": "honor"},
				{"text": "[Compassionate] I won't leave you. Rest now.", "next": "stay", "id": "compassionate", "condition": "morality_compassionate"},
			],
		},
		"refuse_help": {
			"speaker": "Sgt. Park", "portrait_color": Color(0.6, 0.4, 0.3),
			"text": "No time. The bunker has a radio. Contact... anyone.\nThere might be others out there. A resistance.\nDon't let NEXUS win.",
			"effects": {"unlock_mission": "bunker_radio", "xp": 25, "emotion": {"determination": 10}},
			"choices": [{"text": "I'll find it. I promise.", "next": "", "id": "end"}],
		},
		"honor": {
			"speaker": "Sgt. Park", "portrait_color": Color(0.6, 0.4, 0.3),
			"text": "Service... heh. I was just trying to survive like everyone else.\nHere. My dogtags. Show them at the bunker — it'll get you in.",
			"effects": {"add_item": {"scrap_metal": 3}, "xp": 20, "emotion": {"determination": 5, "despair": 3}},
			"choices": [{"text": "I'll remember you.", "next": "", "id": "end"}],
		},
		"stay": {
			"speaker": "Sgt. Park", "portrait_color": Color(0.6, 0.4, 0.3),
			"text": "...you're a good person. The world could use more of those.\nThe bunker code is 4-7-2-1. There's medical supplies inside.\nAnd... a surprise. NEXUS hasn't found it yet.",
			"effects": {"unlock_mission": "bunker_radio", "add_item": {"bandage": 3}, "xp": 40, "emotion": {"hope": 10, "determination": 8}},
			"choices": [{"text": "Rest easy, Sergeant.", "next": "", "id": "end"}],
		},
	},
}


func _ready() -> void:
	add_to_group("dialogue_system")


func start_dialogue(npc_id: String) -> void:
	if is_active:
		return
	if not dialogues.has(npc_id):
		return
	is_active = true
	_current_npc_id = npc_id
	_current_node_id = "start"
	dialogue_started.emit(npc_id)


func get_current_node() -> Dictionary:
	if not is_active or _current_npc_id.is_empty():
		return {}
	var tree: Dictionary = dialogues.get(_current_npc_id, {})
	return tree.get(_current_node_id, {})


func get_available_choices() -> Array[Dictionary]:
	var node := get_current_node()
	if node.is_empty():
		return []

	var result: Array[Dictionary] = []
	var choices: Array = node.get("choices", [])

	for choice in choices:
		if _check_condition(choice.get("condition", "")):
			result.append(choice)

	return result


func make_choice(choice_idx: int) -> void:
	var choices := get_available_choices()
	if choice_idx < 0 or choice_idx >= choices.size():
		return

	var choice: Dictionary = choices[choice_idx]
	choice_made.emit(_current_npc_id, choice.get("id", ""))

	# Move to next node
	var next_id: String = choice.get("next", "")
	if next_id.is_empty():
		# End dialogue
		_apply_node_effects(get_current_node())
		end_dialogue()
		return

	_apply_node_effects(get_current_node())
	_current_node_id = next_id


func end_dialogue() -> void:
	dialogue_ended.emit(_current_npc_id)
	is_active = false
	_current_npc_id = ""
	_current_node_id = ""


func _check_condition(condition: String) -> bool:
	if condition.is_empty():
		return true

	var emo := GameManager.emotional_state

	match condition:
		"emotion_determined":
			return emo.determination >= 60
		"emotion_fearful":
			return emo.fear >= 60
		"emotion_hopeful":
			return emo.hope >= 60
		"emotion_despairing":
			return emo.despair >= 60
		"morality_compassionate":
			return GameManager.morality.compassionate >= 5
		"morality_ruthless":
			return GameManager.morality.ruthless >= 5
		"morality_pragmatic":
			return GameManager.morality.pragmatic >= 5

	# Skill checks
	if condition.begins_with("skill_"):
		var skill_id: String = condition.substr(6)
		var st := get_tree().get_first_node_in_group("skill_tree")
		if st and st.has_method("has_skill"):
			return st.has_skill(skill_id)

	return true


func _apply_node_effects(node: Dictionary) -> void:
	var effects: Dictionary = node.get("effects", {})
	if effects.is_empty():
		return

	# Add items
	if effects.has("add_item"):
		var inv := get_tree().get_first_node_in_group("inventory")
		if inv and inv.has_method("add_item"):
			for item_id: String in effects.add_item:
				inv.add_item(item_id, int(effects.add_item[item_id]))

	# Emotions
	if effects.has("emotion"):
		for emo_key: String in effects.emotion:
			GameManager.adjust_emotion(emo_key, int(effects.emotion[emo_key]))

	# XP
	if effects.has("xp"):
		GameManager.add_xp(int(effects.xp))
