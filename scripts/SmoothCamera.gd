## SmoothCamera.gd
## Professional camera follow script with smooth lerp and predictive positioning
## Handles smooth tracking for 120 FPS gameplay

extends Camera3D

# Camera following parameters
@export var follow_distance: float = 8.0
@export var follow_height: float = 6.0
@export var follow_smoothness: float = 0.12
@export var collision_smoothness: float = 0.15
@export var look_ahead_multiplier: float = 0.3

# Collision parameters
@export var collision_enabled: bool = true
@export var min_distance: float = 1.0
@export var collision_mask: int = 1

# Internal state
var target_player: CharacterBody3D
var desired_position: Vector3 = Vector3.ZERO
var current_follow_distance: float
var velocity: Vector3 = Vector3.ZERO

# Physics query
var space_state: PhysicsDirectSpaceState3D

func _ready() -> void:
	# Find the player
	target_player = get_parent()
	if not target_player or not target_player is CharacterBody3D:
		push_error("SmoothCamera must be child of a CharacterBody3D")
		return
	
	space_state = get_world_3d().direct_space_state
	current_follow_distance = follow_distance
	
	# Initialize camera position
	global_position = target_player.global_position + Vector3(0, follow_height, follow_distance)

func _process(delta: float) -> void:
	if not target_player:
		return
	
	# Calculate desired position with look-ahead
	var player_pos: Vector3 = target_player.global_position
	var player_vel: Vector3 = target_player.velocity
	var look_ahead: Vector3 = player_vel * look_ahead_multiplier
	
	# Get camera direction from player's rotation
	var camera_basis: Basis = target_player.global_transform.basis
	var camera_forward: Vector3 = -camera_basis.z
	var camera_up: Vector3 = camera_basis.y
	
	# Calculate desired position behind and above the player
	desired_position = player_pos + (camera_up * follow_height) + (camera_forward * current_follow_distance) + look_ahead
	
	# Check collision and adjust distance
	if collision_enabled:
		_check_and_adjust_collision(player_pos, delta)
	
	# Smooth camera movement
	var target_distance: float = global_position.distance_to(desired_position)
	velocity = velocity.lerp((desired_position - global_position) / delta, follow_smoothness)
	global_position += velocity * delta
	
	# Look at player with slight offset (look ahead)
	var look_target: Vector3 = player_pos + Vector3.UP * 1.5 + player_vel * 0.1
	look_at(look_target, Vector3.UP)

func _check_and_adjust_collision(player_pos: Vector3, delta: float) -> void:
	# Raycast from player to desired camera position
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		player_pos,
		desired_position
	)
	query.collision_mask = collision_mask
	query.exclude = [target_player]
	
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result:
		# Collision detected, adjust camera distance
		var collision_point: Vector3 = result.position
		var distance_to_collision: float = player_pos.distance_to(collision_point)
		current_follow_distance = lerp(
			current_follow_distance,
			max(min_distance, distance_to_collision * 0.9),
			collision_smoothness
		)
	else:
		# No collision, return to desired distance
		current_follow_distance = lerp(
			current_follow_distance,
			follow_distance,
			collision_smoothness
		)

## Set the target player manually (if not parent)
func set_target(player: CharacterBody3D) -> void:
	target_player = player
	if target_player:
		_ready()

## Get current camera distance
func get_current_distance() -> float:
	return current_follow_distance

## Adjust follow distance for zooming
func set_follow_distance(distance: float) -> void:
	follow_distance = clamp(distance, min_distance, 20.0)
