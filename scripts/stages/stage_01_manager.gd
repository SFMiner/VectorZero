extends Node
class_name Stage01Manager

## Stage 01: The Point - Manager Script
##
## This manager script orchestrates Stage 1's gameplay flow and narrative experience.
## It is responsible for creating and managing dialogue triggers that introduce the player
## to Vector Zero's story and the game's coordinate-based mechanics.
##
## @tutorial(Stage Design): See Vector_Zero_Game_Design_Document_v2.md for stage philosophy
## @tutorial(Next Steps): See "Next Steps 2.md" for Stage 01 implementation details

# === CONFIGURATION ===
## Path to the DialogueDisplay UI component (typically in CanvasLayer)
@export var dialogue_display_path: NodePath

## Path to the parent node that will contain all dialogue trigger areas
@export var dialogue_triggers_parent_path: NodePath

## Path to the player node. If not set, will search for node in "player" group
@export var player_path: NodePath

## Scaling factor: 1 grid unit = this many pixels in world space
## Must match the value used in grid_renderer, coordinate_display, and grid_pulse_manager
@export var pixels_per_unit: float = 500.0

# === REFERENCES ===
## Reference to the dialogue UI display system
var dialogue_display: DialogueDisplay

## Parent node where dialogue trigger Area2D nodes are added as children
var dialogue_triggers_parent: Node2D

## Reference to the player's controller for position tracking
var player: PlayerController

# === STATE ===
## Tracks whether the player has moved from the origin (0,0)
## Used to detect the first moment of player agency
var has_moved: bool = false

## Prevents the "first movement" dialogue from triggering multiple times
var first_movement_triggered: bool = false

# === INITIALIZATION ===
## Called when the node enters the scene tree
## Initializes all references and sets up the stage's dialogue system
func _ready() -> void:
	_get_references()
	player.freeze()
	_create_dialogue_triggers()
	_connect_player_signals()

## Resolves NodePath exports to actual node references
## Falls back to searching the "player" group if player_path is not set
## Emits errors if critical references cannot be found
func _get_references() -> void:
	# Get dialogue display reference
	if dialogue_display_path:
		dialogue_display = get_node(dialogue_display_path)

	# Get dialogue triggers parent reference
	if dialogue_triggers_parent_path:
		dialogue_triggers_parent = get_node(dialogue_triggers_parent_path)

	# Get player reference (with fallback to group search)
	if player_path:
		player = get_node(player_path)
	else:
		# Fallback: search for any node in the "player" group
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	# Validate all critical references were found
	if not dialogue_display:
		push_error("Stage01Manager: DialogueDisplay not found")
	if not dialogue_triggers_parent:
		push_error("Stage01Manager: DialogueTriggers parent not found")
	if not player:
		push_error("Stage01Manager: Player not found")

## Connects to player signals for position-based dialogue triggers
## Currently monitors position_changed to detect first movement
func _connect_player_signals() -> void:
	if player:
		player.position_changed.connect(_on_player_position_changed)

## Creates all dialogue trigger areas for Stage 01
## Each trigger is an Area2D positioned at specific grid coordinates
## Triggers activate when the player enters their collision radius
##
## Stage 01 Narrative Flow:
## 1. Origin (0,0): "I am here" - establishes Vector Zero's initial awareness
## 2. Origin (0,0): "I feel confined" - motivates exploration
## 3. First Movement: "I can move!" - celebrates player agency (signal-based, not area)
## 4. Integer Coordinates (2,2), (5,5), (8,8): Grid feedback - reinforces coordinate awareness
## 5. Goal (10,10): "I've reached further" - completes stage, teases transformation
func _create_dialogue_triggers() -> void:
	if not dialogue_triggers_parent:
		return

	# === ORIGIN DIALOGUE (0, 0) ===
	# First realization: Vector Zero becomes aware of their position
	# Uses auto_trigger_delay to fire immediately on spawn
	var origin_trigger = _create_trigger(
		Vector2(0, 0),
		30.0,
		"Vector Zero",
		"I am... here. Defined by my position."
	)
	origin_trigger.auto_trigger_delay = 0.5  # Trigger 0.5 seconds after scene loads
	origin_trigger.max_activations = 1
	dialogue_triggers_parent.add_child(origin_trigger)

	# Second realization: Vector Zero feels limited, desires more
	# Triggers shortly after the first dialogue
	var origin_trigger_2 = _create_trigger(
		Vector2(0, 0),
		50.0,
		"Vector Zero",
		"But I feel... confined. There must be more."
	)
	origin_trigger_2.auto_trigger_delay = 3.5  # Trigger 3.5 seconds after scene loads
	origin_trigger_2.max_activations = 1
	dialogue_triggers_parent.add_child(origin_trigger_2)

	# === INTEGER COORDINATE FEEDBACK ===
	# Positioned along common paths through the maze
	# Reinforces that the grid "responds" to the player without explicit teaching
	# These mirror the grid pulse mechanic's purpose: implicit coordinate awareness
	var coord_positions = [Vector2(2, 2), Vector2(5, 5), Vector2(8, 8)]
	for pos in coord_positions:
		var coord_trigger = _create_trigger(
			pos,
			25.0,
			"Vector Zero",
			"The space responds to me..."
		)
		dialogue_triggers_parent.add_child(coord_trigger)

	# === GOAL DIALOGUE (10, 10) ===
	# Stage completion: teases future transformation and growth
	var goal_trigger = _create_trigger(
		Vector2(10, 10),
		40.0,
		"Vector Zero",
		"I've reached further than I thought possible. What else lies beyond?"
	)
	dialogue_triggers_parent.add_child(goal_trigger)

## Creates a single dialogue trigger at a grid position
## @param grid_pos: Position in grid coordinates (e.g., Vector2(5, 3) = 5 units right, 3 units up)
## @param radius: Activation radius in world pixels
## @param character: Character name displayed in dialogue UI
## @param text: Dialogue text to display
## @return: Configured DialogueTrigger node, ready to be added to the scene tree
func _create_trigger(grid_pos: Vector2, radius: float, character: String, text: String) -> DialogueTrigger:
	var trigger = DialogueTrigger.create_at_position(grid_pos, radius, character, text, pixels_per_unit)
	trigger.dialogue_triggered.connect(_on_dialogue_triggered)
	return trigger

# === CALLBACKS ===
## Callback when any dialogue trigger is activated
## Routes the dialogue request to the DialogueDisplay UI system
## @param character: Name of the character speaking (affects color/styling)
## @param text: The dialogue text to display
func _on_dialogue_triggered(character: String, text: String) -> void:
	if dialogue_display:
		dialogue_display.show_dialogue(character, text)

## Callback when the player's position changes
## Monitors for the "first movement" moment and triggers celebratory dialogue
##
## This implements a special narrative beat: the moment Vector Zero realizes
## they can move freely. Unlike area-based triggers, this is signal-based
## to capture the exact moment of first agency.
##
## @param new_position: Player's new world position
func _on_player_position_changed(new_position: Vector2) -> void:
	# Check if player has moved more than 5 pixels from origin
	# (Small threshold to avoid triggering from floating-point drift)
	if not has_moved and new_position.length() > 5.0:
		has_moved = true

	# Trigger dialogue on first movement (with slight delay for pacing)
	if has_moved and not first_movement_triggered:
		first_movement_triggered = true
		await get_tree().create_timer(0.5).timeout
		_on_dialogue_triggered("Vector Zero", "I can move! I exist beyond this point!")


func _on_immobility_timer_timeout() -> void:
	player.set_free() # Replace with function body.
