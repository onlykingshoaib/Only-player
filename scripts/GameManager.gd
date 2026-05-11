## GameManager.gd
## High-level game flow and state management
## Handles match lifecycle, player spawning, and victory conditions

extends Node3D

# Game state enum
enum GameState {
	LOADING,
	LOBBY,
	COUNTDOWN,
	PLAYING,
	SAFE_ZONE_SHRINKING,
	GAME_OVER,
	VICTORY
}

# Game configuration
@export var player_count: int = 100
@export var spawn_area_radius: float = 250.0
@export var countdown_time: float = 10.0
@export var match_duration: float = 900.0  # 15 minutes

# References
var current_state: GameState = GameState.LOADING
var player: CharacterBody3D
var safe_zone: Node3D
var mobile_hud: CanvasLayer
var inventory: Node3D

# Match state
var players_alive: int = 0
var match_start_time: float = 0.0
var winners: Array[String] = []

# Signals
signal game_state_changed(new_state: GameState)
signal match_started
signal match_ended(winners: Array[String])
signal player_eliminated(player_name: String)

func _ready() -> void:
	# Find key nodes
	player = get_tree().get_first_node_in_group("player")
	safe_zone = get_tree().get_first_node_in_group("safe_zone")
	mobile_hud = get_tree().get_first_node_in_group("mobile_hud")
	
	# Connect to safe zone signals
	if safe_zone and safe_zone.has_signal("zone_shrink_started"):
		safe_zone.zone_shrink_started.connect(_on_safe_zone_shrink_started)
		safe_zone.zone_shrink_ended.connect(_on_safe_zone_shrink_ended)
	
	# Connect to player signals
	if player and player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	
	# Initialize game
	_change_state(GameState.LOBBY)

func _process(delta: float) -> void:
	match current_state:
		GameState.COUNTDOWN:
			_update_countdown(delta)
		GameState.PLAYING:
			_update_gameplay(delta)
		GameState.SAFE_ZONE_SHRINKING:
			_update_zone_shrinking(delta)

## Change game state
func _change_state(new_state: GameState) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	emit_signal("game_state_changed", current_state)
	
	match new_state:
		GameState.LOADING:
			_state_loading()
		GameState.LOBBY:
			_state_lobby()
		GameState.COUNTDOWN:
			_state_countdown()
		GameState.PLAYING:
			_state_playing()
		GameState.SAFE_ZONE_SHRINKING:
			_state_zone_shrinking()
		GameState.GAME_OVER:
			_state_game_over()
		GameState.VICTORY:
			_state_victory()

## LOADING STATE - Initialize game assets
func _state_loading() -> void:
	print("[GameManager] Loading assets...")
	# Preload models, sounds, textures here
	await get_tree().process_frame
	_change_state(GameState.LOBBY)

## LOBBY STATE - Wait for players
func _state_lobby() -> void:
	print("[GameManager] Waiting in lobby...")
	players_alive = player_count
	
	# Spawn initial player
	if player:
		_spawn_player(player, Vector3(0, 2, 0))
	
	# Spawn AI enemies (simplified)
	for i in range(player_count - 1):
		_spawn_enemy(i)
	
	# Start countdown after brief delay
	await get_tree().create_timer(3.0).timeout
	_change_state(GameState.COUNTDOWN)

## COUNTDOWN STATE - Pre-match countdown
var countdown_remaining: float = 0.0
func _state_countdown() -> void:
	print("[GameManager] Starting countdown...")
	countdown_remaining = countdown_time

func _update_countdown(delta: float) -> void:
	countdown_remaining -= delta
	
	if countdown_remaining <= 0:
		_change_state(GameState.PLAYING)

## PLAYING STATE - Active gameplay
func _state_playing() -> void:
	print("[GameManager] Match started!")
	match_start_time = Time.get_ticks_msec() / 1000.0
	emit_signal("match_started")
	
	# Start safe zone shrinking with public interface
	if safe_zone and safe_zone.has_method("start_zone_shrinking"):
		safe_zone.start_zone_shrinking()

func _update_gameplay(delta: float) -> void:
	var elapsed_time = (Time.get_ticks_msec() / 1000.0) - match_start_time
	
	# Check victory condition
	if players_alive <= 1:
		_change_state(GameState.VICTORY)

## SAFE ZONE SHRINKING STATE
func _state_zone_shrinking() -> void:
	print("[GameManager] Safe zone shrinking!")

func _update_zone_shrinking(delta: float) -> void:
	if safe_zone:
		if safe_zone.has_method("get_zone_info"):
			var zone_info = safe_zone.get_zone_info()
			if not zone_info.get("is_shrinking", false):
				_change_state(GameState.PLAYING)

## GAME OVER STATE
func _state_game_over() -> void:
	print("[GameManager] Game over! Winners: ", winners)
	emit_signal("match_ended", winners)
	get_tree().paused = true

## VICTORY STATE - Player won
func _state_victory() -> void:
	print("[GameManager] VICTORY! Player is the last one standing!")
	winners.append(player.name)
	_change_state(GameState.GAME_OVER)

## Spawn player at position
func _spawn_player(p: CharacterBody3D, position: Vector3) -> void:
	if p:
		p.global_position = position
		if p.has_method("_ready"):
			p._ready()

## Spawn AI enemy
func _spawn_enemy(enemy_id: int) -> void:
	# Simplified enemy spawning - use random position in spawn area
	var spawn_pos = Vector3(
		randf_range(-spawn_area_radius, spawn_area_radius),
		2,
		randf_range(-spawn_area_radius, spawn_area_radius)
	)
	
	# In full implementation, instantiate enemy scene here
	print(f"[GameManager] Spawned enemy {enemy_id} at {spawn_pos}")

## Signal handlers

func _on_player_died() -> void:
	players_alive -= 1
	emit_signal("player_eliminated", player.name)
	
	if players_alive <= 1:
		_change_state(GameState.VICTORY)

func _on_safe_zone_shrink_started() -> void:
	_change_state(GameState.SAFE_ZONE_SHRINKING)

func _on_safe_zone_shrink_ended() -> void:
	if current_state == GameState.SAFE_ZONE_SHRINKING:
		_change_state(GameState.PLAYING)

## Public API

## Get current game state
func get_current_state() -> GameState:
	return current_state

## Get players alive count
func get_players_alive() -> int:
	return players_alive

## Get match elapsed time
func get_match_time() -> float:
	return (Time.get_ticks_msec() / 1000.0) - match_start_time

## Force game end
func end_match() -> void:
	_change_state(GameState.GAME_OVER)
