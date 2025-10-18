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
