extends CharacterBody2D
class_name PlayerController

## Base class for all player forms
## Handles common functionality across all transformations

# === SIGNALS ===
signal position_changed(new_position: Vector2)
signal velocity_changed(new_velocity: Vector2)
signal transformation_requested(new_form: String)

# === CONFIGURATION ===
@export_group("Movement")
@export var base_speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

@export_group("Visuals")
@export var player_color: Color = Color.CYAN
@export var glow_strength: float = 1.0
@export var trail_enabled: bool = true

# === REFERENCES ===
@onready var sprite: Node2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trail: Line2D = $Trail

# === STATE ===
var current_form: String = "point"
var pixels_per_unit: float = 50.0  # Match grid

# === INITIALIZATION ===
func _ready() -> void:
	add_to_group("player")
	_setup_visuals()

func _setup_visuals() -> void:
	if sprite:
		sprite.modulate = player_color

# === PHYSICS ===
func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_update_trail()
	_emit_position_updates()

func _handle_movement(_delta: float) -> void:
	# Override in child classes
	pass

func _update_trail() -> void:
	if not trail or not trail_enabled:
		return
	
	# Add current position to trail
	trail.add_point(global_position)
	
	# Limit trail length
	if trail.get_point_count() > 50:
		trail.remove_point(0)
	
	# Fade trail over time
	var alpha_gradient = Gradient.new()
	alpha_gradient.add_point(0.0, Color(player_color, 0.0))
	alpha_gradient.add_point(1.0, Color(player_color, 0.5))
	trail.gradient = alpha_gradient

func _emit_position_updates() -> void:
	position_changed.emit(global_position)
	velocity_changed.emit(velocity)

# === HELPER FUNCTIONS ===
func get_grid_position() -> Vector2:
	"""Convert world position to grid coordinates"""
	return global_position / pixels_per_unit

func world_to_grid(world_pos: Vector2) -> Vector2:
	"""Convert any world position to grid coordinates"""
	return world_pos / pixels_per_unit

func grid_to_world(grid_pos: Vector2) -> Vector2:
	"""Convert grid coordinates to world position"""
	return grid_pos * pixels_per_unit

# === PUBLIC METHODS ===
func transform_to(new_form: String) -> void:
	"""Request transformation to new form"""
	transformation_requested.emit(new_form)
