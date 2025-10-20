@tool
extends Node2D
class_name ManualMazeLayout

## Manual maze layout system
## Place Line2D nodes as children, and this script automatically generates collision shapes
## Also supports ColorRect and other shapes
##
## IMPORTANT: Requires GameConstants autoload for coordinate system consistency
## Make sure game_constants.gd is added to Project Settings → Autoload as "GameConstants"

# === CONFIGURATION ===
@export var auto_generate_on_ready: bool = true
@export var wall_collision_width: float = 3.0
@export var parent_collisions_to_visuals: bool = true

# Note: pixels_per_unit is now read from GameConstants.PIXELS_PER_UNIT
# This ensures consistency across all coordinate conversions
@export_group("Supported Node Types")
@export var process_line2d: bool = true
@export var process_color_rects: bool = true
@export var process_polygons: bool = true

# === EDITOR TOOLS ===
@export var generate_collisions: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_generate_all_collisions()
			generate_collisions = false

@export var clear_collisions: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_clear_all_collisions()
			clear_collisions = false

# === INITIALIZATION ===
func _ready() -> void:
	if not Engine.is_editor_hint() and auto_generate_on_ready:
		_generate_all_collisions()

# === COLLISION GENERATION ===
func _generate_all_collisions() -> void:
	print("ManualMazeLayout: Generating collisions...")
	
	var collision_count = 0
	
	# Process all children recursively
	for child in get_children():
		collision_count += _process_node(child)
	
	print("ManualMazeLayout: Generated ", collision_count, " collision shapes")

func _process_node(node: Node) -> int:
	var count = 0
	
	# Process Line2D nodes
	if process_line2d and node is Line2D:
		count += _create_collisions_for_line2d(node)
	
	# Process ColorRect nodes
	elif process_color_rects and node is ColorRect:
		count += _create_collision_for_color_rect(node)
	
	# Process Polygon2D nodes
	elif process_polygons and node is Polygon2D:
		count += _create_collision_for_polygon(node)
	
	# Recursively process children
	for child in node.get_children():
		count += _process_node(child)
	
	return count

# === LINE2D COLLISION GENERATION ===
func _create_collisions_for_line2d(line: Line2D) -> int:
	var points = line.points
	if points.size() < 2:
		return 0
	
	var collision_count = 0
	
	# Create a collision segment for each pair of consecutive points
	for i in range(points.size() - 1):
		var start_point = points[i]
		var end_point = points[i + 1]
		
		_create_wall_segment(line, start_point, end_point, i)
		collision_count += 1
	
	return collision_count

func _create_wall_segment(line: Line2D, local_start: Vector2, local_end: Vector2, segment_index: int) -> void:
	# Calculate segment properties in line's local space
	var segment_vector = local_end - local_start
	var segment_length = segment_vector.length()
	var segment_angle = segment_vector.angle()
	var segment_center = (local_start + local_end) / 2.0
	
	# Create StaticBody2D
	var wall_body = StaticBody2D.new()
	wall_body.name = "Collision_Segment_%d" % segment_index
	
	# Parent to the Line2D or to this node
	if parent_collisions_to_visuals:
		line.add_child(wall_body)
		if Engine.is_editor_hint():
			wall_body.owner = get_tree().edited_scene_root
	else:
		add_child(wall_body)
		if Engine.is_editor_hint():
			wall_body.owner = get_tree().edited_scene_root
		# Need to convert to global space if not parented to line
		wall_body.global_position = line.global_position
	
	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	shape.size = Vector2(segment_length, wall_collision_width)
	collision.shape = shape
	collision.position = segment_center
	collision.rotation = segment_angle
	
	wall_body.add_child(collision)
	if Engine.is_editor_hint():
		collision.owner = get_tree().edited_scene_root

# === COLORRECT COLLISION GENERATION ===
func _create_collision_for_color_rect(rect: ColorRect) -> int:
	# Create a single rectangular collision for the ColorRect
	var wall_body = StaticBody2D.new()
	wall_body.name = "Collision"
	
	# Parent to the ColorRect or to this node
	if parent_collisions_to_visuals:
		rect.add_child(wall_body)
		if Engine.is_editor_hint():
			wall_body.owner = get_tree().edited_scene_root
	else:
		add_child(wall_body)
		if Engine.is_editor_hint():
			wall_body.owner = get_tree().edited_scene_root
		wall_body.global_position = rect.global_position
	
	# Create collision shape matching the ColorRect size
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.size / 2.0  # Center of the rect
	
	wall_body.add_child(collision)
	if Engine.is_editor_hint():
		collision.owner = get_tree().edited_scene_root
	
	return 1

# === POLYGON2D COLLISION GENERATION ===
func _create_collision_for_polygon(polygon: Polygon2D) -> int:
	var points = polygon.polygon
	if points.size() < 3:
		return 0
	
	# Create StaticBody2D
	var wall_body = StaticBody2D.new()
	wall_body.name = "Collision"
	
	# Parent to the Polygon2D or to this node
	if parent_collisions_to_visuals:
		polygon.add_child(wall_body)
		if Engine.is_editor_hint():
			wall_body.owner = get_tree().edited_scene_root
	else:
		add_child(wall_body)
		if Engine.is_editor_hint():
			wall_body.owner = get_tree().edited_scene_root
		wall_body.global_position = polygon.global_position
	
	# Create collision polygon
	var collision = CollisionPolygon2D.new()
	collision.polygon = points
	
	wall_body.add_child(collision)
	if Engine.is_editor_hint():
		collision.owner = get_tree().edited_scene_root
	
	return 1

# === COLLISION CLEANUP ===
func _clear_all_collisions() -> void:
	print("ManualMazeLayout: Clearing all generated collisions...")
	
	var cleared_count = 0
	
	# Clear collisions from children
	for child in get_children():
		cleared_count += _clear_collisions_from_node(child)
	
	# Clear any StaticBody2D children directly under this node
	for child in get_children():
		if child is StaticBody2D:
			if Engine.is_editor_hint():
				child.queue_free()
			else:
				child.free()
			cleared_count += 1
	
	print("ManualMazeLayout: Cleared ", cleared_count, " collision shapes")

func _clear_collisions_from_node(node: Node) -> int:
	var count = 0
	
	# Remove any StaticBody2D children (these are our generated collisions)
	for child in node.get_children():
		if child is StaticBody2D:
			if Engine.is_editor_hint():
				child.queue_free()
			else:
				child.free()
			count += 1
	
	# Recursively clear from children
	for child in node.get_children():
		if not child is StaticBody2D:  # Don't recurse into bodies we're about to delete
			count += _clear_collisions_from_node(child)
	
	return count
