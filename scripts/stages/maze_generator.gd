extends Node2D
class_name MazeGenerator

## Simple maze generator for Stage 01
## Creates wall segments as StaticBody2D with Line2D visuals

# === CONFIGURATION ===
@export var pixels_per_unit: float = 50.0
@export var wall_color: Color = Color(0.2, 0.5, 0.6, 1.0)
@export var wall_width: float = 3.0
@export var wall_collision_width: float = 10.0

# === INITIALIZATION ===
func _ready() -> void:
	_generate_stage_01_maze()

# === MAZE GENERATION ===
func _generate_stage_01_maze() -> void:
	# Simple maze from (0,0) to (10,10)
	# Format: [start_x, start_y, end_x, end_y] in grid coordinates

	var walls = [
		# Outer boundary walls
		[-2, -2, 12, -2],	# Bottom boundary
		[-2, -2, -2, 12],	# Left boundary
		[12, -2, 12, 12],	# Right boundary
		[-2, 12, 12, 12],	# Top boundary

		# Maze interior walls (creating paths and dead ends)
		# Main path obstacles
		[2, -1, 2, 3],		# First vertical wall
		[4, 2, 4, 6],		# Second vertical wall
		[6, 1, 6, 4],		# Third vertical wall
		[8, 3, 8, 8],		# Fourth vertical wall

		# Horizontal walls creating maze structure
		[0, 2, 3, 2],		# Bottom horizontal
		[1, 5, 5, 5],		# Middle horizontal
		[6, 7, 9, 7],		# Upper horizontal
		[3, 9, 7, 9],		# Near top horizontal

		# Dead end walls
		[5, 3, 7, 3],		# Dead end 1
		[9, 5, 11, 5],		# Dead end 2
		[7, 10, 10, 10],	# Dead end 3

		# Goal area frame (open on one side)
		[9, 9, 11, 9],		# Goal bottom
		[11, 9, 11, 11],	# Goal right
		[9, 11, 11, 11],	# Goal top
	]

	for wall_data in walls:
		_create_wall_segment(
			Vector2(wall_data[0], wall_data[1]),
			Vector2(wall_data[2], wall_data[3])
		)

	# Create goal marker at (10, 10)
	_create_goal_marker(Vector2(10, 10))

func _create_wall_segment(grid_start: Vector2, grid_end: Vector2) -> void:
	# Convert grid coordinates to world position
	var world_start = grid_start * pixels_per_unit
	var world_end = grid_end * pixels_per_unit

	# Create StaticBody2D for collision
	var wall_body = StaticBody2D.new()
	wall_body.name = "Wall_%d_%d_to_%d_%d" % [grid_start.x, grid_start.y, grid_end.x, grid_end.y]
	add_child(wall_body)

	# Create collision shape (rectangle along the line)
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	# Calculate shape dimensions and position
	var segment_vector = world_end - world_start
	var segment_length = segment_vector.length()
	var segment_angle = segment_vector.angle()

	shape.size = Vector2(segment_length, wall_collision_width)
	collision.shape = shape
	collision.position = (world_start + world_end) / 2.0
	collision.rotation = segment_angle

	wall_body.add_child(collision)

	# Create Line2D for visual representation
	var line = Line2D.new()
	line.width = wall_width
	line.default_color = wall_color
	line.add_point(world_start)
	line.add_point(world_end)
	line.antialiased = true

	add_child(line)

func _create_goal_marker(grid_pos: Vector2) -> void:
	# Create a glowing goal area at the target position
	var world_pos = grid_pos * pixels_per_unit

	# Create visual marker (pulsing circle)
	var marker = Node2D.new()
	marker.name = "GoalMarker"
	marker.position = world_pos
	add_child(marker)

	# Outer circle
	var outer_circle = Line2D.new()
	outer_circle.width = 2.0
	outer_circle.default_color = Color(0, 1, 0, 0.5)
	var points = _generate_circle_points(30.0, 32)
	for point in points:
		outer_circle.add_point(point)
	outer_circle.add_point(points[0])	# Close the circle
	marker.add_child(outer_circle)

	# Inner circle
	var inner_circle = Line2D.new()
	inner_circle.width = 3.0
	inner_circle.default_color = Color(0, 1, 0, 0.8)
	points = _generate_circle_points(15.0, 16)
	for point in points:
		inner_circle.add_point(point)
	inner_circle.add_point(points[0])	# Close the circle
	marker.add_child(inner_circle)

func _generate_circle_points(radius: float, num_points: int) -> Array:
	var points = []
	for i in range(num_points):
		var angle = (i / float(num_points)) * TAU
		var x = cos(angle) * radius
		var y = sin(angle) * radius
		points.append(Vector2(x, y))
	return points
