extends PanelContainer
class_name DialogueDisplay

## Simple dialogue display for Vector Zero
## Shows character name and dialogue text

# === SIGNALS ===
signal dialogue_finished

# === CONFIGURATION ===
@export var text_speed: float = 0.05	# Seconds per character
@export var auto_advance_delay: float = 2.0	# Seconds after text completes
@export var fade_duration: float = 0.3

# === REFERENCES ===
@onready var character_label: Label = $Margin/VBox/CharacterName
@onready var text_label: Label = $Margin/VBox/DialogueText

# === STATE ===
var current_text: String = ""
var display_index: int = 0
var text_timer: float = 0.0
var auto_advance_timer: float = 0.0
var is_displaying: bool = false
var is_complete: bool = false

# === CHARACTER COLORS ===
var character_colors = {
	"Vector Zero": Color.CYAN,
	"Echo": Color.MAGENTA,
	"Axiom": Color.YELLOW,
	"Narrator": Color.WHITE,
}

# === INITIALIZATION ===
func _ready() -> void:
	hide()
	modulate.a = 0.0

# === PROCESS ===
func _process(delta: float) -> void:
	if not is_displaying:
		return

	if not is_complete:
		_update_text_display(delta)
	else:
		_update_auto_advance(delta)

func _update_text_display(delta: float) -> void:
	text_timer += delta

	if text_timer >= text_speed:
		text_timer = 0.0
		display_index += 1

		if display_index > current_text.length():
			_complete_text()
		else:
			text_label.text = current_text.substr(0, display_index)

func _update_auto_advance(delta: float) -> void:
	auto_advance_timer += delta

	if auto_advance_timer >= auto_advance_delay:
		_finish_dialogue()

func _complete_text() -> void:
	is_complete = true
	text_label.text = current_text
	auto_advance_timer = 0.0

func _finish_dialogue() -> void:
	is_displaying = false
	is_complete = false
	_fade_out()

# === PUBLIC METHODS ===
func show_dialogue(character: String, text: String) -> void:
	current_text = text
	display_index = 0
	text_timer = 0.0
	auto_advance_timer = 0.0
	is_displaying = true
	is_complete = false

	# Set character name and color
	character_label.text = character
	var char_color = character_colors[character] if character in character_colors else Color.WHITE
	character_label.add_theme_color_override("font_color", char_color)

	# Clear text
	text_label.text = ""

	# Show panel
	_fade_in()

func skip_to_end() -> void:
	if is_displaying and not is_complete:
		_complete_text()
	elif is_complete:
		_finish_dialogue()

# === ANIMATION ===
func _fade_in() -> void:
	show()
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)

func _fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(_on_fade_out_complete)

func _on_fade_out_complete() -> void:
	hide()
	dialogue_finished.emit()
