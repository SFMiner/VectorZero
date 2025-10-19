# Gemini Reference

## Coding Conventions
- Always update CLAUDE.md with the exact changes you make to this file.
- Indent with tabs, not spaces.
- Maintain a README.md file of features, in checklist format, with implemented features checked off.
- Maintain a GEMINI.md file for the agent's purposes in coding, listing anything he AI will need to readily reference about the project, including any recurring syntactical errors (such as proper tertiatry operators), 
- Godot ternary operators use syntax: "value1 if condition else value2"
	- incorrect: "condition ? value1 : value2"	
- Do not use external ids in scene files: just use the paths to the included files. 
- Never use comments in a *.tscn file.




# Quick Fix Checklist for Grid Issues

## Files to Replace

Gridlines made by infinite_grid.gdshader were malformed, stretched to match display. 

1. ✅ `res://scripts/grid/grid_renderer.gd`
   - pixels_per_unit: 500.0
   - line_width: 0.7 (reduced)
   - major_line_width: 1.4 (reduced)
   - make offset match player movement: Vector2(8.67, 9.08)
		func _update_shader_parameters() -> void:
			# ...
			if camera and follow_camera:
				var offset = camera.get_screen_center_position() * Vector2(8.67, 9.08)
				shader_material.set_shader_parameter("grid_offset", offset)

2. ✅ `res://scripts/stages/maze_generator.gd`
   - pixels_per_unit: 50.0 (othewise maze is wrong size and wrong position)

3. ✅ `res://scripts/grid/grid_pulse_manager.gd`
   - pixels_per_unit: 500.0

4. ✅ `res://scripts/ui/coordinate_display.gd`
   - pixels_per_unit: 500.0


Replace these files in your project with the updated versions from /outputs:


## Scene Changes (Do Manually in Godot)

### Fix Camera Parenting (Fixes Parallax):

5. ✅ Scaled Grid.ColorRect vertically by 1.7, correcting for distortion.
   - will have to automatie this to match player's actual display


1. Open `res://scenes/stages/stage_01_the_point.tscn`
2. In the Scene tree, locate `Camera2D` node
3. **Drag** `Camera2D` onto `Player` node to reparent it
4. Select `Camera2D` and set its **Position** to `(0, 0)` in the Inspector
5. **Save** the scene (Ctrl+S)

This makes the camera follow the player perfectly, eliminating the parallax effect.

## Expected Results

After applying these fixes:

✅ Grid lines appear uniform width (horizontal = vertical)
✅ Grid and maze walls move together (no parallax)
✅ Coordinates display correctly
✅ Grid pulses happen at the right positions

## Testing

1. Run the scene
2. Move around - grid should stay aligned with maze
3. Check that grid lines are consistent width
4. Verify coordinates match grid positions
