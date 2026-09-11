extends Node

const LevelScene := preload("res://scenes/level.tscn")

func _ready() -> void:
	GameState.checkpoint_id = 2
	GameState.checkpoint_position = Vector2(3950, 600)
	var level: AshenLevel = LevelScene.instantiate()
	add_child(level)
	level.player.global_position = Vector2(4360, 600)
	level.camera.reset_smoothing()
	level.begin_boss()
	level.boss.modulate.a = 1.0
	level.boss.scale = Vector2.ONE
	level.boss.state = BellWardenBoss.State.WINDUP
	level.boss.current_attack = BellWardenBoss.Attack.SLAM
	level.boss.state_time = 3.0
	level.boss.phase = 2
	level.boss.hp = 180
	level.hud.show_boss(level.boss.hp, level.boss.max_hp, 2)

