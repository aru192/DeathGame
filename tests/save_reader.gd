extends Node
func _ready() -> void:
	var ok := GameState.deaths == 7 and GameState.checkpoint_id == 2 and is_equal_approx(float(GameState.settings.sfx), 0.42)
	if ok:
		print("PERSISTENCE READ PASS")
		get_tree().quit(0)
	else:
		push_error("PERSISTENCE READ FAILED")
		get_tree().quit(1)
