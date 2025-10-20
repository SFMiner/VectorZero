extends Area2D
class_name DialogueTrigger

## Triggers dialogue when player enters area, via timer, or manual call

# === SIGNALS ===
signal dialogue_triggered(character: String, text: String)

# === CONFIGURATION ===
@export var character_name: String = "Vector Zero"
@export_multiline var dialogue_text: String = ""
@export var trigger_once: bool = true
@export var pixels_per_unit: float = 50.0

## If > 0, automatically triggers after this delay on _ready()
@export var auto_trigger_delay: float = 0.0

## Maximum number of activations. If <= 0, infinite activations allowed.
## Counts down with each trigger (both area and timed).
@export var max_activations: int = 1

# === STATE ===
var has_triggered: bool = false
var timed_activations: int = 0
var area_activations: int = 0

# === INITIALIZATION ===
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false
	
	# Auto-trigger if delay is set
	if auto_trigger_delay > 0.0:
		trigger_after_delay(auto_trigger_delay)

# === PUBLIC METHODS ===
## Manually trigger dialogue immediately (counts as timed activation)
func trigger_manually() -> void:
	if _can_trigger():
		_trigger_dialogue(true)

## Trigger dialogue after a specified delay (counts as timed activation)
func trigger_after_delay(delay: float) -> void:
	if _can_trigger():
		await get_tree().create_timer(delay).timeout
		if _can_trigger():  # Check again in case something changed during wait
			_trigger_dialogue(true)

# === CALLBACKS ===
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if _can_trigger():
			_trigger_dialogue(false)

# === HELPER METHODS ===
## Check if this trigger can still fire
func _can_trigger() -> bool:
	# Check legacy trigger_once flag
	if has_triggered and trigger_once:
		return false
	
	# Check max_activations counter
	if max_activations > 0 and (timed_activations + area_activations) >= max_activations:
		return false
	
	return true

## Fire the dialogue trigger
## @param is_timed: true for timer/manual triggers, false for area triggers
func _trigger_dialogue(is_timed: bool) -> void:
	has_triggered = true
	
	# Increment appropriate counter
	if is_timed:
		timed_activations += 1
	else:
		area_activations += 1
	
	# Emit the signal
	dialogue_triggered.emit(character_name, dialogue_text)
	
	# Disable area monitoring if we've hit the limit
	var total_activations = timed_activations + area_activations
	if trigger_once or (max_activations > 0 and total_activations >= max_activations):
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
