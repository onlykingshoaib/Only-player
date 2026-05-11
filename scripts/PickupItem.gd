## PickupItem.gd
## Base class for pickupable items in the world
## Handles detection and interaction with players

extends Area3D

# Item configuration
@export var item_id: String = "rifle_ammo"
@export var quantity: int = 30
@export var despawn_time: float = 300.0  # 5 minutes before despawn
@export var rotation_speed: float = 2.0

# References
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D if has_node("MeshInstance3D") else null
@onready var collision_shape: CollisionShape3D = $CollisionShape3D if has_node("CollisionShape3D") else null

# Internal state
var pickup_time: float = 0.0
var is_picked_up: bool = false

# Signals
signal item_picked_up(item_id: String, quantity: int)

func _ready() -> void:
	# Validate item
	if item_id.is_empty():
		push_error("Item ID not set")
		queue_free()
		return
	
	# Connect area signals
	area_entered.connect(_on_area_entered)
	
	# Setup physics
	collision_layer = 4  # Items layer
	collision_mask = 0   # Don't collide with anything, only detect
	
	# Visual setup
	_setup_visual()
	
	# Start despawn timer
	await get_tree().create_timer(despawn_time).timeout
	if not is_picked_up:
		_despawn()

func _process(delta: float) -> void:
	if not is_picked_up and mesh_instance:
		# Rotate the item for visual appeal
		mesh_instance.rotate_y(rotation_speed * delta)

func _setup_visual() -> void:
	if not mesh_instance:
		return
	
	# Create simple sphere for now (replace with actual models later)
	if not mesh_instance.mesh:
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.5
		sphere_mesh.height = 1.0
		mesh_instance.mesh = sphere_mesh
	
	# Apply material
	var material = StandardMaterial3D.new()
	material.albedo_color = _get_item_color()
	material.emission = material.albedo_color * 0.5
	material.emission_enabled = true
	mesh_instance.set_surface_override_material(0, material)

func _on_area_entered(area: Area3D) -> void:
	if is_picked_up:
		return
	
	# Check if it's a player
	var parent = area.get_parent()
	if parent and parent.has_method("add_ammo"):
		_pickup(parent)

func _pickup(player: Node3D) -> void:
	is_picked_up = true
	
	# Emit signal for pickup (player will handle through inventory)
	emit_signal("item_picked_up", item_id, quantity)
	
	# Disable visuals
	if mesh_instance:
		mesh_instance.visible = false
	if collision_shape:
		collision_shape.disabled = true
	
	# Despawn after animation
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _despawn() -> void:
	# Fade out effect
	if mesh_instance:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(mesh_instance, "modulate:a", 0.0, 1.0)
	
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _get_item_color() -> Color:
	match item_id:
		"rifle_ammo":
			return Color.YELLOW
		"sniper_ammo":
			return Color.ORANGE
		"shotgun_ammo":
			return Color.RED
		"bandage":
			return Color.GREEN
		"medkit":
			return Color.LIGHT_GREEN
		_:
			return Color.GRAY

## Get item information
func get_item_info() -> Dictionary:
	return {
		"id": item_id,
		"quantity": quantity,
		"type": _get_item_type()
	}

func _get_item_type() -> String:
	if "ammo" in item_id:
		return "ammo"
	elif "health" in item_id or item_id in ["bandage", "medkit"]:
		return "health"
	else:
		return "utility"
