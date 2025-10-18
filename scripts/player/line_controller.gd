extends PlayerController
class_name LineController

## Stage 3: Two-vertex line segment with Unity and Endpoint modes

# === VERTEX CONFIGURATION ===
class Vertex:
	var position: Vector2
	var color: Color
	var node: Node2D
	
	func _init(pos: Vector2 = Vector2.ZERO, col: Color = Color.WHITE) -> void:
		position = pos
		color = col

# === STATE ===
enum Mode { UNITY, ENDPOINT }
var current_mode: Mode = Mode.UNITY
var vertices: Array[Vertex] = []
var active_endpoint: int = 0  # 0 or 1
var line_length: float = 100.0  # pixels

# === CONFIGURATION ===
@export_group("Line")
@export var min_length: float = 50.0
@export var max_length: float = 200.0
@export var rotation_speed: float = 180.0  # degrees per second
@export var endpoint_switch_enabled: bool = true

# === REFERENCES ===
@onready var vertex_a: Node2D = $VertexA
@onready var vertex_b: Node2D = $VertexB
@onready var line_visual: Line2D = $LineVisual

# === INITIALIZATION ===
func _ready() -> void:
	super._ready()
	current_form = "line"
	_initialize_vertices()

func _initialize_vertices() -> void:
	# Vector Zero (cyan)
	var vert_a = Vertex.new(Vector2(-line_length / 2.0, 0.0), Color.CYAN)
	vert_a.node = vertex_a
	
	# Echo (magenta)
	var vert_b = Vertex.new(Vector2(line_length / 2.0, 0.0), Color.MAGENTA)
	vert_b.node = vertex_b
	
	vertices = [vert_a, vert_b]
	
	_update_vertex_positions()
	_update_line_visual()

# === INPUT ===
func _unhandled_input(event: InputEvent) -> void:
	# Toggle mode
	if event.is_action_pressed("toggle_mode"):
		_toggle_mode()
	
	# In endpoint mode, switch active endpoint
	if current_mode == Mode.ENDPOINT and event.is_action_pressed("switch_endpoint"):
		_switch_endpoint()
	
	# Rotate line
	if event.is_action_pressed("rotate_cw"):
		_rotate_line(1.0)
	elif event.is_action_pressed("rotate_ccw"):
		_rotate_line(-1.0)

# === MOVEMENT ===
func _handle_movement(delta: float) -> void:
	match current_mode:
		Mode.UNITY:
			_handle_unity_movement(delta)
		Mode.ENDPOINT:
			_handle_endpoint_movement(delta)
	
	_update_vertex_positions()
	_update_line_visual()

func _handle_unity_movement(delta: float) -> void:
	# Move entire line as rigid body
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * base_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	
	# Rotate line with additional input
	var rotation_input = Input.get_axis("rotate_ccw", "rotate_cw")
	if rotation_input != 0.0:
		rotation_degrees += rotation_input * rotation_speed * delta

func _handle_endpoint_movement(delta: float) -> void:
	# Anchor one endpoint, move the other
	var anchor_index = 1 - active_endpoint
	var moving_index = active_endpoint
	
	# Get input
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction != Vector2.ZERO:
		# Move the active endpoint
		var anchor_world = _vertex_to_world(vertices[anchor_index])
		var moving_world = _vertex_to_world(vertices[moving_index])
		
		# Move toward input direction
		moving_world += input_direction * base_speed * delta
		
		# Calculate new length and angle
		var new_vector = moving_world - anchor_world
		var new_length = new_vector.length()
		
		# Clamp length
		new_length = clamp(new_length, min_length, max_length)
		new_vector = new_vector.normalized() * new_length
		
		# Update line properties
		line_length = new_length
		var angle_to_anchor = anchor_world.angle_to_point(anchor_world + new_vector)
		rotation = angle_to_anchor
		
		# Update position (midpoint)
		global_position = (anchor_world + (anchor_world + new_vector)) / 2.0

func _toggle_mode() -> void:
	if current_mode == Mode.UNITY:
		current_mode = Mode.ENDPOINT
		_visual_mode_change()
	else:
		current_mode = Mode.UNITY
		_visual_mode_change()

func _switch_endpoint() -> void:
	if endpoint_switch_enabled:
		active_endpoint = 1 - active_endpoint
		_highlight_active_endpoint()

func _rotate_line(direction: float) -> void:
	# Instant rotation for puzzle alignment
	rotation_degrees += direction * 90.0  # Rotate 90 degrees at a time

# === VERTEX MANAGEMENT ===
func _update_vertex_positions() -> void:
	if vertices.size() != 2:
		return
	
	# Update vertices relative to line center
	vertices[0].position = Vector2(-line_length / 2.0, 0.0)
	vertices[1].position = Vector2(line_length / 2.0, 0.0)
	
	# Update visual nodes
	if vertex_a:
		vertex_a.position = vertices[0].position
	if vertex_b:
		vertex_b.position = vertices[1].position

func _vertex_to_world(vertex: Vertex) -> Vector2:
	"""Convert vertex local position to world position"""
	return global_position + vertex.position.rotated(rotation)

func _update_line_visual() -> void:
	if not line_visual:
		return
	
	line_visual.clear_points()
	line_visual.add_point(vertices[0].position)
	line_visual.add_point(vertices[1].position)
	
	# Gradient from Vector Zero (cyan) to Echo (magenta)
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color.CYAN)
	gradient.add_point(1.0, Color.MAGENTA)
	line_visual.gradient = gradient
	line_visual.width = 3.0

func _visual_mode_change() -> void:
	# TODO: Add visual feedback for mode change
	# Flash vertices, change UI indicator, etc.
	pass

func _highlight_active_endpoint() -> void:
	if vertices.size() != 2:
		return
	
	# Highlight active endpoint
	for i in range(2):
		if vertices[i].node:
			var is_active = (i == active_endpoint) and (current_mode == Mode.ENDPOINT)
			var scale_target = 1.3 if is_active else 1.0
			vertices[i].node.scale = Vector2.ONE * scale_target

# === PUBLIC METHODS ===
func get_length() -> float:
	"""Get current line length in pixels"""
	return line_length

func get_length_units() -> float:
	"""Get current line length in grid units"""
	return line_length / pixels_per_unit

func get_slope() -> float:
	"""Get line slope (rise/run)"""
	var angle_rad = rotation
	if cos(angle_rad) == 0.0:
		return INF  # Vertical line
	return tan(angle_rad)
