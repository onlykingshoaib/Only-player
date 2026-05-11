## SafeZone.gd
## Shrinking circle logic with visual representation and damage area
## Manages the battle royale safe zone mechanics

extends Node3D

# Safe zone parameters
@export var initial_radius: float = 200.0
@export var final_radius: float = 10.0
@export var shrink_duration: float = 300.0  # 5 minutes
@export var damage_per_tick: float = 5.0
@export var damage_tick_rate: float = 0.5  # seconds between damage ticks

# Visual parameters
@export var inner_zone_color: Color = Color(0.2, 0.8, 0.2, 0.3)
@export var outer_zone_color: Color = Color(1.0, 0.2, 0.2, 0.4)
@export var torus_radius: float = 50.0
@export var torus_inner_radius: float = 2.0
@export var update_frequency: float = 0.1  # Update visual every 100ms

# Internal state
var current_radius: float
var time_elapsed: float = 0.0
var damage_accumulator: float = 0.0
var is_shrinking: bool = false
var current_center: Vector3 = Vector3.ZERO
var players_in_danger: Array[Node3D] = []

# References
@onready var area_3d: Area3D = $Area3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var shape_cast: ShapeCast3D = $ShapeCast3D if has_node("ShapeCast3D") else null

# Signals
signal zone_shrink_started
signal zone_shrink_progress(progress: float)
signal zone_shrink_ended
signal player_in_danger(player: Node3D)
signal player_safe(player: Node3D)

func _ready() -> void:
	current_radius = initial_radius
	
	# Setup Area3D for damage detection
	if area_3d:
		area_3d.area_entered.connect(_on_player_entered_danger)
		area_3d.area_exited.connect(_on_player_left_danger)
	
	# Create initial mesh visualization
	_update_mesh_visualization()
	
	# Start first shrink phase
	_start_shrink_phase()

func _process(delta: float) -> void:
	if not is_shrinking:
		return
	
	time_elapsed += delta
	damage_accumulator += delta
	
	# Calculate current radius
	var progress: float = min(time_elapsed / shrink_duration, 1.0)
	current_radius = lerp(initial_radius, final_radius, progress)
	
	# Update zone position (for dynamic moving safe zones, adjust center here)
	current_center = global_position
	
	# Emit progress signal
	emit_signal("zone_shrink_progress", progress)
	
	# Update mesh visualization periodically
	if fmod(time_elapsed, update_frequency) < delta:
		_update_mesh_visualization()
	
	# Apply damage to players in danger zone
	if damage_accumulator >= damage_tick_rate:
		_apply_damage_to_players()
		damage_accumulator = 0.0
	
	# Check if shrinking is complete
	if progress >= 1.0:
		_end_shrink_phase()

func _start_shrink_phase() -> void:
	is_shrinking = true
	time_elapsed = 0.0
	damage_accumulator = 0.0
	emit_signal("zone_shrink_started")
	
	# Update collision shapes
	_update_collision_shapes()

## Public API for starting zone shrinking (called from GameManager)
func start_zone_shrinking() -> void:
	_start_shrink_phase()

func _end_shrink_phase() -> void:
	is_shrinking = false
	current_radius = final_radius
	players_in_danger.clear()
	_update_mesh_visualization()
	_update_collision_shapes()
	emit_signal("zone_shrink_ended")

func _update_mesh_visualization() -> void:
	if not mesh_instance:
		return
	
	# Create or update torus mesh for the safe zone boundary
	var torus_mesh: TorusMesh = TorusMesh.new()
	torus_mesh.radius = current_radius
	torus_mesh.inner_radius = torus_inner_radius
	torus_mesh.height = 1.0
	
	mesh_instance.mesh = torus_mesh
	
	# Update material to show zone status
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = inner_zone_color
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.no_depth_test = false
	
	mesh_instance.set_surface_override_material(0, mat)

func _update_collision_shapes() -> void:
	# Update Area3D collision shape to match current radius
	if area_3d and area_3d.get_child_count() > 0:
		var collision_shape: CollisionShape3D = area_3d.get_child(0)
		if collision_shape:
			var cylinder_shape: CylinderShape3D = CylinderShape3D.new()
			cylinder_shape.radius = current_radius
			cylinder_shape.height = 500.0  # Large height to catch players at any elevation
			collision_shape.shape = cylinder_shape

func _on_player_entered_danger(area: Area3D) -> void:
	var player = area.get_parent()
	if player and player not in players_in_danger:
		players_in_danger.append(player)
		emit_signal("player_in_danger", player)

func _on_player_left_danger(area: Area3D) -> void:
	var player = area.get_parent()
	if player and player in players_in_danger:
		players_in_danger.erase(player)
		emit_signal("player_safe", player)

func _apply_damage_to_players() -> void:
	for player in players_in_danger:
		if player and player.has_method("take_damage"):
			player.take_damage(damage_per_tick)

## Get current zone info
func get_zone_info() -> Dictionary:
	var progress: float = min(time_elapsed / shrink_duration, 1.0)
	return {
		"radius": current_radius,
		"center": current_center,
		"progress": progress,
		"is_shrinking": is_shrinking,
		"time_remaining": max(0, shrink_duration - time_elapsed)
	}

## Manually move the safe zone center
func move_zone_center(new_center: Vector3, duration: float = 0.0) -> void:
	if duration > 0.0:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "global_position", new_center, duration)
	else:
		global_position = new_center
	
	current_center = new_center

## Get distance from point to zone center
func get_distance_to_center(point: Vector3) -> float:
	return current_center.distance_to(point)

## Check if point is inside safe zone
func is_point_in_zone(point: Vector3) -> bool:
	return get_distance_to_center(point) <= current_radius

## Get number of players in danger zone
func get_players_in_danger_count() -> int:
	return players_in_danger.size()
