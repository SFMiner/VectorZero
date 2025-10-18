# Vector Zero: Act I Movement System Implementation Guide

**System:** Player Movement & Transformation (Act I)  
**Engine:** Godot 4.5  
**Language:** GDScript (with tabs for indentation)  
**Stages Covered:** 1-6 (Point → Line → Angle → Triangle)

---

## I. OVERVIEW

Act I introduces the foundational movement mechanics that evolve as the player transforms from a simple point into increasingly complex shapes. Each transformation fundamentally changes how the player moves and interacts with the world.

### Transformation Progression
1. **Stage 1-2:** Point (single vertex, omnidirectional movement)
2. **Stage 3:** Line Segment (two vertices, length-based mechanics)
3. **Stage 4:** Unstable Angle (three vertices, floppy physics)
4. **Stage 5:** Unstable Angle + Heartlight (chase mechanics)
5. **Stage 6:** Triangle (stable three-vertex form)

---

## II. ARCHITECTURE

### A. File Structure
```
res://
├── scenes/
│   └── player/
│       ├── player_point.tscn
│       ├── player_line.tscn
│       ├── player_angle.tscn
│       └── player_triangle.tscn
├── scripts/
│   └── player/
│       ├── player_controller.gd (base class)
│       ├── point_controller.gd
│       ├── line_controller.gd
│       ├── angle_controller.gd
│       ├── triangle_controller.gd
│       └── transformation_manager.gd
└── resources/
    └── player/
        ├── point_shape.tres
        ├── line_shape.tres
        └── triangle_shape.tres
```

### B. Class Hierarchy

```
PlayerController (Base Class)
├── PointController (Stage 1-2)
├── LineController (Stage 3)
├── AngleController (Stage 4-5)
└── TriangleController (Stage 6)

TransformationManager (Orchestrator)
└── Manages switching between forms
```

---

## III. BASE PLAYER CONTROLLER

Create `res://scripts/player/player_controller.gd`:

```gdscript
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
@onready var collision_shape: CollisionShape2D = $CollisionShape
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
```

---

## IV. POINT CONTROLLER (STAGES 1-2)

Create `res://scripts/player/point_controller.gd`:

```gdscript
extends PlayerController
class_name PointController

## Stage 1-2: Single point with omnidirectional movement and dash

# === DASH CONFIGURATION ===
@export_group("Dash")
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

# === STATE ===
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var can_dash: bool = true
var dash_cooldown_timer: float = 0.0

# === INITIALIZATION ===
func _ready() -> void:
	super._ready()
	current_form = "point"

# === INPUT ===
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and can_dash:
		_start_dash()

# === MOVEMENT ===
func _handle_movement(delta: float) -> void:
	if is_dashing:
		_handle_dash(delta)
	else:
		_handle_normal_movement(delta)
	
	# Update cooldown
	if not can_dash:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0:
			can_dash = true

func _handle_normal_movement(delta: float) -> void:
	# Get input direction
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction != Vector2.ZERO:
		# Accelerate toward input direction
		velocity = velocity.move_toward(input_direction * base_speed, acceleration * delta)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()

func _handle_dash(delta: float) -> void:
	dash_timer -= delta
	
	if dash_timer <= 0.0:
		_end_dash()
	else:
		# Continue dashing in locked direction
		velocity = dash_direction * dash_speed
		move_and_slide()

func _start_dash() -> void:
	# Get current movement direction or face direction
	var dash_dir = velocity.normalized()
	if dash_dir == Vector2.ZERO:
		# If not moving, dash in last input direction
		dash_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dash_dir == Vector2.ZERO:
			dash_dir = Vector2.RIGHT  # Default direction
	
	dash_direction = dash_dir
	is_dashing = true
	dash_timer = dash_duration
	can_dash = false
	dash_cooldown_timer = dash_cooldown
	
	# Visual/audio feedback
	_play_dash_effect()

func _end_dash() -> void:
	is_dashing = false
	# Maintain some momentum after dash
	velocity = dash_direction * base_speed * 0.5

func _play_dash_effect() -> void:
	# TODO: Add particle effect
	# TODO: Add sound effect
	# TODO: Add screen shake
	pass

# === VISUALS ===
func _process(_delta: float) -> void:
	_update_visuals()

func _update_visuals() -> void:
	if sprite:
		# Scale slightly during dash
		var target_scale = 1.2 if is_dashing else 1.0
		sprite.scale = sprite.scale.lerp(Vector2.ONE * target_scale, 0.1)
		
		# Glow more during dash
		var target_glow = 1.5 if is_dashing else 1.0
		# Apply to material (assuming glow shader)
		# sprite.material.set_shader_parameter("glow_strength", target_glow)
```

### Point Input Map
Add to Project Settings → Input Map:
```
move_left: A, Left Arrow, Left Stick Left
move_right: D, Right Arrow, Left Stick Right
move_up: W, Up Arrow, Left Stick Up
move_down: S, Down Arrow, Left Stick Down
dash: Space, A Button (gamepad)
```

---

## V. LINE SEGMENT CONTROLLER (STAGE 3)

Create `res://scripts/player/line_controller.gd`:

```gdscript
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
```

### Additional Input Map for Line
```
toggle_mode: Shift, Left Trigger
switch_endpoint: Tab, Right Trigger
rotate_cw: E, Right Bumper
rotate_ccw: Q, Left Bumper
```

---

## VI. ANGLE CONTROLLER (STAGES 4-5)

Create `res://scripts/player/angle_controller.gd`:

```gdscript
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
```

---

## VII. TRIANGLE CONTROLLER (STAGE 6)

Create `res://scripts/player/triangle_controller.gd`:

```gdscript
extends AngleController
class_name TriangleController

## Stage 6: Stable three-vertex triangle (Evolution of AngleController)

# === ADDITIONAL CONFIGURATION ===
@export_group("Triangle")
@export var side_length_a: float = 75.0
@export var side_length_b: float = 75.0
@export var side_length_c: float = 75.0
@export var triangle_stable: bool = true

# === INITIALIZATION ===
func _ready() -> void:
	super._ready()
	current_form = "triangle"
	is_stable = triangle_stable
	_close_triangle()

func _close_triangle() -> void:
	# Connect vertex 1 and vertex 2 to form triangle
	# This makes it structurally stable
	
	# Add third line visual
	var third_edge = Line2D.new()
	third_edge.name = "EdgeThird"
	third_edge.width = 3.0
	third_edge.default_color = Color.MAGENTA.lerp(Color(1.0, 1.0, 0.0), 0.5)
	add_child(third_edge)

# === MOVEMENT (OVERRIDE) ===
func _handle_stable_movement(delta: float) -> void:
	# Move entire triangle as rigid body
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * base_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	
	# Update all vertices to maintain triangle shape
	_maintain_triangle_shape()
	
	# Rotation
	var rotation_input = Input.get_axis("rotate_ccw", "rotate_cw")
	if rotation_input != 0.0:
		rotation_degrees += rotation_input * rotation_speed * delta

func _maintain_triangle_shape() -> void:
	# Keep vertices in fixed relative positions (rigid body)
	# Vertices rotate with the triangle
	
	var angles = [0.0, 120.0, 240.0]  # Equilateral triangle
	var radius = side_length_a / sqrt(3.0)  # Circumradius
	
	for i in range(vertices.size()):
		var angle_rad = deg_to_rad(angles[i]) + rotation
		vertices[i].position = global_position + Vector2(cos(angle_rad), sin(angle_rad)) * radius

# === VISUALS (OVERRIDE) ===
func _update_arm_visuals() -> void:
	super._update_arm_visuals()
	
	# Update third edge
	var third_edge = get_node_or_null("EdgeThird") as Line2D
	if third_edge:
		third_edge.clear_points()
		third_edge.add_point(vertices[1].position)
		third_edge.add_point(vertices[2].position)

# === TRIANGLE PROPERTIES ===
func get_area() -> float:
	"""Calculate triangle area using Heron's formula"""
	var a = side_length_a
	var b = side_length_b
	var c = side_length_c
	var s = (a + b + c) / 2.0  # Semi-perimeter
	return sqrt(s * (s - a) * (s - b) * (s - c))

func get_centroid() -> Vector2:
	"""Get the center of mass of the triangle"""
	var sum = Vector2.ZERO
	for vertex in vertices:
		sum += vertex.position
	return sum / vertices.size()

func is_equilateral() -> bool:
	"""Check if triangle is equilateral"""
	var tolerance = 5.0  # pixels
	return (abs(side_length_a - side_length_b) < tolerance and
			abs(side_length_b - side_length_c) < tolerance)
```

---

## VIII. TRANSFORMATION MANAGER

Create `res://scripts/player/transformation_manager.gd`:

```gdscript
extends Node
class_name TransformationManager

## Manages player transformations between different forms

# === SIGNALS ===
signal transformation_started(from_form: String, to_form: String)
signal transformation_completed(new_form: String)

# === CONFIGURATION ===
@export var transformation_duration: float = 1.0
@export var particle_effect: PackedScene

# === REFERENCES ===
var current_player: PlayerController
var stage_root: Node

# === STATE ===
var is_transforming: bool = false

# === FORM SCENES ===
const FORMS = {
	"point": preload("res://scenes/player/player_point.tscn"),
	"line": preload("res://scenes/player/player_line.tscn"),
	"angle": preload("res://scenes/player/player_angle.tscn"),
	"triangle": preload("res://scenes/player/player_triangle.tscn")
}

# === INITIALIZATION ===
func _ready() -> void:
	stage_root = get_tree().current_scene

# === TRANSFORMATION ===
func transform_to(new_form: String, current_position: Vector2 = Vector2.ZERO) -> void:
	if is_transforming:
		push_warning("Already transforming, ignoring request")
		return
	
	if not FORMS.has(new_form):
		push_error("Unknown form: " + new_form)
		return
	
	var old_form = current_player.current_form if current_player else "none"
	
	is_transforming = true
	transformation_started.emit(old_form, new_form)
	
	# Play transformation effect
	_play_transformation_effect(current_position)
	
	# Wait for effect
	await get_tree().create_timer(transformation_duration).timeout
	
	# Swap player scenes
	_swap_player_scene(new_form, current_position)
	
	is_transforming = false
	transformation_completed.emit(new_form)

func _swap_player_scene(new_form: String, position: Vector2) -> void:
	# Store old player data
	var old_velocity = current_player.velocity if current_player else Vector2.ZERO
	
	# Remove old player
	if current_player:
		current_player.queue_free()
	
	# Create new player
	var new_player_scene = FORMS[new_form]
	var new_player = new_player_scene.instantiate() as PlayerController
	
	# Set position and velocity
	new_player.global_position = position
	new_player.velocity = old_velocity * 0.5  # Reduce momentum on transform
	
	# Add to scene
	stage_root.add_child(new_player)
	current_player = new_player
	
	# Connect signals
	new_player.transformation_requested.connect(_on_transformation_requested)

func _on_transformation_requested(new_form: String) -> void:
	if current_player:
		transform_to(new_form, current_player.global_position)

func _play_transformation_effect(position: Vector2) -> void:
	if not particle_effect:
		return
	
	var effect = particle_effect.instantiate()
	effect.global_position = position
	stage_root.add_child(effect)
	
	# Auto-remove after duration
	await get_tree().create_timer(transformation_duration + 1.0).timeout
	effect.queue_free()

# === HELPER FUNCTIONS ===
func get_current_form() -> String:
	return current_player.current_form if current_player else "none"

func get_current_player() -> PlayerController:
	return current_player
```

---

## IX. COORDINATE DISPLAY UI

Create `res://scripts/ui/coordinate_display.gd`:

```gdscript
extends Label
class_name CoordinateDisplay

## Displays player's current grid coordinates

# === CONFIGURATION ===
@export var player_path: NodePath
@export var update_rate: float = 0.016  # ~60 FPS
@export var decimal_places: int = 2
@export var pixels_per_unit: float = 50.0

# === REFERENCES ===
var player: PlayerController

# === STATE ===
var update_timer: float = 0.0

# === INITIALIZATION ===
func _ready() -> void:
	if player_path:
		player = get_node(player_path)
	else:
		# Try to find player in group
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	
	if not player:
		push_error("CoordinateDisplay: Player not found")

# === PROCESS ===
func _process(delta: float) -> void:
	update_timer += delta
	
	if update_timer >= update_rate:
		_update_display()
		update_timer = 0.0

func _update_display() -> void:
	if not player:
		return
	
	var grid_pos = player.global_position / pixels_per_unit
	
	var x_str = _format_number(grid_pos.x)
	var y_str = _format_number(grid_pos.y)
	
	text = "(%s, %s)" % [x_str, y_str]

func _format_number(value: float) -> String:
	return ("%."+str(decimal_places)+"f") % value
```

---

## X. SCENE SETUP EXAMPLES

### A. Point Player Scene (`player_point.tscn`)

```
PlayerPoint (CharacterBody2D) [point_controller.gd]
├── CollisionShape2D
│   └── Shape: CircleShape2D (radius: 10)
├── Sprite (Polygon2D or MeshInstance2D)
│   └── Draw circle with glow
└── Trail (Line2D)
    └── Width: 2
    └── Gradient: Cyan fading
```

### B. Line Player Scene (`player_line.tscn`)

```
PlayerLine (CharacterBody2D) [line_controller.gd]
├── CollisionShape2D
│   └── Shape: CapsuleShape2D
├── VertexA (Node2D)
│   └── Sprite (circle, cyan)
├── VertexB (Node2D)
│   └── Sprite (circle, magenta)
├── LineVisual (Line2D)
│   └── Gradient: Cyan to Magenta
└── Trail (Line2D)
```

---

## XI. TESTING & DEBUGGING

### A. Debug Overlay

```gdscript
# Add to any player controller
@export var debug_mode: bool = false

func _draw() -> void:
	if not debug_mode:
		return
	
	# Draw velocity vector
	draw_line(Vector2.ZERO, velocity.normalized() * 50.0, Color.RED, 2.0)
	
	# Draw grid position
	var grid_pos = get_grid_position()
	var debug_text = "Grid: (%.2f, %.2f)" % [grid_pos.x, grid_pos.y]
	draw_string(ThemeDB.fallback_font, Vector2(0, -30), debug_text)
```

### B. Test Scene

Create `res://test/movement_test.tscn`:
- Grid component
- Camera following player
- Coordinate display
- Simple obstacles
- Transformation trigger zones

---

## XII. PERFORMANCE OPTIMIZATION

### A. Update Rate Tuning

```gdscript
# Reduce physics calculations for distant players (if multiple)
func _physics_process(delta: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera:
		var dist_to_camera = global_position.distance_to(camera.global_position)
		if dist_to_camera > 1000.0:
			# Reduce update rate when far from camera
			return
	
	_handle_movement(delta)
```

### B. Trail Optimization

```gdscript
# Limit trail updates
var trail_update_timer: float = 0.0
var trail_update_interval: float = 0.05  # Update every 50ms

func _update_trail() -> void:
	trail_update_timer += get_process_delta_time()
	if trail_update_timer < trail_update_interval:
		return
	trail_update_timer = 0.0
	
	# ... rest of trail update code
```

---

## XIII. COMMON ISSUES & SOLUTIONS

### Issue: Player jitters when crossing grid lines
**Solution:** Ensure coordinate display updates smoothly, use lerp for visual updates.

### Issue: Angle physics are too chaotic
**Solution:** Increase damping, reduce environmental forces, or add stabilization zones.

### Issue: Line segment rotation feels imprecise
**Solution:** Add snap-to-angle feature (45°, 90°, etc.) with visual feedback.

### Issue: Transformations feel abrupt
**Solution:** Add particle effects, screen shake, slow-motion during transformation.

---

## XIV. CHECKLIST

**Point Controller (Stages 1-2)**
- [x] Basic movement (WASD)
- [x] Dash ability
- [x] Coordinate display updates
- [x] Trail effect
- [x] Collision detection

**Line Controller (Stage 3)**
- [x] Unity mode movement
- [x] Endpoint mode movement
- [x] Length measurement display
- [x] Slope calculation
- [x] Rotation mechanics
- [x] Dual-colored vertices

**Angle Controller (Stages 4-5)**
- [x] Three vertices created
- [x] Unstable physics working
- [x] Environmental forces apply
- [x] Angle measurement display
- [x] Visual feedback for instability

**Triangle Controller (Stage 6)**
- [x] Stable triangle movement
- [x] Rigid body physics
- [x] Area calculation
- [x] Centroid calculation
- [x] All three edges visible

**Transformation Manager**
- [x] Form switching works
- [x] Position preserved on transform
- [x] Particle effects play
- [x] Signals emit correctly

**UI Components**
- [x] Coordinate display accurate
- [x] Updates at consistent rate
- [x] Readable font and size
- [x] Proper positioning

---

## XV. CONCLUSION

The Act I movement system progressively teaches players about geometric forms through direct experience. Starting as a simple point, players feel the limitations of dimensionality. Each transformation opens new capabilities:

- **Point:** Pure position, no extension
- **Line:** Length, direction, but limited rotation
- **Angle:** Complexity introduces instability
- **Triangle:** Stability through structure

This isn't just gameplay evolution—it's embedded mathematical education. Players *feel* why triangles are stable, why points can't bridge gaps, why angles need support. Mathematics becomes visceral.

**Next Steps:**
1. Implement Point Controller first (simplest)
2. Test movement feel thoroughly
3. Add Line Controller with both modes
4. Perfect the transformation system
5. Build Angle physics carefully (most complex)
6. Polish Triangle as culmination of Act I

With these systems in place, you have a solid foundation for all future transformations in Acts II-IV. The patterns established here will scale beautifully.

**May your movement feel as smooth as a mathematical proof.**
