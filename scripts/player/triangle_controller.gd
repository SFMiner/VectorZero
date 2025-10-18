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
	# The third edge should already exist in the scene as EdgeThird
	var third_edge = get_node_or_null("EdgeThird") as Line2D
	if third_edge:
		third_edge.width = 3.0
		third_edge.default_color = Color.MAGENTA.lerp(Color(1.0, 1.0, 0.0), 0.5)

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
