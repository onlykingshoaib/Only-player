## MobileHUD.gd
## Touch UI controller with virtual joysticks and action buttons
## Optimized for 120 FPS mobile gameplay with zero-lag input

extends CanvasLayer

# UI References
@onready var movement_joystick: Control = $MovementJoystick
@onready var look_joystick: Control = $LookJoystick
@onready var jump_button: Button = $ActionButtons/JumpButton
@onready var shoot_button: Button = $ActionButtons/ShootButton
@onready var aim_button: Button = $ActionButtons/AimButton
@onready var sprint_button: Button = $ActionButtons/SprintButton
@onready var health_label: Label = $InfoPanel/HealthLabel
@onready var ammo_label: Label = $InfoPanel/AmmoLabel
@onready var zone_info_label: Label = $InfoPanel/ZoneInfoLabel

# Joystick parameters
@export var joystick_radius: float = 80.0
@export var deadzone: float = 0.2
@export var movement_speed_factor: float = 1.0
@export var look_speed_factor: float = 1.0

# Internal state
var player_controller: CharacterBody3D
var movement_input: Vector2 = Vector2.ZERO
var look_input: Vector2 = Vector2.ZERO
var is_touch_held: bool = false
var touch_id: int = -1

# Touch input tracking
var movement_touch_pos: Vector2 = Vector2.ZERO
var look_touch_pos: Vector2 = Vector2.ZERO

# Signals
signal movement_input_changed(input: Vector2)
signal look_input_changed(input: Vector2)

func _ready() -> void:
	# Add to HUD group for discovery
	add_to_group("mobile_hud")
	
	# Initialize joystick visuals
	_setup_joysticks()
	
	# Connect button signals
	if jump_button:
		jump_button.pressed.connect(_on_jump_pressed)
	if shoot_button:
		shoot_button.pressed.connect(_on_shoot_pressed)
	if aim_button:
		aim_button.pressed.connect(_on_aim_pressed)
	if sprint_button:
		sprint_button.toggled.connect(_on_sprint_toggled)
	
	# Set initial UI state
	_update_ui_labels()

func _setup_joysticks() -> void:
	if movement_joystick:
		movement_joystick.custom_minimum_size = Vector2(200, 200)
		movement_joystick.anchors_and_offsets_preset = Control.PRESET_BOTTOM_LEFT
		movement_joystick.offset_left = 20
		movement_joystick.offset_top = -220
		movement_joystick.modulate.alpha = 0.6
	
	if look_joystick:
		look_joystick.custom_minimum_size = Vector2(200, 200)
		look_joystick.anchors_and_offsets_preset = Control.PRESET_BOTTOM_RIGHT
		look_joystick.offset_right = -20
		look_joystick.offset_top = -220
		look_joystick.modulate.alpha = 0.6

func _process(delta: float) -> void:
	# Update input from joysticks
	_update_movement_input(delta)
	_update_look_input(delta)
	
	# Update UI labels periodically
	if fmod(Time.get_ticks_msec() / 1000.0, 0.1) < delta:
		_update_ui_labels()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Handle touch input
	if event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event
		
		if touch_event.pressed:
			_handle_touch_pressed(touch_event.position, touch_event.index)
		else:
			_handle_touch_released(touch_event.index)
	
	elif event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event
		_handle_touch_drag(drag_event.position, drag_event.index)

func _handle_touch_pressed(position: Vector2, touch_index: int) -> void:
	# Determine which joystick or button area
	var viewport_size: Vector2 = get_viewport_rect().size
	
	# Left side = movement joystick
	if position.x < viewport_size.x / 2:
		movement_touch_pos = position
	# Right side = look joystick
	else:
		look_touch_pos = position

func _handle_touch_released(touch_index: int) -> void:
	movement_input = Vector2.ZERO
	look_input = Vector2.ZERO
	movement_touch_pos = Vector2.ZERO
	look_touch_pos = Vector2.ZERO
	_emit_input_signals()

func _handle_touch_drag(position: Vector2, touch_index: int) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	
	# Left side = movement joystick
	if position.x < viewport_size.x / 2:
		var center: Vector2 = Vector2(100, viewport_size.y - 120)
		var delta: Vector2 = (position - center) / joystick_radius
		movement_input = delta.normalized() if delta.length() > deadzone else Vector2.ZERO
	# Right side = look joystick
	else:
		var center: Vector2 = Vector2(viewport_size.x - 100, viewport_size.y - 120)
		var delta: Vector2 = (position - center) / joystick_radius
		look_input = delta.normalized() if delta.length() > deadzone else Vector2.ZERO
	
	_emit_input_signals()

func _update_movement_input(delta: float) -> void:
	# Apply keyboard input for testing
	var kb_input: Vector2 = Vector2.ZERO
	kb_input.x = Input.get_axis("ui_left", "ui_right")
	kb_input.y = Input.get_axis("ui_up", "ui_down")
	
	if kb_input.length() > 0:
		movement_input = kb_input.normalized()
	
	_emit_input_signals()

func _update_look_input(delta: float) -> void:
	# Mouse look for testing (when emulating touch from mouse)
	if Input.is_action_pressed("ui_accept"):  # Right-click equivalent
		var mouse_pos: Vector2 = get_global_mouse_position()
		var viewport_size: Vector2 = get_viewport_rect().size
		var center: Vector2 = viewport_size * 0.75
		look_input = ((mouse_pos - center) * 0.01).normalized()
	
	_emit_input_signals()

func _emit_input_signals() -> void:
	if player_controller:
		player_controller.set_movement_input(movement_input)
		player_controller.set_look_input(look_input * look_speed_factor)

func _on_jump_pressed() -> void:
	if player_controller:
		player_controller.jump()

func _on_shoot_pressed() -> void:
	if player_controller:
		player_controller.shoot()

func _on_aim_pressed() -> void:
	if player_controller:
		player_controller.set_aiming(true)

func _on_sprint_toggled(toggled: bool) -> void:
	if player_controller:
		player_controller.set_sprint(toggled)

func _update_ui_labels() -> void:
	if not player_controller:
		return
	
	# Update health label
	if health_label:
		var health_pct: float = player_controller.get_health_percentage() * 100
		health_label.text = f"HP: {int(health_pct)}%"
		health_label.modulate = Color.RED.lerp(Color.GREEN, player_controller.get_health_percentage())
	
	# Update ammo label
	if ammo_label:
		ammo_label.text = f"AMMO: {player_controller.current_ammo}"
	
	# Update zone info (if available)
	if zone_info_label:
		var safe_zone = get_tree().get_first_node_in_group("safe_zone")
		if safe_zone and safe_zone.has_method("get_zone_info"):
			var zone_data = safe_zone.get_zone_info()
			var time_remaining = int(zone_data.get("time_remaining", 0))
			zone_info_label.text = f"ZONE: {int(zone_data.get('radius', 0))}m | {time_remaining}s"

## Called from PlayerController to connect this HUD
func connect_controller(controller: CharacterBody3D) -> void:
	player_controller = controller
	
	# Connect signals
	if controller.has_signal("health_changed"):
		controller.health_changed.connect(_on_player_health_changed)
	if controller.has_signal("ammo_changed"):
		controller.ammo_changed.connect(_on_player_ammo_changed)

func _on_player_health_changed(health: float) -> void:
	_update_ui_labels()

func _on_player_ammo_changed(ammo: int) -> void:
	_update_ui_labels()

## Create visual joystick display
func create_joystick_visual() -> TextureRect:
	var rect = TextureRect.new()
	rect.custom_minimum_size = Vector2(200, 200)
	return rect
