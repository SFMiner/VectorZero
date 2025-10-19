extends Area2D
class_name DialogueTrigger

## Triggers dialogue when player enters area

# === SIGNALS ===
signal dialogue_triggered(character: String, text: String)

# === CONFIGURATION ===
@export var character_name: String = "Vector Zero"
@export_multiline var dialogue_text: String = ""
@export var trigger_once: bool = true
@export var pixels_per_unit: float = 50.0

# === STATE ===
var has_triggered: bool = false

# === INITIALIZATION ===
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false

# === CALLBACKS ===
func _on_body_entered(body: Node2D) -> void:
	if has_triggered and trigger_once:
		return

	if body.is_in_group("player"):
		_trigger_dialogue()

func _trigger_dialogue() -> void:
	has_triggered = true
	dialogue_triggered.emit(character_name, dialogue_text)

	if trigger_once:
		monitoring = false

# === HELPER ===
static func create_at_position(grid_pos: Vector2, radius: float, character: String, text: String, ppu: float = 50.0) -> DialogueTrigger:
	var trigger = DialogueTrigger.new()
	trigger.position = grid_pos * ppu
	trigger.character_name = character
	trigger.dialogue_text = text
	trigger.pixels_per_unit = ppu

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	trigger.add_child(collision)

	return trigger
