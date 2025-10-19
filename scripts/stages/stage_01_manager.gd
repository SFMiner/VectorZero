extends Node
class_name Stage01Manager

## Stage 01: The Point - Manager script
## Handles dialogue triggers and stage-specific logic

# === CONFIGURATION ===
@export var dialogue_display_path: NodePath
@export var dialogue_triggers_parent_path: NodePath
@export var player_path: NodePath
@export var pixels_per_unit: float = 50.0

# === REFERENCES ===
var dialogue_display: DialogueDisplay
var dialogue_triggers_parent: Node2D
var player: PlayerController

# === STATE ===
var has_moved: bool = false
var first_movement_triggered: bool = false

# === INITIALIZATION ===
func _ready() -> void:
	_get_references()
	_create_dialogue_triggers()
	_connect_player_signals()

func _get_references() -> void:
	if dialogue_display_path:
		dialogue_display = get_node(dialogue_display_path)
	if dialogue_triggers_parent_path:
		dialogue_triggers_parent = get_node(dialogue_triggers_parent_path)
	if player_path:
		player = get_node(player_path)
	else:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	if not dialogue_display:
		push_error("Stage01Manager: DialogueDisplay not found")
	if not dialogue_triggers_parent:
		push_error("Stage01Manager: DialogueTriggers parent not found")
	if not player:
		push_error("Stage01Manager: Player not found")

func _connect_player_signals() -> void:
	if player:
		player.position_changed.connect(_on_player_position_changed)

func _create_dialogue_triggers() -> void:
	if not dialogue_triggers_parent:
		return

	# Origin dialogue trigger (0, 0)
	var origin_trigger = _create_trigger(
		Vector2(0, 0),
		30.0,
		"Vector Zero",
		"I am... here. Defined by my position."
	)
	dialogue_triggers_parent.add_child(origin_trigger)

	# Second part of origin dialogue
	var origin_trigger_2 = _create_trigger(
		Vector2(0, 0),
		50.0,
		"Vector Zero",
		"But I feel... confined. There must be more."
	)
	dialogue_triggers_parent.add_child(origin_trigger_2)

	# Integer coordinate triggers (create a few along the path)
	var coord_positions = [Vector2(2, 2), Vector2(5, 5), Vector2(8, 8)]
	for pos in coord_positions:
		var coord_trigger = _create_trigger(
			pos,
			25.0,
			"Vector Zero",
			"The space responds to me..."
		)
		dialogue_triggers_parent.add_child(coord_trigger)

	# Goal trigger at (10, 10)
	var goal_trigger = _create_trigger(
		Vector2(10, 10),
		40.0,
		"Vector Zero",
		"I've reached further than I thought possible. What else lies beyond?"
	)
	dialogue_triggers_parent.add_child(goal_trigger)

func _create_trigger(grid_pos: Vector2, radius: float, character: String, text: String) -> DialogueTrigger:
	var trigger = DialogueTrigger.create_at_position(grid_pos, radius, character, text, pixels_per_unit)
	trigger.dialogue_triggered.connect(_on_dialogue_triggered)
	return trigger

# === CALLBACKS ===
func _on_dialogue_triggered(character: String, text: String) -> void:
	if dialogue_display:
		dialogue_display.show_dialogue(character, text)

func _on_player_position_changed(new_position: Vector2) -> void:
	# Trigger "first movement" dialogue after player moves
	if not has_moved and new_position.length() > 5.0:
		has_moved = true

	if has_moved and not first_movement_triggered:
		first_movement_triggered = true
		await get_tree().create_timer(0.5).timeout
		_on_dialogue_triggered("Vector Zero", "I can move! I exist beyond this point!")
