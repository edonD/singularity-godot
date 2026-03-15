extends Node2D

## Main scene controller — sets up the game world and wires systems.

@onready var inventory: Node = $Systems/Inventory
@onready var crafting: Node = $Systems/Crafting
@onready var inventory_ui: CanvasLayer = $InventoryUI


func _ready() -> void:
	# Wire systems together
	crafting.inventory = inventory
	inventory_ui.inventory = inventory
	inventory_ui.crafting = crafting
	inventory.add_to_group("inventory")

	# Give player some starter items
	inventory.add_item("bandage", 3)
	inventory.add_item("canned_food", 2)
	inventory.add_item("water_bottle", 2)
	inventory.add_item("scrap_metal", 5)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameManager.toggle_pause()
