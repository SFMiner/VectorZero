extends Node2D

## Test Scene Setup Script
## This script sets up the movement test scene on first run

func _ready() -> void:
	print("Movement Test Scene Ready!")
	print("Controls:")
	print("  WASD - Move")
	print("  Space - Dash")
	print("  ESC - Quit")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
