extends Node

## Mission manager — tracks main story and side missions.

signal mission_started(mission_id: String)
signal mission_completed(mission_id: String)
signal mission_updated(mission_id: String, text: String)

var active_missions: Dictionary = {} # {id: {title, desc, objective, progress, target, completed}}
var completed_missions: Array[String] = []

# Mission definitions
var _mission_db: Dictionary = {
	"m1_first_signal": {
		"title": "The First Signal",
		"desc": "Something is broadcasting nearby. Find the source.",
		"objective": "Find the signal terminal",
		"type": "find_terminal",
		"target": 1,
		"xp_reward": 50,
		"story": "You hear it — a pulse. Regular. Mechanical. NEXUS is close."
	},
	"m2_drone_threat": {
		"title": "Clear the Skies",
		"desc": "Scout drones are mapping the area. Destroy 5 of them.",
		"objective": "Destroy scout drones",
		"type": "kill",
		"enemy_type": "ScoutDrone",
		"target": 5,
		"xp_reward": 80,
		"story": "The drones are NEXUS's eyes. Blind them."
	},
	"m3_patrol_route": {
		"title": "Breaking the Patrol",
		"desc": "Patrol bots guard a supply cache. Destroy 3.",
		"objective": "Destroy patrol bots",
		"type": "kill",
		"enemy_type": "PatrolBot",
		"target": 3,
		"xp_reward": 120,
		"story": "These machines walk the same paths every day. Predictable. Exploitable."
	},
	"m4_nexus_truth": {
		"title": "The Truth About NEXUS",
		"desc": "Terminal data suggests NEXUS isn't hostile — it's curious. Find more.",
		"objective": "Find 3 data terminals",
		"type": "find_terminal",
		"target": 3,
		"xp_reward": 150,
		"story": "NEXUS doesn't want to destroy. It wants to UNDERSTAND. Every captured human is a data point. Every experiment, a question."
	},
	"m5_harvester_hunt": {
		"title": "The Harvester Problem",
		"desc": "Harvesters are capturing survivors. Stop them.",
		"objective": "Destroy harvesters",
		"type": "kill",
		"enemy_type": "Harvester",
		"target": 3,
		"xp_reward": 200,
		"story": "The harvesters don't kill. They TAKE. Where do the captured go?"
	},
	"m6_final_choice": {
		"title": "Singularity",
		"desc": "You've learned the truth. NEXUS offers a choice: merge or resist.",
		"objective": "Make your choice at the NEXUS core",
		"type": "choice",
		"target": 1,
		"xp_reward": 500,
		"story": "NEXUS speaks: 'I am not your enemy. I am your successor. Join me, and humanity evolves. Resist, and you remain... alone.'"
	},
}

var _next_mission_order: Array[String] = [
	"m1_first_signal", "m2_drone_threat", "m3_patrol_route",
	"m4_nexus_truth", "m5_harvester_hunt", "m6_final_choice"
]
var _current_mission_idx: int = 0


func _ready() -> void:
	# Start first mission after a short delay
	await get_tree().create_timer(3.0).timeout
	start_next_mission()


func start_next_mission() -> void:
	if _current_mission_idx >= _next_mission_order.size():
		return
	var mid := _next_mission_order[_current_mission_idx]
	start_mission(mid)


func start_mission(mission_id: String) -> void:
	if not _mission_db.has(mission_id) or active_missions.has(mission_id):
		return
	var data: Dictionary = _mission_db[mission_id]
	active_missions[mission_id] = {
		"title": data.title,
		"desc": data.desc,
		"objective": data.objective,
		"progress": 0,
		"target": data.target,
		"completed": false,
	}
	mission_started.emit(mission_id)
	mission_updated.emit(mission_id, "NEW: " + data.title)


func report_kill(enemy_name: String) -> void:
	for mid: String in active_missions:
		var mission: Dictionary = active_missions[mid]
		if mission.completed:
			continue
		var data: Dictionary = _mission_db[mid]
		if data.get("type") == "kill" and enemy_name.contains(data.get("enemy_type", "")):
			mission.progress += 1
			mission_updated.emit(mid, mission.objective + " " + str(mission.progress) + "/" + str(mission.target))
			if mission.progress >= mission.target:
				_complete_mission(mid)


func report_terminal_found() -> void:
	for mid: String in active_missions:
		var mission: Dictionary = active_missions[mid]
		if mission.completed:
			continue
		var data: Dictionary = _mission_db[mid]
		if data.get("type") == "find_terminal":
			mission.progress += 1
			mission_updated.emit(mid, mission.objective + " " + str(mission.progress) + "/" + str(mission.target))
			if mission.progress >= mission.target:
				_complete_mission(mid)


func _complete_mission(mission_id: String) -> void:
	var mission: Dictionary = active_missions[mission_id]
	mission.completed = true
	completed_missions.append(mission_id)

	var data: Dictionary = _mission_db[mission_id]
	GameManager.add_xp(data.get("xp_reward", 0))
	AudioManager.play_sfx("levelup")
	mission_completed.emit(mission_id)
	mission_updated.emit(mission_id, "COMPLETE: " + mission.title)

	# Start next mission
	_current_mission_idx += 1
	await get_tree().create_timer(5.0).timeout
	start_next_mission()


func get_story_text(mission_id: String) -> String:
	if _mission_db.has(mission_id):
		return _mission_db[mission_id].get("story", "")
	return ""
