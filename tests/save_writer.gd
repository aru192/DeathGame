extends Node
func _ready() -> void:
	GameState.deaths = 7
	GameState.checkpoint_id = 2
	GameState.checkpoint_position = Vector2(3950, 600)
	GameState.settings.sfx = 0.42
	GameState.save_game()
	print("PERSISTENCE WRITE PASS")
	get_tree().quit(0)
