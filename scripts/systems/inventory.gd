extends Node

## Inventory system — grid-based with weight and stacking.

signal inventory_changed
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)

const MAX_SLOTS := 20
const MAX_WEIGHT := 50.0

var slots: Array[Dictionary] = [] # [{id, amount}]
var _item_db: Dictionary = {} # Loaded item definitions


func _ready() -> void:
	slots.resize(MAX_SLOTS)
	for i in MAX_SLOTS:
		slots[i] = {}
	_init_item_database()


func _init_item_database() -> void:
	# Item definitions: {name, description, weight, max_stack, type, stats}
	_item_db = {
		"scrap_metal": {
			"name": "Scrap Metal", "desc": "Twisted metal. Useful for crafting.",
			"weight": 0.5, "max_stack": 20, "type": "material",
			"color": Color(0.5, 0.5, 0.55)
		},
		"circuit_board": {
			"name": "Circuit Board", "desc": "Salvaged electronics.",
			"weight": 0.3, "max_stack": 10, "type": "material",
			"color": Color(0.2, 0.6, 0.3)
		},
		"battery": {
			"name": "Battery", "desc": "Still holds a charge.",
			"weight": 0.8, "max_stack": 5, "type": "material",
			"color": Color(0.7, 0.7, 0.2)
		},
		"wire": {
			"name": "Wire", "desc": "Copper wiring.",
			"weight": 0.2, "max_stack": 30, "type": "material",
			"color": Color(0.8, 0.4, 0.2)
		},
		"bandage": {
			"name": "Bandage", "desc": "Restores 25 HP.",
			"weight": 0.2, "max_stack": 10, "type": "consumable",
			"color": Color(0.9, 0.9, 0.9), "heal": 25
		},
		"canned_food": {
			"name": "Canned Food", "desc": "Restores 30 hunger.",
			"weight": 0.5, "max_stack": 5, "type": "consumable",
			"color": Color(0.6, 0.5, 0.3), "hunger": 30
		},
		"water_bottle": {
			"name": "Water Bottle", "desc": "Restores 30 thirst.",
			"weight": 0.4, "max_stack": 5, "type": "consumable",
			"color": Color(0.3, 0.5, 0.8), "thirst": 30
		},
		"cooked_meat": {
			"name": "Cooked Meat", "desc": "Restores 50 hunger.",
			"weight": 0.4, "max_stack": 5, "type": "consumable",
			"color": Color(0.6, 0.3, 0.2), "hunger": 50
		},
		"emp_device": {
			"name": "EMP Device", "desc": "Stuns nearby machines.",
			"weight": 1.5, "max_stack": 3, "type": "tool",
			"color": Color(0.3, 0.3, 0.8)
		},
		"signal_jammer": {
			"name": "Signal Jammer", "desc": "Blocks NEXUS detection.",
			"weight": 2.0, "max_stack": 1, "type": "tool",
			"color": Color(0.5, 0.2, 0.6)
		},
		"makeshift_blade": {
			"name": "Makeshift Blade", "desc": "+5 attack damage.",
			"weight": 1.0, "max_stack": 1, "type": "weapon",
			"color": Color(0.6, 0.6, 0.65), "attack_bonus": 5
		},
		"reinforced_blade": {
			"name": "Reinforced Blade", "desc": "+12 attack damage.",
			"weight": 1.5, "max_stack": 1, "type": "weapon",
			"color": Color(0.7, 0.7, 0.75), "attack_bonus": 12
		},
		"nexus_blade": {
			"name": "NEXUS Blade", "desc": "+25 attack. Hums with energy.",
			"weight": 1.0, "max_stack": 1, "type": "weapon",
			"color": Color(0.2, 0.8, 1.0), "attack_bonus": 25
		},
		"leather_armor": {
			"name": "Leather Armor", "desc": "+3 defense.",
			"weight": 2.0, "max_stack": 1, "type": "armor",
			"color": Color(0.5, 0.35, 0.2), "defense_bonus": 3
		},
		"nexus_shield": {
			"name": "NEXUS Shield", "desc": "+10 defense. Energy barrier.",
			"weight": 1.5, "max_stack": 1, "type": "armor",
			"color": Color(0.2, 0.6, 1.0), "defense_bonus": 10
		},
		"arrow": {
			"name": "Arrow", "desc": "Ammunition for bow.",
			"weight": 0.1, "max_stack": 50, "type": "ammo",
			"color": Color(0.5, 0.4, 0.3)
		},
	}


func get_item_data(item_id: String) -> Dictionary:
	return _item_db.get(item_id, {})


func get_total_weight() -> float:
	var total := 0.0
	for slot in slots:
		if slot.is_empty():
			continue
		var data := get_item_data(slot.id)
		total += data.get("weight", 0.0) * slot.amount
	return total


func add_item(item_id: String, amount: int = 1) -> bool:
	var data := get_item_data(item_id)
	if data.is_empty():
		return false

	var remaining := amount

	# Try to stack into existing slots first
	for i in MAX_SLOTS:
		if remaining <= 0:
			break
		if not slots[i].is_empty() and slots[i].id == item_id:
			var max_stack: int = data.get("max_stack", 1)
			var space: int = max_stack - slots[i].amount
			if space > 0:
				var to_add := mini(remaining, space)
				slots[i].amount += to_add
				remaining -= to_add

	# Put remainder in empty slots
	for i in MAX_SLOTS:
		if remaining <= 0:
			break
		if slots[i].is_empty():
			var max_stack: int = data.get("max_stack", 1)
			var to_add := mini(remaining, max_stack)
			slots[i] = {"id": item_id, "amount": to_add}
			remaining -= to_add

	if remaining < amount:
		inventory_changed.emit()
		item_added.emit(item_id, amount - remaining)
		return remaining == 0
	return false


func remove_item(item_id: String, amount: int = 1) -> bool:
	var remaining := amount
	for i in range(MAX_SLOTS - 1, -1, -1):
		if remaining <= 0:
			break
		if not slots[i].is_empty() and slots[i].id == item_id:
			var to_remove := mini(remaining, slots[i].amount)
			slots[i].amount -= to_remove
			remaining -= to_remove
			if slots[i].amount <= 0:
				slots[i] = {}

	if remaining < amount:
		inventory_changed.emit()
		item_removed.emit(item_id, amount - remaining)
		return remaining == 0
	return false


func has_item(item_id: String, amount: int = 1) -> bool:
	var count := 0
	for slot in slots:
		if not slot.is_empty() and slot.id == item_id:
			count += slot.amount
	return count >= amount


func get_item_count(item_id: String) -> int:
	var count := 0
	for slot in slots:
		if not slot.is_empty() and slot.id == item_id:
			count += slot.amount
	return count


func use_item(slot_idx: int) -> bool:
	if slot_idx < 0 or slot_idx >= MAX_SLOTS:
		return false
	if slots[slot_idx].is_empty():
		return false

	var item_id: String = slots[slot_idx].id
	var data := get_item_data(item_id)
	var s := GameManager.player_stats

	match data.get("type", ""):
		"consumable":
			if data.has("heal"):
				s.hp = mini(s.hp + int(data.heal), s.max_hp)
			if data.has("hunger"):
				s.hunger = minf(s.hunger + float(data.hunger), s.max_hunger)
			if data.has("thirst"):
				s.thirst = minf(s.thirst + float(data.thirst), s.max_thirst)
			AudioManager.play_sfx("pickup")
			remove_item(item_id, 1)
			return true
		"weapon":
			s.attack = 10 + int(data.get("attack_bonus", 0))
			AudioManager.play_sfx("click")
			return true
		"armor":
			s.defense = 5 + int(data.get("defense_bonus", 0))
			AudioManager.play_sfx("click")
			return true

	return false
