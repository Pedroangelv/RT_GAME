extends Node2D



func _ready():
	pass

func _on_wiggles_tree_exited() -> void:
	var exit_wall = $TileMapLayer/wall/ExitWall
	exit_wall.move_local_x(500.0, false)
