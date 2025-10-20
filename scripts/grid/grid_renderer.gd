extends Node2D
class_name GridRenderer

# === CONFIGURATION ===
@export var grid_color: Color = Color(0.102, 0.227, 0.290, 0.3)  # #1a3a4a
@export var follow_camera: bool = true

# === REFERENCES ===
@onready var shader_material: ShaderMaterial = $GridRect.material

# Internal tracking
var camera: Camera2D = null
var player: Node2D = null

# Pulse decay state
var pulse_decay_timer: float = 0.0
var pulse_decay_duration: float = 0.5

# === INITIALIZATION ===
func _ready() -> void:
	# Find camera and player
	_find_camera()
	_find_player()
	
	# Set up shader material
	_initialize_shader()
	
	# Set up the ColorRect to cover screen
	_setup_rect()

func _find_camera() -> void:
	# Look for Camera2D in scene
	camera = get_viewport().get_camera_2d()
	if not camera:
		push_warning("GridRenderer: No Camera2D found in scene")

func _find_player() -> void:
	# Look for player node (should have group "player")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("GridRenderer: No player found in 'player' group")

func _initialize_shader() -> void:
	if not shader_material:
		push_error("GridRenderer: No shader material assigned")
		return
	
	# Use the global constant for consistency
	var ppu = GameConstants.PIXELS_PER_UNIT
	
	# Set initial shader parameters
	shader_material.set_shader_parameter("minor_spacing", ppu)
	shader_material.set_shader_parameter("major_spacing", ppu * 5.0)
	shader_material.set_shader_parameter("grid_color", grid_color)
	shader_material.set_shader_parameter("line_width", 1.0)
	shader_material.set_shader_parameter("major_line_width", 2.0)

func _setup_rect() -> void:
	var rect = $GridRect as ColorRect
	if rect:
		# Make it cover the entire viewport
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.size = get_viewport_rect().size

# === PROCESS ===
func _process(delta: float) -> void:
	_update_shader_parameters()
	_update_pulse_decay(delta)

func _update_shader_parameters() -> void:
	if not shader_material:
		return
	
	# Update viewport size for proper aspect ratio handling
	var viewport_size = get_viewport_rect().size
	shader_material.set_shader_parameter("viewport_size", viewport_size)
	
	if camera and follow_camera:
		# Use camera position directly - no magic multipliers needed
		# The shader handles the coordinate space conversion
		var offset = camera.get_screen_center_position()
		print("Camera position: ", camera.get_screen_center_position(), " | Grid offset being set: ", offset)
		shader_material.set_shader_parameter("grid_offset", offset)

	
	if player:
		shader_material.set_shader_parameter("player_position", player.global_position)

func _update_pulse_decay(delta: float) -> void:
	if pulse_decay_timer > 0.0:
		pulse_decay_timer -= delta
		var decay_strength = pulse_decay_timer / pulse_decay_duration
		
		if shader_material:
			shader_material.set_shader_parameter("pulse_strength", decay_strength * 0.8)
		
		if pulse_decay_timer <= 0.0:
			# Pulse finished
			shader_material.set_shader_parameter("pulse_strength", 0.0)

# === PUBLIC METHODS ===

## Trigger a pulse effect at a world position
func trigger_pulse(world_pos: Vector2, strength: float = 0.8, radius: float = 150.0) -> void:
	if not shader_material:
		return
	
	# Use world position directly
	shader_material.set_shader_parameter("pulse_position", world_pos)
	shader_material.set_shader_parameter("pulse_strength", strength)
	shader_material.set_shader_parameter("pulse_radius", radius)
	
	# Start pulse decay
	_start_pulse_decay()

func _start_pulse_decay() -> void:
	pulse_decay_timer = pulse_decay_duration

## Set grid alpha
func set_grid_alpha(alpha: float) -> void:
	if shader_material:
		var color = shader_material.get_shader_parameter("grid_color") as Color
		color.a = alpha
		shader_material.set_shader_parameter("grid_color", color)

## Set pixels per unit (for zooming effects)
func set_pixels_per_unit(ppu: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("minor_spacing", ppu)
		shader_material.set_shader_parameter("major_spacing", ppu * 5.0)
