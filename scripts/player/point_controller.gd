extends PlayerController
class_name PointController

## Stage 1-2: Single point with omnidirectional movement and dash

# === DASH CONFIGURATION ===
@export_group("Dash")
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.5

# === STATE ===
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var can_dash: bool = true
var dash_cooldown_timer: float = 0.0

# === INITIALIZATION ===
func _ready() -> void:
	super._ready()
	current_form = "point"

# === INPUT ===
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and can_dash:
		_start_dash()

# === MOVEMENT ===
func _handle_movement(delta: float) -> void:
	if is_dashing:
		_handle_dash(delta)
	else:
		_handle_normal_movement(delta)
	
	# Update cooldown
	if not can_dash:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0:
			can_dash = true

func _handle_normal_movement(delta: float) -> void:
	# Get input direction
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_direction != Vector2.ZERO:
		# Accelerate toward input direction
		velocity = velocity.move_toward(input_direction * base_speed, acceleration * delta)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()

func _handle_dash(delta: float) -> void:
	dash_timer -= delta
	
	if dash_timer <= 0.0:
		_end_dash()
	else:
		# Continue dashing in locked direction
		velocity = dash_direction * dash_speed
		move_and_slide()

func _start_dash() -> void:
	# Get current movement direction or face direction
	var dash_dir = velocity.normalized()
	if dash_dir == Vector2.ZERO:
		# If not moving, dash in last input direction
		dash_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dash_dir == Vector2.ZERO:
			dash_dir = Vector2.RIGHT  # Default direction
	
	dash_direction = dash_dir
	is_dashing = true
	dash_timer = dash_duration
	can_dash = false
	dash_cooldown_timer = dash_cooldown
	
	# Visual/audio feedback
	_play_dash_effect()

func _end_dash() -> void:
	is_dashing = false
	# Maintain some momentum after dash
	velocity = dash_direction * base_speed * 0.5

func _play_dash_effect() -> void:
	# TODO: Add particle effect
	# TODO: Add sound effect
	# TODO: Add screen shake
	pass

# === VISUALS ===
func _process(_delta: float) -> void:
	_update_visuals()

func _update_visuals() -> void:
	if sprite:
		# Scale slightly during dash
		var target_scale = 0.4 if is_dashing else 0.2
		sprite.scale = sprite.scale.lerp(Vector2.ONE * target_scale, 0.1)
		
		# Glow more during dash
		var target_glow = 1.5 if is_dashing else 1.0
		# Apply to material (assuming glow shader)
		# sprite.material.set_shader_parameter("glow_strength", target_glow)
