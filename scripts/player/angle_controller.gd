extends PlayerController
class_name AngleController

## Stage 4-5: Three-vertex unstable angle with floppy physics

# === VERTEX CONFIGURATION ===
class AngleVertex:
	var position: Vector2
	var velocity: Vector2
	var color: Color
	var node: Node2D
	var mass: float = 1.0
	
	func _init(pos: Vector2 = Vector2.ZERO, col: Color = Color.WHITE) -> void:
		position = pos
		velocity = Vector2.ZERO
		color = col

# === STATE ===
var vertices: Array[AngleVertex] = []
var is_stable: bool = false  # Will be true in Stage 6

# === CONFIGURATION ===
@export_group("Angle Physics")
@export var arm_length: float = 75.0
@export var spring_stiffness: float = 500.0
@export var arm_damping: float = 5.0
@export var environmental_force_strength: float = 100.0
@export var rotation_speed: float = 90.0  # degrees per second

# === REFERENCES ===
@onready var vertex_zero: Node2D = $VertexZero  # Vector Zero (cyan)
@onready var vertex_echo: Node2D = $VertexEcho  # Echo (magenta)
@onready var vertex_axiom: Node2D = $VertexAxiom  # Axiom (yellow)
@onready var arm_visual_1: Line2D = $ArmVisual1
@onready var arm_visual_2: Line2D = $ArmVisual2

# === INITIALIZATION ===
func _ready() -> void:
	super._ready()
	current_form = "angle"
	_initialize_vertices()

func _initialize_vertices() -> void:
	# Vector Zero at apex (cyan)
	var vert_0 = AngleVertex.new(Vector2.ZERO, Color.CYAN)
	vert_0.node = vertex_zero
	
	# Echo as first arm (magenta)
	var vert_1 = AngleVertex.new(Vector2(arm_length, 0.0), Color.MAGENTA)
	vert_1.node = vertex_echo
	
	# Axiom as second arm (yellow)
	var vert_2 = AngleVertex.new(Vector2(-arm_length, 0.0), Color(1.0, 1.0, 0.0))
	vert_2.node = vertex_axiom
	
	vertices = [vert_0, vert_1, vert_2]
	
	_update_vertex_positions()
	_update_arm_visuals()

# === PHYSICS ===
func _handle_movement(delta: float) -> void:
	if is_stable:
		_handle_stable_movement(delta)
	else:
		_handle_unstable_movement(delta)
	
	_update_vertex_positions()
	_update_arm_visuals()

func _handle_unstable_movement(delta: float) -> void:
	# Get player input for apex (vertex 0)
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Apply force to apex
	if input_direction != Vector2.ZERO:
		vertices[0].velocity += input_direction * acceleration * delta
	
	# Apply friction to apex
	vertices[0].velocity = vertices[0].velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Update apex position
	vertices[0].position += vertices[0].velocity * delta
	
	# Update arms with spring physics
	_update_arm_physics(delta)
	
	# Apply environmental forces (wind, gravity, etc.)
	_apply_environmental_forces(delta)
	
	# Update CharacterBody2D position to apex
	global_position = vertices[0].position

func _update_arm_physics(delta: float) -> void:
	# Spring forces to maintain arm length
	for i in range(1, vertices.size()):
		var arm_vector = vertices[i].position - vertices[0].position
		var current_length = arm_vector.length()
		
		if current_length == 0.0:
			continue
		
		var length_error = current_length - arm_length
		var spring_force_dir = arm_vector.normalized()
		
		# Spring force (Hooke's law)
		var spring_force = -spring_force_dir * length_error * spring_stiffness
		
		# Apply damping
		var damping_force = -vertices[i].velocity * arm_damping
		
		# Total force
		var total_force = spring_force + damping_force
		
		# Update velocity and position
		vertices[i].velocity += (total_force / vertices[i].mass) * delta
		vertices[i].position += vertices[i].velocity * delta

func _apply_environmental_forces(delta: float) -> void:
	# Example: Wind force (can be level-specific)
	var wind_force = Vector2(sin(Time.get_ticks_msec() / 1000.0), cos(Time.get_ticks_msec() / 1500.0))
	wind_force *= environmental_force_strength
	
	# Apply to arms
	for i in range(1, vertices.size()):
		vertices[i].velocity += wind_force * delta

func _handle_stable_movement(_delta: float) -> void:
	# Will be implemented in TriangleController
	pass

# === VISUALS ===
func _update_vertex_positions() -> void:
	for vertex in vertices:
		if vertex.node:
			vertex.node.global_position = vertex.position

func _update_arm_visuals() -> void:
	if arm_visual_1:
		arm_visual_1.clear_points()
		arm_visual_1.add_point(vertices[0].position)
		arm_visual_1.add_point(vertices[1].position)
		arm_visual_1.default_color = Color.CYAN.lerp(Color.MAGENTA, 0.5)
	
	if arm_visual_2:
		arm_visual_2.clear_points()
		arm_visual_2.add_point(vertices[0].position)
		arm_visual_2.add_point(vertices[2].position)
		arm_visual_2.default_color = Color.CYAN.lerp(Color(1.0, 1.0, 0.0), 0.5)

# === ANGLE MEASUREMENT ===
func get_angle_degrees() -> float:
	"""Get the angle between the two arms in degrees"""
	var arm1 = vertices[1].position - vertices[0].position
	var arm2 = vertices[2].position - vertices[0].position
	return rad_to_deg(arm1.angle_to(arm2))

func get_angle_radians() -> float:
	"""Get the angle between the two arms in radians"""
	var arm1 = vertices[1].position - vertices[0].position
	var arm2 = vertices[2].position - vertices[0].position
	return arm1.angle_to(arm2)
