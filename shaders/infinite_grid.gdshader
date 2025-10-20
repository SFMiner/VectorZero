shader_type canvas_item;

// === UNIFORMS ===
uniform vec2 grid_offset = vec2(0.0, 0.0);
uniform float minor_spacing = 50.0;
uniform float major_spacing = 250.0;
//uniform vec4 grid_color : source_color = vec4(0.102, 0.227, 0.290, 0.3);
//uniform vec4 major_color = vec4(0.102, 0.227, 0.290, 0.5);
uniform vec4 grid_color = vec4(1.0, 0.0, 1.0, 0.3);
uniform vec4 major_color = vec4(0.0, 1.0, 0.0, 0.5);
uniform float line_width = 1.0;
uniform float major_line_width = 2.0;

// Pulse effect uniforms
uniform vec2 pulse_position = vec2(0.0, 0.0);
uniform float pulse_strength = 0.0;
uniform float pulse_radius = 100.0;

// Player proximity glow
uniform vec2 player_position = vec2(0.0, 0.0);
uniform float player_glow_radius = 50.0;
uniform float player_glow_strength = 0.5;

// === FUNCTIONS ===

float gridLine(vec2 coord, float spacing, float width) {
	vec2 grid = abs(fract(coord / spacing - 0.5) - 0.5);
	vec2 derivative = fwidth(coord / spacing);
	grid = grid / derivative;
	float line = min(grid.x, grid.y);
	return 1.0 - min(line / width, 1.0);
}

float calculatePulse(vec2 world_pos) {
	float dist = distance(world_pos, pulse_position);
	float pulse = 1.0 - smoothstep(0.0, pulse_radius, dist);
	return pulse * pulse_strength;
}

float calculatePlayerGlow(vec2 world_pos) {
	float dist = distance(world_pos, player_position);
	float glow = 1.0 - smoothstep(0.0, player_glow_radius, dist);
	return glow * player_glow_strength;
}

float integerCoordinateGlow(vec2 world_pos, float spacing) {
	vec2 grid_coord = world_pos / spacing;
	vec2 nearest_int = round(grid_coord);
	vec2 dist_to_int = abs(grid_coord - nearest_int);
	float glow_x = 1.0 - smoothstep(0.0, 0.05, dist_to_int.x);
	float glow_y = 1.0 - smoothstep(0.0, 0.05, dist_to_int.y);
	return max(glow_x, glow_y) * 0.3;
}

// === FRAGMENT SHADER ===
void fragment() {
	// Get actual viewport size dynamically
	vec2 viewport_size = 1.0 / SCREEN_PIXEL_SIZE;

	// Convert UV (0 to 1) to screen pixel coordinates
	vec2 screen_pixel = UV * viewport_size;

	// Calculate world position:
	// Start with screen pixel, subtract half viewport to center, then add camera offset
	vec2 world_pos = (screen_pixel - viewport_size * 0.5) + grid_offset;

	// Draw minor gridlines (remove the * 100.0 multiplier!)
	float minor_grid = gridLine(world_pos, minor_spacing, line_width);

	// Draw major gridlines (remove the * 100.0 multiplier!)
	float major_grid = gridLine(world_pos, major_spacing, major_line_width);

	// Combine grids
	vec4 final_color = mix(grid_color, major_color, major_grid);
	float alpha = max(minor_grid, major_grid);

	// Add pulse effect
	float pulse = calculatePulse(world_pos);
	alpha += pulse;
	final_color.rgb += pulse * 0.5;

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