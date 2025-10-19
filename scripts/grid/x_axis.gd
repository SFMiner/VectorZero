extends Line2D

var player : CharacterBody2D

func _ready():
	call_deferred("get_player")
	
func _process(delta: float) -> void:
	global_position.x = player.global_position.x

func get_player() -> void:
	player = get_tree().get_nodes_in_group("player")[0]
