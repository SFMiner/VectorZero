extends Node
class_name TransformationManager

## Manages player transformations between different forms

# === SIGNALS ===
signal transformation_started(from_form: String, to_form: String)
signal transformation_completed(new_form: String)

# === CONFIGURATION ===
@export var transformation_duration: float = 1.0
@export var particle_effect: PackedScene

# === REFERENCES ===
var current_player: PlayerController
var stage_root: Node

# === STATE ===
var is_transforming: bool = false

# === FORM SCENES ===
const FORMS = {
	"point": preload("res://scenes/player/player_point.tscn"),
	"line": preload("res://scenes/player/player_line.tscn"),
	"angle": preload("res://scenes/player/player_angle.tscn"),
	"triangle": preload("res://scenes/player/player_triangle.tscn")
}

# === INITIALIZATION ===
func _ready() -> void:
	stage_root = get_tree().current_scene

# === TRANSFORMATION ===
func transform_to(new_form: String, current_position: Vector2 = Vector2.ZERO) -> void:
	if is_transforming:
		push_warning("Already transforming, ignoring request")
		return
	
	if not FORMS.has(new_form):
		push_error("Unknown form: " + new_form)
		return
	
	var old_form = current_player.current_form if current_player else "none"
	
	is_transforming = true
	transformation_started.emit(old_form, new_form)
	
	# Play transformation effect
	_play_transformation_effect(current_position)
	
	# Wait for effect
	await get_tree().create_timer(transformation_duration).timeout
	
	# Swap player scenes
	_swap_player_scene(new_form, current_position)
	
	is_transforming = false
	transformation_completed.emit(new_form)

func _swap_player_scene(new_form: String, position: Vector2) -> void:
	# Store old player data
	var old_velocity = current_player.velocity if current_player else Vector2.ZERO
	
	# Remove old player
	if current_player:
		current_player.queue_free()
	
	# Create new player
	var new_player_scene = FORMS[new_form]
	var new_player = new_player_scene.instantiate() as PlayerController
	
	# Set position and velocity
	new_player.global_position = position
	new_player.velocity = old_velocity * 0.5  # Reduce momentum on transform
	
	# Add to scene
	stage_root.add_child(new_player)
	current_player = new_player
	
	# Connect signals
	new_player.transformation_requested.connect(_on_transformation_requested)

func _on_transformation_requested(new_form: String) -> void:
	if current_player:
		transform_to(new_form, current_player.global_position)

func _play_transformation_effect(position: Vector2) -> void:
	if not particle_effect:
		return
	
	var effect = particle_effect.instantiate()
	effect.global_position = position
	stage_root.add_child(effect)
	
	# Auto-remove after duration
	await get_tree().create_timer(transformation_duration + 1.0).timeout
	effect.queue_free()

# === HELPER FUNCTIONS ===
func get_current_form() -> String:
	return current_player.current_form if current_player else "none"

func get_current_player() -> PlayerController:
	return current_player
