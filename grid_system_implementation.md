# Vector Zero: Cartesian Grid Implementation Guide

**System:** Infinite Cartesian Grid  
**Engine:** Godot 4.5  
**Language:** GDScript  
**Purpose:** The mathematical "reality" of Vector Zero's world

---

## I. OVERVIEW

The grid is not just a background—it's the fundamental fabric of the game world. It represents the Cartesian plane itself, making coordinates visible and tangible.

### Design Requirements
- ✓ Infinite scrolling (follows camera/player)
- ✓ Two grid densities: Minor (1 unit) and Major (5 units)
- ✓ Pulses brighter at integer coordinates
- ✓ Glows when player crosses gridlines
- ✓ Performance optimized (shader-based, minimal redraws)
- ✓ Color: Dim cyan (#1a3a4a) with dynamic brightness
- ✓ Responds to player position and movement

---

## II. ARCHITECTURE

### A. File Structure
```
res://
├── scenes/
│   └── components/
│       ├── grid.tscn
│       └── grid_interaction.tscn
├── scripts/
│   └── grid/
│       ├── grid_renderer.gd
│       ├── grid_shader_controller.gd
│       └── grid_pulse_manager.gd
└── shaders/
    └── infinite_grid.gdshader
```

### B. System Components

**1. GridRenderer (Node2D)**
- Main grid scene node
- Manages shader material
- Handles camera following
- Updates shader parameters

**2. GridShaderController (Script)**
- Controls shader uniforms
- Manages visual effects
- Handles optimization

**3. GridPulseManager (Script)**
- Detects integer coordinate crossings
- Triggers pulse effects
- Manages pulse timing and decay

**4. infinite_grid.gdshader**
- Shader that renders the grid
- Handles major/minor gridlines
- Pulse effects
- Player proximity glow

---

## III. SHADER IMPLEMENTATION

### A. Infinite Grid Shader

Create `res://shaders/infinite_grid.gdshader`:

```gdshader
shader_type canvas_item;

// === UNIFORMS ===
uniform vec2 grid_offset = vec2(0.0, 0.0);  // Camera/player position
uniform float minor_spacing = 50.0;          // 1 unit = 50 pixels
uniform float major_spacing = 250.0;         // 5 units = 250 pixels
uniform vec4 grid_color : source_color = vec4(0.102, 0.227, 0.290, 0.3);  // #1a3a4a with alpha
uniform vec4 major_color : source_color = vec4(0.102, 0.227, 0.290, 0.5); // Brighter for major lines
uniform float line_width = 1.0;
uniform float major_line_width = 2.0;

// Pulse effect uniforms
uniform vec2 pulse_position = vec2(0.0, 0.0);  // Where the pulse is centered
uniform float pulse_strength = 0.0;             // 0.0 to 1.0
uniform float pulse_radius = 100.0;             // How far the pulse extends

// Player proximity glow
uniform vec2 player_position = vec2(0.0, 0.0);
uniform float player_glow_radius = 50.0;
uniform float player_glow_strength = 0.5;

// === FUNCTIONS ===

// Draw a single gridline
float gridLine(vec2 coord, float spacing, float width) {
	vec2 grid = abs(fract(coord / spacing - 0.5) - 0.5) / fwidth(coord / spacing);
	float line = min(grid.x, grid.y);
	return 1.0 - min(line / width, 1.0);
}

// Calculate pulse effect
float calculatePulse(vec2 world_pos) {
	float dist = distance(world_pos, pulse_position);
	float pulse = 1.0 - smoothstep(0.0, pulse_radius, dist);
	return pulse * pulse_strength;
}

// Calculate player proximity glow
float calculatePlayerGlow(vec2 world_pos) {
	float dist = distance(world_pos, player_position);
	float glow = 1.0 - smoothstep(0.0, player_glow_radius, dist);
	return glow * player_glow_strength;
}

// Check if we're at an integer coordinate (with tolerance)
float integerCoordinateGlow(vec2 world_pos, float spacing) {
	vec2 grid_coord = world_pos / spacing;
	vec2 nearest_int = round(grid_coord);
	vec2 dist_to_int = abs(grid_coord - nearest_int);
	
	// Glow if within 0.05 units of integer coordinate
	float glow_x = 1.0 - smoothstep(0.0, 0.05, dist_to_int.x);
	float glow_y = 1.0 - smoothstep(0.0, 0.05, dist_to_int.y);
	
	return max(glow_x, glow_y) * 0.3;  // 30% brightness boost
}

// === FRAGMENT SHADER ===
void fragment() {
	// Calculate world position
	vec2 world_pos = UV * 10000.0 - 5000.0 + grid_offset;  // Center on screen
	
	// Draw minor gridlines
	float minor_grid = gridLine(world_pos, minor_spacing, line_width);
	
	// Draw major gridlines (every 5 units)
	float major_grid = gridLine(world_pos, major_spacing, major_line_width);
	
	// Combine grids
	vec4 final_color = mix(grid_color, major_color, major_grid);
	float alpha = max(minor_grid, major_grid);
	
	// Add pulse effect
	float pulse = calculatePulse(world_pos);
	alpha += pulse;
	final_color.rgb += pulse * 0.5;  // Brighten during pulse
	
	// Add player proximity glow
	float player_glow = calculatePlayerGlow(world_pos);
	alpha += player_glow;
	final_color.rgb += player_glow * 0.3;
	
	// Add integer coordinate glow
	float int_glow = integerCoordinateGlow(world_pos, minor_spacing);
	alpha += int_glow;
	final_color.rgb += int_glow * 0.4;
	
	// Apply final alpha
	final_color.a = min(alpha, 1.0);
	
	COLOR = final_color;
}
```

---

## IV. GRID RENDERER SCRIPT

Create `res://scripts/grid/grid_renderer.gd`:

```gdscript
extends Node2D
class_name GridRenderer

# === CONFIGURATION ===
@export var pixels_per_unit: float = 50.0  # 1 game unit = 50 pixels
@export var grid_color: Color = Color(0.102, 0.227, 0.290, 0.3)  # #1a3a4a
@export var follow_camera: bool = true

# === REFERENCES ===
@onready var shader_material: ShaderMaterial = $GridRect.material

# Internal tracking
var camera: Camera2D = null
var player: Node2D = null

# === INITIALIZATION ===
func _ready() -> void:
	# Find camera and player
	_find_camera()
	_find_player()
	
	# Set up shader material
	_initialize_shader()
	
	# Set up the ColorRect to cover screen
	_setup_rect()

func _find_camera() -> void:
	# Look for Camera2D in scene
	camera = get_viewport().get_camera_2d()
	if not camera:
		push_warning("GridRenderer: No Camera2D found in scene")

func _find_player() -> void:
	# Look for player node (should have group "player")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_warning("GridRenderer: No player found in 'player' group")

func _initialize_shader() -> void:
	if not shader_material:
		push_error("GridRenderer: No shader material assigned")
		return
	
	# Set initial shader parameters
	shader_material.set_shader_parameter("minor_spacing", pixels_per_unit)
	shader_material.set_shader_parameter("major_spacing", pixels_per_unit * 5.0)
	shader_material.set_shader_parameter("grid_color", grid_color)
	shader_material.set_shader_parameter("line_width", 1.0)
	shader_material.set_shader_parameter("major_line_width", 2.0)

func _setup_rect() -> void:
	var rect = $GridRect as ColorRect
	if rect:
		# Make it cover the entire viewport
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.size = get_viewport_rect().size

# === PROCESS ===
func _process(_delta: float) -> void:
	_update_shader_parameters()

func _update_shader_parameters() -> void:
	if not shader_material:
		return
	
	# Update grid offset to follow camera
	if camera and follow_camera:
		var cam_pos = camera.get_screen_center_position()
		shader_material.set_shader_parameter("grid_offset", cam_pos)
	
	# Update player position for glow effect
	if player:
		shader_material.set_shader_parameter("player_position", player.global_position)

# === PUBLIC METHODS ===

## Trigger a pulse effect at a world position
func trigger_pulse(world_position: Vector2, strength: float = 1.0, radius: float = 100.0) -> void:
	if not shader_material:
		return
	
	shader_material.set_shader_parameter("pulse_position", world_position)
	shader_material.set_shader_parameter("pulse_strength", strength)
	shader_material.set_shader_parameter("pulse_radius", radius)
	
	# Fade out pulse over time
	var tween = create_tween()
	tween.tween_method(
		_set_pulse_strength,
		strength,
		0.0,
		0.5  # 0.5 second fade
	)

func _set_pulse_strength(value: float) -> void:
	if shader_material:
		shader_material.set_shader_parameter("pulse_strength", value)

## Adjust grid visibility
func set_grid_alpha(alpha: float) -> void:
	if shader_material:
		var color = shader_material.get_shader_parameter("grid_color") as Color
		color.a = alpha
		shader_material.set_shader_parameter("grid_color", color)

## Set pixels per unit (for zooming effects)
func set_pixels_per_unit(ppu: float) -> void:
	pixels_per_unit = ppu
	if shader_material:
		shader_material.set_shader_parameter("minor_spacing", ppu)
		shader_material.set_shader_parameter("major_spacing", ppu * 5.0)
```

---

## V. GRID PULSE MANAGER

Create `res://scripts/grid/grid_pulse_manager.gd`:

```gdscript
extends Node
class_name GridPulseManager

## Detects when player crosses integer coordinates and triggers grid pulses

# === CONFIGURATION ===
@export var player_path: NodePath
@export var grid_renderer_path: NodePath
@export var pulse_threshold: float = 0.05  # How close to integer before pulse
@export var pulse_strength: float = 0.8
@export var pulse_radius: float = 150.0
@export var pixels_per_unit: float = 50.0

# === REFERENCES ===
var player: Node2D
var grid_renderer: GridRenderer

# === STATE ===
var last_grid_x: int = 0
var last_grid_y: int = 0

# === INITIALIZATION ===
func _ready() -> void:
	# Get references
	if player_path:
		player = get_node(player_path)
	if grid_renderer_path:
		grid_renderer = get_node(grid_renderer_path)
	
	if not player:
		push_error("GridPulseManager: Player not found")
		return
	
	if not grid_renderer:
		push_error("GridPulseManager: GridRenderer not found")
		return
	
	# Initialize tracking
	var grid_pos = _world_to_grid(player.global_position)
	last_grid_x = int(round(grid_pos.x))
	last_grid_y = int(round(grid_pos.y))

# === PROCESS ===
func _process(_delta: float) -> void:
	if not player or not grid_renderer:
		return
	
	_check_grid_crossing()

# === GRID CROSSING DETECTION ===
func _check_grid_crossing() -> void:
	# Convert player position to grid coordinates
	var grid_pos = _world_to_grid(player.global_position)
	var current_grid_x = int(round(grid_pos.x))
	var current_grid_y = int(round(grid_pos.y))
	
	# Check if we crossed an integer X coordinate
	if current_grid_x != last_grid_x:
		var pulse_world_x = current_grid_x * pixels_per_unit
		var pulse_pos = Vector2(pulse_world_x, player.global_position.y)
		_trigger_crossing_pulse(pulse_pos)
		last_grid_x = current_grid_x
	
	# Check if we crossed an integer Y coordinate
	if current_grid_y != last_grid_y:
		var pulse_world_y = current_grid_y * pixels_per_unit
		var pulse_pos = Vector2(player.global_position.x, pulse_world_y)
		_trigger_crossing_pulse(pulse_pos)
		last_grid_y = current_grid_y

func _trigger_crossing_pulse(world_position: Vector2) -> void:
	grid_renderer.trigger_pulse(world_position, pulse_strength, pulse_radius)
	
	# Optional: Play audio effect
	_play_grid_cross_sound()

func _play_grid_cross_sound() -> void:
	# TODO: Implement audio feedback
	# AudioManager.play_sfx("grid_cross", 0.3)  # Low volume
	pass

# === HELPER FUNCTIONS ===
func _world_to_grid(world_pos: Vector2) -> Vector2:
	return world_pos / pixels_per_unit
```

---

## VI. SCENE SETUP

### A. Create Grid Scene

1. Create new scene: `res://scenes/components/grid.tscn`
2. Root node: `Node2D` (rename to "Grid")
3. Add child: `ColorRect` (rename to "GridRect")
4. Configure GridRect:
   - Anchors: Full Rect
   - Material: New ShaderMaterial
   - Shader: Load `infinite_grid.gdshader`
5. Attach script to Grid node: `grid_renderer.gd`

### B. Grid Scene Structure

```
Grid (Node2D) [grid_renderer.gd]
└── GridRect (ColorRect)
    └── Material: ShaderMaterial
        └── Shader: infinite_grid.gdshader
```

### C. Add Pulse Manager

In your main stage scene:

```
Stage (Node2D)
├── Grid (Instance of grid.tscn)
├── Player (CharacterBody2D) [in group "player"]
└── GridPulseManager (Node) [grid_pulse_manager.gd]
    └── Set player_path: "../Player"
    └── Set grid_renderer_path: "../Grid"
```

---

## VII. INTEGRATION WITH GAME

### A. Player Script Integration

In your player script, you can optionally trigger pulses on events:

```gdscript
extends CharacterBody2D

@onready var grid: GridRenderer = get_node("/root/Stage/Grid")

func _on_transformation() -> void:
	# Trigger big pulse on transformation
	if grid:
		grid.trigger_pulse(global_position, 1.5, 300.0)

func _on_dash() -> void:
	# Trigger small pulse on dash
	if grid:
		grid.trigger_pulse(global_position, 0.5, 100.0)
```

### B. Camera Setup

Ensure you have a Camera2D in your scene:

```gdscript
extends Camera2D

func _ready() -> void:
	# Make this the active camera
	make_current()
	
	# Enable smoothing for better grid visuals
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0
```

---

## VIII. OPTIMIZATION

### A. Performance Targets
- 60 FPS on recommended specs
- Grid rendering should take < 2ms per frame
- Minimal GPU overhead

### B. Optimization Techniques

**1. Shader Optimization**
```gdshader
// Use step functions instead of smoothstep where possible
// Cache calculations
// Minimize texture lookups
```

**2. Update Frequency**
```gdscript
# Only update shader parameters when they change
var _last_camera_pos: Vector2 = Vector2.ZERO
var _position_threshold: float = 1.0  # Only update if moved > 1 pixel

func _process(_delta: float) -> void:
	if camera:
		var cam_pos = camera.get_screen_center_position()
		if cam_pos.distance_to(_last_camera_pos) > _position_threshold:
			shader_material.set_shader_parameter("grid_offset", cam_pos)
			_last_camera_pos = cam_pos
```

**3. Conditional Rendering**
```gdscript
# Disable grid rendering when zoomed out very far
func _process(_delta: float) -> void:
	if camera:
		var zoom_level = camera.zoom.x
		visible = zoom_level > 0.1  # Hide grid at extreme zoom levels
```

---

## IX. VISUAL VARIATIONS

### A. Grid Intensity Based on Zoom

```gdscript
func _process(_delta: float) -> void:
	if camera:
		var zoom = camera.zoom.x
		var alpha = clamp(zoom, 0.2, 1.0)
		set_grid_alpha(alpha * 0.3)  # 0.3 = base alpha
```

### B. Dynamic Grid Spacing

```gdscript
# Adjust grid spacing based on zoom (for very zoomed out views)
func update_grid_for_zoom(zoom_level: float) -> void:
	if zoom_level < 0.5:
		# Use larger grid spacing when zoomed out
		set_pixels_per_unit(pixels_per_unit * 2.0)
	else:
		# Normal spacing
		set_pixels_per_unit(50.0)
```

### C. Grid Color Themes

```gdscript
# Different grid colors for different acts/areas
func set_grid_theme(theme_name: String) -> void:
	match theme_name:
		"default":
			grid_color = Color(0.102, 0.227, 0.290, 0.3)  # Cyan
		"danger":
			grid_color = Color(0.5, 0.1, 0.1, 0.3)  # Red tint
		"safe":
			grid_color = Color(0.1, 0.5, 0.1, 0.3)  # Green tint
		"calculus":
			grid_color = Color(0.2, 0.2, 0.5, 0.3)  # Blue tint
	
	shader_material.set_shader_parameter("grid_color", grid_color)
```

---

## X. DEBUGGING & TESTING

### A. Debug Overlay

```gdscript
# Add to GridRenderer for debugging
@export var debug_mode: bool = false

func _draw() -> void:
	if not debug_mode:
		return
	
	# Draw debug info
	if player:
		var grid_pos = player.global_position / pixels_per_unit
		var text = "Grid Pos: (%.2f, %.2f)" % [grid_pos.x, grid_pos.y]
		draw_string(ThemeDB.fallback_font, Vector2(10, 20), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
```

### B. Test Scenes

Create `res://test/grid_test.tscn`:
- Simple scene with grid, camera, and moving object
- Test grid at different zoom levels
- Test pulse effects
- Verify integer coordinate detection

---

## XI. COMMON ISSUES & SOLUTIONS

### Issue: Grid flickers during movement
**Solution:** Ensure camera smoothing is enabled and grid_offset updates are smooth.

```gdscript
# In camera script
position_smoothing_enabled = true
position_smoothing_speed = 5.0
```

### Issue: Performance drops with grid enabled
**Solution:** Reduce shader complexity or grid update frequency.

```gdscript
# Update grid less frequently
var _update_timer: float = 0.0
var _update_interval: float = 0.016  # ~60 FPS

func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= _update_interval:
		_update_shader_parameters()
		_update_timer = 0.0
```

### Issue: Grid doesn't align with integer coordinates
**Solution:** Ensure pixels_per_unit is consistent everywhere.

```gdscript
# Create a global constant
const PIXELS_PER_UNIT: float = 50.0

# Use it consistently in:
# - Grid shader
# - Player movement
# - Coordinate display
# - Physics calculations
```

---

## XII. FUTURE ENHANCEMENTS

### A. 3D Grid (Act IV)
When transitioning to 3D:
- Convert to MeshInstance3D with custom geometry shader
- Render XY, XZ, and YZ planes
- Maintain same visual style

### B. Non-Euclidean Grids (Stage 18)
For curved space:
- Modify shader to curve gridlines
- Implement hyperbolic/elliptic geometry
- Maintain readability while bending space

### C. Interactive Grid
Allow player to:
- Change grid density
- Toggle major/minor lines
- Customize colors
- Enable/disable features

---

## XIII. CHECKLIST

**Setup**
- [x] Create grid shader (`infinite_grid.gdshader`)
- [x] Create GridRenderer script
- [x] Create GridPulseManager script
- [x] Set up grid scene (`grid.tscn`)
- [ ] Add grid to stage scenes

**Configuration**
- [ ] Set pixels_per_unit to 50.0
- [ ] Configure grid colors (cyan #1a3a4a)
- [ ] Link player to pulse manager
- [ ] Link camera to grid renderer
- [ ] Test grid rendering

**Testing**
- [ ] Verify grid follows camera
- [ ] Test pulse on integer crossing
- [ ] Check player glow effect
- [ ] Verify performance (< 2ms)
- [ ] Test at different zoom levels

**Polish**
- [ ] Add audio for grid crossing
- [ ] Fine-tune pulse timing
- [ ] Optimize shader if needed
- [ ] Add accessibility options (disable grid)

---

## XIV. CONCLUSION

The Cartesian grid is the foundation of Vector Zero's visual identity. It makes mathematics tangible—coordinates aren't just numbers, they're your location in a real, visible space. The grid pulses and glows, responding to your presence and movement, making the abstract concrete.

**Key Principles:**
- The grid is always visible (it's the fabric of reality)
- It responds to player actions (it's alive)
- It teaches passively (coordinates are always shown)
- It performs well (shader-based, optimized)

With this system in place, players will *feel* the Cartesian plane rather than just understand it intellectually. That's the magic of embedded learning.

**Next Step:** Implement player movement that works harmoniously with this grid system.
