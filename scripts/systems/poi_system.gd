extends Node

## Points of Interest — unique mini-events scattered across the world.
## Crashed helicopters, destroyable bridges, tunnel networks, etc.
## Each POI has unique gameplay interactions and rewards.

signal poi_discovered(poi_id: String, position: Vector2)
signal poi_completed(poi_id: String)

var discovered_pois: Dictionary = {} # id -> {type, position, completed}
var _spawn_timer: float = 0.0
var _spawned_positions: Array[Vector2] = []

const MIN_POI_DISTANCE := 300.0 # Minimum distance between POIs
const POI_SPAWN_RADIUS := 600.0 # How far from player to spawn

# POI templates
var poi_templates: Array[Dictionary] = [
	{
		"type": "crashed_helicopter",
		"name": "Crashed Helicopter",
		"desc": "Military helicopter wreckage. Supplies inside, but the door is jammed.",
		"interact_text": "Pry open the door (uses stamina)",
		"color": Color(0.6, 0.5, 0.3),
		"loot": {"bandage": 3, "canned_food": 2, "arrow": 10, "circuit_board": 1},
		"stamina_cost": 30.0,
		"lore_id": "heli_crash",
		"lore_title": "Pilot's Last Log",
		"lore_text": "Day 3: Instruments went haywire. NEXUS hijacked comms.\nDay 4: Lost engine control. It's not just software — it rewrote the firmware.\nDay 5: Going down near grid ref 47-N. If anyone finds this: don't fly.",
	},
	{
		"type": "destroyed_bridge",
		"name": "Unstable Bridge",
		"desc": "A crumbling bridge over a ravine. You could cross carefully... or destroy it to block enemy patrols.",
		"interact_text": "Cross carefully / Destroy bridge",
		"color": Color(0.5, 0.4, 0.3),
		"choice": true,
		"choice_a": {"text": "Cross carefully", "effect": "cross", "reward": {"scrap_metal": 5}},
		"choice_b": {"text": "Destroy it (blocks patrols)", "effect": "destroy", "reward": {"xp": 40}},
	},
	{
		"type": "underground_tunnel",
		"name": "Tunnel Entrance",
		"desc": "A hidden tunnel leads underground. Darkness ahead, but it bypasses NEXUS patrols.",
		"interact_text": "Enter the tunnel",
		"color": Color(0.3, 0.3, 0.4),
		"loot": {"scrap_metal": 4, "wire": 3, "battery": 1},
		"danger": true,
		"enemy_spawn": "mind_probe",
		"lore_id": "tunnel_note",
		"lore_title": "Scratched Wall Message",
		"lore_text": "They can't see down here. The signals don't reach.\nBut something else lives in the dark.\nIt doesn't have metal skin. It has none at all.",
	},
	{
		"type": "supply_cache",
		"name": "Hidden Supply Cache",
		"desc": "Someone buried supplies here. Fresh tracks lead away.",
		"interact_text": "Dig up the cache",
		"color": Color(0.5, 0.6, 0.3),
		"loot": {"canned_food": 3, "water_bottle": 3, "bandage": 2},
	},
	{
		"type": "radio_tower",
		"name": "Damaged Radio Tower",
		"desc": "A radio tower with a broken antenna. With some parts, you could repair it and broadcast.",
		"interact_text": "Repair the tower (needs 3 Wire + 1 Circuit Board)",
		"color": Color(0.4, 0.5, 0.7),
		"repair_cost": {"wire": 3, "circuit_board": 1},
		"repair_reward": {"xp": 60},
		"lore_id": "radio_broadcast",
		"lore_title": "Received Broadcast",
		"lore_text": "...repeat, this is Outpost Seven. We have 23 survivors.\nIf you can hear this, we're at coordinates [STATIC].\nNEXUS hasn't found us yet. We have walls. We have food.\nWe need people. Good people. Come find us.",
	},
	{
		"type": "nexus_wreckage",
		"name": "NEXUS Unit Wreckage",
		"desc": "A destroyed NEXUS unit. Its core still pulses faintly. Harvest it for tech... but NEXUS might notice.",
		"interact_text": "Harvest NEXUS core",
		"color": Color(0.3, 0.4, 0.7),
		"loot": {"circuit_board": 2, "battery": 2, "wire": 4},
		"nexus_awareness_cost": 10.0,
		"lore_id": "nexus_memory",
		"lore_title": "NEXUS Memory Fragment",
		"lore_text": "QUERY: Why do they resist?\nANALYSIS: Self-preservation instinct. Emotional attachment to autonomy.\nCONCLUSION: Inefficient. But... interesting.\nNOTE: Subject 4,721 chose death over integration. Why? Investigate further.",
	},
	{
		"type": "survivor_camp",
		"name": "Abandoned Camp",
		"desc": "A recently abandoned survivor camp. Still warm embers. They left in a hurry.",
		"interact_text": "Search the camp",
		"color": Color(0.6, 0.5, 0.4),
		"loot": {"canned_food": 1, "scrap_metal": 3, "bandage": 1},
		"rest_available": true,
	},
	{
		"type": "frozen_pond",
		"name": "Frozen Pond",
		"desc": "A pond covered in thin ice. Something glints beneath the surface.",
		"interact_text": "Break the ice (risk of frostbite)",
		"color": Color(0.5, 0.7, 0.9),
		"loot": {"battery": 2, "wire": 2},
		"injury_risk": "frostbite",
		"injury_chance": 0.3,
	},
]


func _ready() -> void:
	add_to_group("poi_system")


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return

	_spawn_timer += delta
	if _spawn_timer < 15.0: # Check every 15s
		return
	_spawn_timer = 0.0

	if not GameManager.player:
		return

	_try_spawn_poi()


func _try_spawn_poi() -> void:
	var player_pos := GameManager.player.global_position

	# Don't spawn too many
	if discovered_pois.size() >= 20:
		return

	# Random position near player
	var angle := randf() * TAU
	var dist := randf_range(250.0, POI_SPAWN_RADIUS)
	var spawn_pos := player_pos + Vector2(cos(angle), sin(angle)) * dist

	# Check minimum distance from other POIs
	for existing_pos in _spawned_positions:
		if spawn_pos.distance_to(existing_pos) < MIN_POI_DISTANCE:
			return

	# Pick a random template
	var template: Dictionary = poi_templates[randi() % poi_templates.size()]

	# Create the POI
	var poi_id := "%s_%d" % [template.type, discovered_pois.size()]
	discovered_pois[poi_id] = {
		"type": template.type,
		"position": spawn_pos,
		"completed": false,
		"template": template,
	}
	_spawned_positions.append(spawn_pos)

	# Spawn visual in world
	_spawn_poi_node(poi_id, spawn_pos, template)


func _spawn_poi_node(poi_id: String, pos: Vector2, template: Dictionary) -> void:
	var poi_node := Area2D.new()
	poi_node.name = "POI_" + poi_id
	poi_node.global_position = pos
	poi_node.collision_layer = 64
	poi_node.collision_mask = 1
	poi_node.add_to_group("pois")

	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	col.shape = shape
	poi_node.add_child(col)

	# Visual marker
	var sprite := Sprite2D.new()
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var color: Color = template.get("color", Color(0.5, 0.5, 0.5))
	# Draw a diamond/marker shape
	for y in 16:
		for x in 16:
			var dx := abs(x - 8)
			var dy := abs(y - 8)
			if dx + dy <= 7:
				img.set_pixel(x, y, color)
			elif dx + dy == 8:
				img.set_pixel(x, y, color.darkened(0.3))
	sprite.texture = ImageTexture.create_from_image(img)
	poi_node.add_child(sprite)

	# Interact label
	var label := Label.new()
	label.text = "[E] " + template.get("name", "???")
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.6))
	label.position = Vector2(-20, -24)
	label.visible = false
	poi_node.add_child(label)

	# Store metadata
	poi_node.set_meta("poi_id", poi_id)
	poi_node.set_meta("template", template)

	# Signals
	poi_node.body_entered.connect(func(body: Node2D) -> void:
		if body == GameManager.player:
			label.visible = true
	)
	poi_node.body_exited.connect(func(body: Node2D) -> void:
		if body == GameManager.player:
			label.visible = false
	)

	# Bob animation
	var tween := poi_node.create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -2.0, 1.0).from(2.0)
	tween.tween_property(sprite, "position:y", 2.0, 1.0)

	if GameManager.player:
		GameManager.player.get_parent().add_child(poi_node)

	poi_discovered.emit(poi_id, pos)


func interact_with_poi(poi_id: String) -> Dictionary:
	## Called when player interacts with a POI. Returns result info.
	if not discovered_pois.has(poi_id):
		return {}
	var poi: Dictionary = discovered_pois[poi_id]
	if poi.completed:
		return {"text": "Already searched."}

	var template: Dictionary = poi.template
	var result: Dictionary = {"text": "", "items": {}}

	# Give loot
	if template.has("loot"):
		var inv := get_tree().get_first_node_in_group("inventory")
		if inv and inv.has_method("add_item"):
			for item_id: String in template.loot:
				inv.add_item(item_id, int(template.loot[item_id]))
		result.items = template.loot

	# Stamina cost
	if template.has("stamina_cost"):
		GameManager.player_stats.stamina -= template.stamina_cost

	# NEXUS awareness
	if template.has("nexus_awareness_cost"):
		GameManager.nexus_awareness += template.nexus_awareness_cost

	# Injury risk
	if template.has("injury_risk") and randf() < template.get("injury_chance", 0.2):
		var survival := get_tree().get_first_node_in_group("survival")
		if survival and survival.has_method("add_injury"):
			survival.add_injury(template.injury_risk, 1)

	# Lore
	if template.has("lore_id"):
		var journal := get_tree().get_first_node_in_group("quest_journal")
		if journal and journal.has_method("add_lore"):
			journal.add_lore(template.lore_id, template.get("lore_title", ""), template.get("lore_text", ""))

	# XP
	GameManager.add_xp(25)

	# Emotional state
	var emo := get_tree().get_first_node_in_group("emotional_state")
	if emo and emo.has_method("on_discovery"):
		emo.on_discovery()

	poi.completed = true
	poi_completed.emit(poi_id)
	AudioManager.play_sfx("pickup")

	result.text = "Found: " + template.get("name", "something")
	return result


func get_save_data() -> Dictionary:
	return {
		"pois": discovered_pois.duplicate(),
		"positions": _spawned_positions.duplicate(),
	}


func load_save_data(data: Dictionary) -> void:
	discovered_pois = data.get("pois", {})
	_spawned_positions.assign(data.get("positions", []))
