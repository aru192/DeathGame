extends Node

const LevelScene := preload("res://scenes/level.tscn")

func _ready() -> void:
	GameState.new_game()
	var level: AshenLevel = LevelScene.instantiate()
	add_child(level)
	level.player.global_position = Vector2(1080, 410)
	level.camera.reset_smoothing()
	level.hud.show_message("敵の深紅の予兆を見切れ", 2.0)
	var enemies := get_tree().get_nodes_in_group("enemies")
	if not enemies.is_empty():
		var enemy: Enemy = enemies[0]
		enemy.global_position = Vector2(1180, 600)
		enemy.change_state(Enemy.State.WINDUP, 2.0)

