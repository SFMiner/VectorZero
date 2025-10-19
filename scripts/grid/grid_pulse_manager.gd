extends Node
class_name GridPulseManager

## Detects when player crosses integer coordinates and triggers grid pulses

# === CONFIGURATION ===
@export var player_path: NodePath
@export var grid_renderer_path: NodePath
@export var pulse_threshold: float = 0.05  # How close to integer before pulse
@export var pulse_strength: float = 0.8
@export var pulse_radius: float = 150.0
@export var pixels_per_unit: float = 500.0  # UPDATED: was 50.0, now matches grid scale

# === REFERENCES ===
var player: Node2D
var grid_renderer: GridRenderer

# === STATE ===
var last_grid_x: int = 0
var last_grid_y: int = 0

# === INITIALIZATION ===
func _ready() -> void:
	# Get references
	if player_path:
		player = get_node(player_path)
	if grid_renderer_path:
		grid_renderer = get_node(grid_renderer_path)
	
	if not player:
		push_error("GridPulseManager: Player not found")
		return
	
	if not grid_renderer:
		push_error("GridPulseManager: GridRenderer not found")
		return
	
	# Initialize tracking
	var grid_pos = _world_to_grid(player.global_position)
	last_grid_x = int(round(grid_pos.x))
	last_grid_y = int(round(grid_pos.y))

# === PROCESS ===
func _process(_delta: float) -> void:
	if not player or not grid_renderer:
		return
	
	_check_grid_crossing()

# === GRID CROSSING DETECTION ===
func _check_grid_crossing() -> void:
	# Convert player position to grid coordinates
	var grid_pos = _world_to_grid(player.global_position)
	var current_grid_x = int(round(grid_pos.x))
	var current_grid_y = int(round(grid_pos.y))
	
	# Check if we crossed an integer X coordinate
	if current_grid_x != last_grid_x:
		var pulse_world_x = current_grid_x * pixels_per_unit
		var pulse_pos = Vector2(pulse_world_x, player.global_position.y)
		_trigger_crossing_pulse(pulse_pos)
		last_grid_x = current_grid_x
	
	# Check if we crossed an integer Y coordinate
	if current_grid_y != last_grid_y:
		var pulse_world_y = current_grid_y * pixels_per_unit
		var pulse_pos = Vector2(player.global_position.x, pulse_world_y)
		_trigger_crossing_pulse(pulse_pos)
		last_grid_y = current_grid_y

func _trigger_crossing_pulse(world_position: Vector2) -> void:
	grid_renderer.trigger_pulse(world_position, pulse_strength, pulse_radius)
	
	# Optional: Play audio effect
	_play_grid_cross_sound()

func _play_grid_cross_sound() -> void:
	# TODO: Implement audio feedback
	# AudioManager.play_sfx("grid_cross", 0.3)  # Low volume
	pass

# === HELPER FUNCTIONS ===
func _world_to_grid(world_pos: Vector2) -> Vector2:
	return world_pos / pixels_per_unit
