## PlayerController.gd
## Advanced player controller with 3D movement, touch camera, and shooting mechanics
## Optimized for 120 FPS mobile gameplay

extends CharacterBody3D

# Movement parameters
@export var walk_speed: float = 20.0
@export var sprint_speed: float = 35.0
@export var jump_force: float = 15.0
@export var acceleration: float = 50.0
@export var friction: float = 25.0
@export var air_friction: float = 5.0
@export var gravity: float = 40.0

# Camera parameters
@export var camera_sensitivity: float = 0.003
@export var max_look_angle: float = 90.0
@export var smooth_factor: float = 0.15

# Combat parameters
@export var fire_rate: float = 0.1
@export var projectile_speed: float = 100.0
@export var max_ammo: int = 300

# References
@onready var camera_3d: Camera3D = $Camera3D
@onready var raycast_3d: RayCast3D = $Camera3D/RayCast3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Internal state
var current_velocity: Vector3 = Vector3.ZERO
var desired_velocity: Vector3 = Vector3.ZERO
var camera_rotation: Vector2 = Vector2.ZERO
var is_sprinting: bool = false
var can_shoot: bool = true
var current_ammo: int = 300
var current_health: float = 100.0
var max_health: float = 100.0

# Touch input state
var touch_input: Vector2 = Vector2.ZERO
var look_input: Vector2 = Vector2.ZERO
var is_aiming: bool = false
var is_jumping: bool = false

# Signals
signal health_changed(health: float)
signal ammo_changed(ammo: int)
signal player_died

func _ready() -> void:
	# Ensure character body is properly set up
	if not is_node_ready():
		await tree_entered
	
	# Disable mouse capture for mobile
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Initialize camera
	if camera_3d:
		camera_3d.current = true
	
	# Connect to HUD signals
	get_tree().get_first_node_in_group("mobile_hud")?.connect_controller(self)
	
	current_ammo = max_ammo
	emit_signal("ammo_changed", current_ammo)

func _physics_process(delta: float) -> void:
	# Update movement
	_update_movement(delta)
	
	# Update camera
	_update_camera(delta)
	
	# Apply velocity
	velocity = current_velocity
	move_and_slide()
	current_velocity = velocity
	
	# Update aiming state
	_update_aiming(delta)

func _update_movement(delta: float) -> void:
	# Get input from touch or keyboard
	var input_vector: Vector3 = Vector3.ZERO
	
	# Keyboard input (for testing)
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.z = Input.get_axis("ui_up", "ui_down")
	
	# Mobile touch input (from HUD)
	input_vector = Vector3(touch_input.x, 0, touch_input.y)
	
	# Normalize diagonal movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
	
	# Determine target speed
	var target_speed: float = sprint_speed if is_sprinting else walk_speed
	
	# Transform input to world space based on camera direction
	var camera_forward: Vector3 = -camera_3d.global_transform.basis.z
	var camera_right: Vector3 = camera_3d.global_transform.basis.x
	camera_forward.y = 0
	camera_forward = camera_forward.normalized()
	camera_right.y = 0
	camera_right = camera_right.normalized()
	
	# Calculate desired velocity
	desired_velocity = (camera_forward * input_vector.z + camera_right * input_vector.x) * target_speed
	
	# Apply gravity
	if not is_on_floor():
		current_velocity.y -= gravity * delta
	elif is_jumping:
		current_velocity.y = jump_force
		is_jumping = false
	
	# Smooth horizontal acceleration/deceleration
	var friction_factor: float = friction if is_on_floor() else air_friction
	current_velocity.x = lerp(current_velocity.x, desired_velocity.x, 1.0 - exp(-friction_factor * delta))
	current_velocity.z = lerp(current_velocity.z, desired_velocity.z, 1.0 - exp(-friction_factor * delta))

func _update_camera(delta: float) -> void:
	# Apply camera rotation from touch look
	camera_rotation.y -= look_input.x * camera_sensitivity
	camera_rotation.x = clamp(camera_rotation.x - look_input.y * camera_sensitivity, -max_look_angle, max_look_angle)
	
	# Apply rotation to camera
	camera_3d.rotation.x = deg_to_rad(camera_rotation.x)
	global_rotation.y = deg_to_rad(camera_rotation.y)
	
	# Reset look input
	look_input = Vector2.ZERO

## Called from MobileHUD to update movement input
func set_movement_input(input_vector: Vector2) -> void:
	touch_input = input_vector

## Called from MobileHUD to update camera look
func set_look_input(look_delta: Vector2) -> void:
	look_input = look_delta

## Called from MobileHUD for jump action
func jump() -> void:
	if is_on_floor():
		is_jumping = true

## Called from MobileHUD for sprint
func set_sprint(sprinting: bool) -> void:
	is_sprinting = sprinting

## Called from MobileHUD for aiming
func set_aiming(aiming: bool) -> void:
	is_aiming = aiming

## Called from MobileHUD for shooting
func shoot() -> void:
	if not can_shoot or current_ammo <= 0:
		return
	
	can_shoot = false
	await get_tree().create_timer(0.1).timeout
	can_shoot = true
	
	if raycast_3d.is_colliding():
		var collider = raycast_3d.get_collider()
		if collider and collider.is_in_group("enemies"):
			_deal_damage_to_target(collider, 25.0)
	
	current_ammo -= 1
	emit_signal("ammo_changed", current_ammo)
	
	# Fire animation and effects
	_play_shoot_effect()

## Deal damage to a target
func _deal_damage_to_target(target: Node3D, damage: float) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)

## Play shooting effects
func _play_shoot_effect() -> void:
	if animation_player:
		animation_player.play("shoot")
	
	# Audio effect would go here
	# get_node("ShootSound").play()

## Called from SafeZone for damage
func take_damage(damage: float) -> void:
	current_health = max(0, current_health - damage)
	emit_signal("health_changed", current_health)
	
	if current_health <= 0:
		_die()

## Player death
func _die() -> void:
	emit_signal("player_died")
	set_physics_process(false)
	if animation_player:
		animation_player.play("death")

## Pickup weapons/ammo
func add_ammo(amount: int) -> void:
	current_ammo = min(current_ammo + amount, max_ammo)
	emit_signal("ammo_changed", current_ammo)

## Heal player
func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health)

## Get current health percentage
func get_health_percentage() -> float:
	return current_health / max_health
