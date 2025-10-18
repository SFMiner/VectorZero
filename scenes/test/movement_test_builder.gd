extends Node2D

## Movement Test Scene - Auto Setup
## This script automatically builds the test scene on first run

var grid_scene = preload("res://scenes/components/grid.tscn")
var player_scene = preload("res://scenes/player/player_point.tscn")
var pulse_manager_script = preload("res://scripts/grid/grid_pulse_manager.gd")
var coord_display_script = preload("res://scripts/ui/coordinate_display.gd")

var grid: Node2D
var player: CharacterBody2D
var camera: Camera2D
var pulse_manager: Node
var ui_layer: CanvasLayer
var coord_display: Label

func _ready() -> void:
	_build_scene()
	print("=== Movement Test Scene Ready ===")
	print("Controls:")
	print("  WASD - Move")
	print("  Space - Dash")
	print("  ESC - Quit")
	print("================================")

func _build_scene() -> void:
	# Instance Grid
	grid = grid_scene.instantiate()
	add_child(grid)
	grid.name = "Grid"
	
	# Instance Player
	player = player_scene.instantiate()
	add_child(player)
	player.name = "Player"
	player.global_position = Vector2.ZERO
	
	# Add Camera to Player
	camera = Camera2D.new()
	player.add_child(camera)
	camera.name = "Camera2D"
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	# Add Grid Pulse Manager
	pulse_manager = Node.new()
	add_child(pulse_manager)
	pulse_manager.name = "GridPulseManager"
	pulse_manager.set_script(pulse_manager_script)
	
	# Wait one frame for player to be ready, then set paths
	await get_tree().process_frame
	pulse_manager.set("player_path", pulse_manager.get_path_to(player))
	pulse_manager.set("grid_renderer_path", pulse_manager.get_path_to(grid))
	
	# Create UI Layer
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	ui_layer.name = "UI"
	
	# Add Coordinate Display
	coord_display = Label.new()
	ui_layer.add_child(coord_display)
	coord_display.name = "CoordinateDisplay"
	coord_display.position = Vector2(10, 10)
	coord_display.text = "(0.00, 0.00)"
	coord_display.add_theme_font_size_override("font_size", 24)
	coord_display.set_script(coord_display_script)
	
	# Wait one more frame then set coordinate display path
	await get_tree().process_frame
	coord_display.set("player_path", coord_display.get_path_to(player))
	
	# Add Instructions Label
	var instructions = Label.new()
	ui_layer.add_child(instructions)
	instructions.name = "Instructions"
	instructions.position = Vector2(10, 60)
	instructions.text = "WASD: Move\nSpace: Dash\nESC: Quit"
	instructions.add_theme_font_size_override("font_size", 20)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
