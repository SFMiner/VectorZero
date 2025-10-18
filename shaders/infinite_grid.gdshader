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
