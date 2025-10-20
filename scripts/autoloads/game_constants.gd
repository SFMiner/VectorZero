extends Node

## Global game constants
## Single source of truth for coordinate system values

# === COORDINATE SYSTEM ===
## Pixels per grid unit - THIS IS THE MASTER VALUE
## All coordinate conversions MUST use this value
const PIXELS_PER_UNIT: float = 50.0

# === DERIVED VALUES ===
## These are calculated from PIXELS_PER_UNIT for convenience
const GRID_MAJOR_SPACING: float = PIXELS_PER_UNIT * 5.0  # Major grid lines every 5 units

# === CONVERSION FUNCTIONS ===
static func world_to_grid(world_pos: Vector2) -> Vector2:
	"""Convert world pixel position to grid coordinates"""
	return world_pos / PIXELS_PER_UNIT

static func grid_to_world(grid_pos: Vector2) -> Vector2:
	"""Convert grid coordinates to world pixel position"""
	return grid_pos * PIXELS_PER_UNIT

static func world_to_grid_scalar(world_value: float) -> float:
	"""Convert a world pixel distance to grid units"""
	return world_value / PIXELS_PER_UNIT

static func grid_to_world_scalar(grid_value: float) -> float:
	"""Convert grid units to world pixel distance"""
	return grid_value * PIXELS_PER_UNIT
