extends Node

## Crafting system — recipes with tech tiers.

signal recipe_crafted(item_id: String)

# Recipes: {result_id: {ingredients: {item_id: count}, tier: int}}
var recipes: Dictionary = {
	"bandage": {
		"ingredients": {"scrap_metal": 1},
		"tier": 0, "name": "Bandage"
	},
	"makeshift_blade": {
		"ingredients": {"scrap_metal": 5, "wire": 2},
		"tier": 1, "name": "Makeshift Blade"
	},
	"emp_device": {
		"ingredients": {"circuit_board": 2, "battery": 1, "wire": 3},
		"tier": 2, "name": "EMP Device"
	},
	"reinforced_blade": {
		"ingredients": {"scrap_metal": 10, "circuit_board": 2, "wire": 5},
		"tier": 2, "name": "Reinforced Blade"
	},
	"leather_armor": {
		"ingredients": {"scrap_metal": 8},
		"tier": 1, "name": "Leather Armor"
	},
	"signal_jammer": {
		"ingredients": {"circuit_board": 3, "battery": 2, "wire": 5},
		"tier": 2, "name": "Signal Jammer"
	},
	"nexus_blade": {
		"ingredients": {"circuit_board": 5, "battery": 3, "scrap_metal": 10, "wire": 8},
		"tier": 3, "name": "NEXUS Blade"
	},
	"nexus_shield": {
		"ingredients": {"circuit_board": 4, "battery": 4, "scrap_metal": 8},
		"tier": 3, "name": "NEXUS Shield"
	},
	"arrow": {
		"ingredients": {"scrap_metal": 1},
		"tier": 0, "name": "Arrow x5", "amount": 5
	},
	"cooked_meat": {
		"ingredients": {"canned_food": 1},
		"tier": 0, "name": "Cooked Meat"
	},
	"antibiotics": {
		"ingredients": {"scrap_metal": 2, "wire": 1},
		"tier": 1, "name": "Antibiotics"
	},
	"splint": {
		"ingredients": {"scrap_metal": 3, "wire": 2},
		"tier": 1, "name": "Splint"
	},
	"burn_cream": {
		"ingredients": {"scrap_metal": 2, "bandage": 1},
		"tier": 1, "name": "Burn Cream"
	},
	"purified_water": {
		"ingredients": {"water_bottle": 1, "scrap_metal": 1},
		"tier": 1, "name": "Purified Water"
	},
	"thermal_wrap": {
		"ingredients": {"scrap_metal": 5, "wire": 3},
		"tier": 2, "name": "Thermal Wrap"
	},
	"sleeping_bag": {
		"ingredients": {"scrap_metal": 4, "wire": 2},
		"tier": 2, "name": "Sleeping Bag"
	},
}

var inventory: Node = null # Set by main scene


func can_craft(recipe_id: String) -> bool:
	if not inventory or not recipes.has(recipe_id):
		return false
	var recipe: Dictionary = recipes[recipe_id]
	for ingredient_id: String in recipe.ingredients:
		var needed: int = recipe.ingredients[ingredient_id]
		if not inventory.has_item(ingredient_id, needed):
			return false
	return true


func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false

	var recipe: Dictionary = recipes[recipe_id]
	# Remove ingredients
	for ingredient_id: String in recipe.ingredients:
		var needed: int = recipe.ingredients[ingredient_id]
		inventory.remove_item(ingredient_id, needed)

	# Add result
	var amount: int = recipe.get("amount", 1)
	inventory.add_item(recipe_id, amount)

	AudioManager.play_sfx("levelup")
	recipe_crafted.emit(recipe_id)
	return true


func get_available_recipes() -> Array[String]:
	var available: Array[String] = []
	for recipe_id: String in recipes:
		if can_craft(recipe_id):
			available.append(recipe_id)
	return available
