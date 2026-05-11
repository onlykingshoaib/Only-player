## Inventory.gd
## Weapon and ammo management system with pickup signals
## Optimized for fast item lookup and efficient slot management

extends Node3D

# Inventory configuration
@export var max_weapon_slots: int = 3
@export var max_health_items: int = 5
@export var max_ammo_items: int = 10

# Item type constants
enum ItemType {
	WEAPON,
	AMMO,
	HEALTH,
	UTILITY
}

# Weapon configuration
var weapons_data: Dictionary = {
	"assault_rifle": {
		"name": "Assault Rifle",
		"damage": 25.0,
		"fire_rate": 0.1,
		"ammo_capacity": 300,
		"type": ItemType.WEAPON
	},
	"sniper_rifle": {
		"name": "Sniper Rifle",
		"damage": 75.0,
		"fire_rate": 1.5,
		"ammo_capacity": 30,
		"type": ItemType.WEAPON
	},
	"shotgun": {
		"name": "Shotgun",
		"damage": 60.0,
		"fire_rate": 0.8,
		"ammo_capacity": 24,
		"type": ItemType.WEAPON
	}
}

# Ammo types
var ammo_data: Dictionary = {
	"rifle_ammo": {
		"name": "Rifle Ammo",
		"weapon_type": "assault_rifle",
		"amount": 30,
		"type": ItemType.AMMO
	},
	"sniper_ammo": {
		"name": "Sniper Ammo",
		"weapon_type": "sniper_rifle",
		"amount": 5,
		"type": ItemType.AMMO
	},
	"shotgun_ammo": {
		"name": "Shotgun Ammo",
		"weapon_type": "shotgun",
		"amount": 8,
		"type": ItemType.AMMO
	}
}

# Health items
var health_items: Dictionary = {
	"bandage": {
		"name": "Bandage",
		"heal_amount": 25.0,
		"type": ItemType.HEALTH
	},
	"medkit": {
		"name": "Medical Kit",
		"heal_amount": 75.0,
		"type": ItemType.HEALTH
	}
}

# Inventory structure
var inventory: Array[Dictionary] = []
var equipped_weapon_index: int = -1

# Signals
signal item_picked_up(item: Dictionary)
signal weapon_equipped(weapon: Dictionary)
signal weapon_swapped(from_weapon: Dictionary, to_weapon: Dictionary)
signal ammo_added(ammo_type: String, amount: int)
signal health_used(heal_amount: float)
signal inventory_updated

func _ready() -> void:
	# Initialize empty inventory
	inventory.clear()

## Add item to inventory
func add_item(item_id: String, quantity: int = 1) -> bool:
	var item = _get_item_data(item_id)
	if not item:
		push_error("Item not found: " + item_id)
		return false
	
	# Check inventory space based on item type (count by type)
	var type_count = 0
	for slot in inventory:
		if slot.type == item.type:
			type_count += 1
	
	match item.type:
		ItemType.WEAPON:
			if type_count >= max_weapon_slots:
				push_warning("Weapon slots full")
				return false
		ItemType.AMMO:
			if type_count >= max_ammo_items:
				push_warning("Ammo slots full")
				return false
		ItemType.HEALTH:
			if type_count >= max_health_items:
				push_warning("Health items full")
				return false
	
	# Create inventory slot
	var slot: Dictionary = item.duplicate()
	slot["id"] = item_id
	slot["quantity"] = quantity
	slot["slot_index"] = inventory.size()
	
	inventory.append(slot)
	emit_signal("item_picked_up", slot)
	emit_signal("inventory_updated")
	
	return true

## Remove item from inventory
func remove_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= inventory.size():
		return false
	
	var item = inventory[slot_index]
	inventory.remove_at(slot_index)
	
	# Adjust equipped weapon if removed
	if equipped_weapon_index == slot_index:
		equipped_weapon_index = -1
	
	emit_signal("inventory_updated")
	return true

## Equip a weapon by slot index
func equip_weapon(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= inventory.size():
		return false
	
	var item = inventory[slot_index]
	if item.type != ItemType.WEAPON:
		push_error("Cannot equip non-weapon item")
		return false
	
	var previous_weapon = null
	if equipped_weapon_index >= 0:
		previous_weapon = inventory[equipped_weapon_index]
	
	equipped_weapon_index = slot_index
	emit_signal("weapon_equipped", item)
	
	if previous_weapon:
		emit_signal("weapon_swapped", previous_weapon, item)
	
	emit_signal("inventory_updated")
	return true

## Get equipped weapon
func get_equipped_weapon() -> Dictionary:
	if equipped_weapon_index < 0 or equipped_weapon_index >= inventory.size():
		return {}
	return inventory[equipped_weapon_index]

## Add ammo for a weapon type
func add_ammo(weapon_type: String, amount: int) -> void:
	# Find weapon of this type and add ammo
	for slot in inventory:
		if slot.type == ItemType.WEAPON and slot.get("weapon_type", "") == weapon_type:
			slot["current_ammo"] = slot.get("current_ammo", slot.get("ammo_capacity", 0)) + amount
			slot["current_ammo"] = min(slot["current_ammo"], slot.get("ammo_capacity", 300))
			emit_signal("ammo_added", weapon_type, amount)
			emit_signal("inventory_updated")
			break

## Use health item
func use_health_item(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= inventory.size():
		return 0.0
	
	var item = inventory[slot_index]
	if item.type != ItemType.HEALTH:
		return 0.0
	
	var heal_amount: float = item.get("heal_amount", 0.0)
	emit_signal("health_used", heal_amount)
	remove_item(slot_index)
	
	return heal_amount

## Get inventory contents
func get_inventory() -> Array[Dictionary]:
	return inventory.duplicate()

## Get item by slot index
func get_item(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= inventory.size():
		return {}
	return inventory[slot_index].duplicate()

## Get all weapons in inventory
func get_weapons() -> Array[Dictionary]:
	var weapons: Array[Dictionary] = []
	for item in inventory:
		if item.type == ItemType.WEAPON:
			weapons.append(item)
	return weapons

## Get inventory slot count
func get_inventory_count() -> int:
	return inventory.size()

## Check if inventory has space for item type
func has_space_for(item_type: ItemType) -> bool:
	match item_type:
		ItemType.WEAPON:
			return inventory.size() < max_weapon_slots
		ItemType.AMMO:
			return inventory.size() < max_ammo_items
		ItemType.HEALTH:
			return inventory.size() < max_health_items
	return false

## Get item data by ID
func _get_item_data(item_id: String) -> Dictionary:
	if item_id in weapons_data:
		return weapons_data[item_id].duplicate()
	elif item_id in ammo_data:
		return ammo_data[item_id].duplicate()
	elif item_id in health_items:
		return health_items[item_id].duplicate()
	return {}

## Debug: Print inventory
func debug_print_inventory() -> void:
	print("=== INVENTORY ===")
	for i in range(inventory.size()):
		var item = inventory[i]
		var marker = " <-- EQUIPPED" if i == equipped_weapon_index else ""
		print(f"[{i}] {item.get('name', 'Unknown')}{marker}")
	print("================")
