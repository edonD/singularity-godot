extends Node

## Quest Journal — tracks active/completed quests, objectives, and discovered lore.

signal quest_added(quest_id: String)
signal quest_completed(quest_id: String)
signal objective_completed(quest_id: String, obj_idx: int)
signal lore_discovered(lore_id: String)

var active_quests: Dictionary = {} # quest_id -> {data + state}
var completed_quests: Array[String] = []
var discovered_lore: Array[Dictionary] = [] # [{id, title, text, day}]

# Quest definitions
var quest_db: Dictionary = {
	"first_signal": {
		"title": "The First Signal",
		"desc": "A broadcast repeats on an old frequency. Something — or someone — is out there.",
		"category": "main",
		"objectives": [
			"Find the source of the broadcast",
			"Investigate the signal origin",
			"Decide: respond or stay silent",
		],
		"xp_reward": 100,
	},
	"clear_the_skies": {
		"title": "Clear the Skies",
		"desc": "Scout drones are mapping your area. Destroy them before NEXUS locks your position.",
		"category": "main",
		"objectives": [
			"Destroy 5 Scout Drones",
			"Find and disable the relay beacon",
		],
		"xp_reward": 80,
	},
	"breaking_patrol": {
		"title": "Breaking the Patrol",
		"desc": "Patrol Bots guard a supply cache. Take them out to access vital resources.",
		"category": "main",
		"objectives": [
			"Destroy 3 Patrol Bots",
			"Secure the supply cache",
		],
		"xp_reward": 120,
	},
	"truth_about_nexus": {
		"title": "The Truth About NEXUS",
		"desc": "Data terminals scattered across NEXUS outposts contain fragments of the truth.",
		"category": "main",
		"objectives": [
			"Access NEXUS Terminal Alpha",
			"Access NEXUS Terminal Beta",
			"Access NEXUS Terminal Gamma",
			"Piece together the truth",
		],
		"xp_reward": 200,
	},
	"harvester_problem": {
		"title": "The Harvester Problem",
		"desc": "Harvesters are capturing survivors. Stop them before there's no one left to save.",
		"category": "main",
		"objectives": [
			"Destroy 2 Harvesters",
			"Free the captured survivors",
		],
		"xp_reward": 150,
	},
	"singularity": {
		"title": "Singularity",
		"desc": "The final choice. NEXUS offers a deal. What does it mean to be human?",
		"category": "main",
		"objectives": [
			"Reach the NEXUS Core",
			"Make your final choice",
		],
		"xp_reward": 500,
	},
	"military_cache": {
		"title": "The Military Cache",
		"desc": "Anna mentioned a military supply cache to the north. Could be worth the risk.",
		"category": "side",
		"objectives": [
			"Find the military cache",
			"Defeat the guards",
			"Loot the supplies",
		],
		"xp_reward": 60,
	},
	"bunker_radio": {
		"title": "The Bunker Radio",
		"desc": "Sgt. Park's last wish — reach the bunker and contact potential survivors.",
		"category": "side",
		"objectives": [
			"Find the bunker entrance",
			"Enter code 4-7-2-1",
			"Activate the radio",
		],
		"xp_reward": 80,
	},
	"scavenger_run": {
		"title": "Scavenger Run",
		"desc": "Supplies are running low. Scavenge materials from the nearby ruins.",
		"category": "side",
		"objectives": [
			"Collect 10 Scrap Metal",
			"Collect 3 Circuit Boards",
			"Return to shelter",
		],
		"xp_reward": 40,
	},
	"night_watch": {
		"title": "Night Watch",
		"desc": "Survive a full night cycle without returning to shelter. Test your endurance.",
		"category": "side",
		"objectives": [
			"Survive from dusk to dawn in the open",
			"Kill any enemies that attack",
		],
		"xp_reward": 50,
	},
}


func _ready() -> void:
	add_to_group("quest_journal")
	# Start with first quest
	add_quest("first_signal")


func add_quest(quest_id: String) -> void:
	if active_quests.has(quest_id) or quest_id in completed_quests:
		return
	if not quest_db.has(quest_id):
		return

	var qdata: Dictionary = quest_db[quest_id].duplicate()
	qdata["obj_completed"] = []
	for i in qdata.objectives.size():
		qdata.obj_completed.append(false)

	active_quests[quest_id] = qdata
	quest_added.emit(quest_id)
	AudioManager.play_sfx("click")


func complete_objective(quest_id: String, obj_idx: int) -> void:
	if not active_quests.has(quest_id):
		return
	var quest: Dictionary = active_quests[quest_id]
	if obj_idx < 0 or obj_idx >= quest.obj_completed.size():
		return
	if quest.obj_completed[obj_idx]:
		return

	quest.obj_completed[obj_idx] = true
	objective_completed.emit(quest_id, obj_idx)
	AudioManager.play_sfx("pickup")

	# Check if all objectives done
	var all_done := true
	for done: bool in quest.obj_completed:
		if not done:
			all_done = false
			break

	if all_done:
		complete_quest(quest_id)


func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	var quest: Dictionary = active_quests[quest_id]
	GameManager.add_xp(quest.get("xp_reward", 0))
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	quest_completed.emit(quest_id)
	AudioManager.play_sfx("levelup")

	# Emotional boost
	GameManager.adjust_emotion("determination", 5)
	GameManager.adjust_emotion("hope", 5)


func add_lore(lore_id: String, title: String, text: String) -> void:
	# Check for duplicates
	for entry in discovered_lore:
		if entry.id == lore_id:
			return

	discovered_lore.append({
		"id": lore_id,
		"title": title,
		"text": text,
		"day": GameManager.day,
	})
	lore_discovered.emit(lore_id)
	AudioManager.play_sfx("click")

	GameManager.adjust_emotion("hope", 3)
	GameManager.adjust_emotion("determination", 2)


func get_save_data() -> Dictionary:
	return {
		"active": active_quests.duplicate(),
		"completed": completed_quests.duplicate(),
		"lore": discovered_lore.duplicate(),
	}


func load_save_data(data: Dictionary) -> void:
	active_quests = data.get("active", {})
	completed_quests.assign(data.get("completed", []))
	discovered_lore.assign(data.get("lore", []))
