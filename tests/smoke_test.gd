extends Node

const LevelScene := preload("res://scenes/level.tscn")
const MainScene := preload("res://scenes/main.tscn")
var failures: Array[String] = []

func _ready() -> void:
	await run_tests()
	if failures.is_empty():
		print("SELF_TEST PASS: all gameplay systems exercised")
		get_tree().quit(0)
	else:
		for failure in failures: push_error("SELF_TEST: " + failure)
		get_tree().quit(1)

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func run_tests() -> void:
	for action in ["move_left", "move_right", "jump", "attack", "dodge", "heal", "pause", "debug_toggle"]:
		check(InputMap.has_action(action), "missing input action: " + action)
	check(ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/main.tscn", "main scene is not configured")
	GameState.new_game()
	var original_master: float = float(GameState.settings.master)
	GameState.update_setting("master", 0.65)
	GameState.load_game()
	check(is_equal_approx(float(GameState.settings.master), 0.65), "settings did not persist")
	GameState.update_setting("master", original_master)
	var main: Node = MainScene.instantiate()
	add_child(main)
	await get_tree().process_frame
	var new_game_button: Button
	for candidate in main.find_children("*", "Button", true, false):
		if candidate.text == "新しい巡礼": new_game_button = candidate
	check(is_instance_valid(new_game_button), "new game button missing")
	if is_instance_valid(new_game_button): new_game_button.pressed.emit()
	await get_tree().process_frame
	check(is_instance_valid(main.current_level), "title-to-game transition failed")
	main.queue_free()
	await get_tree().process_frame
	var level: AshenLevel = LevelScene.instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame
	check(is_instance_valid(level.player), "player did not spawn")
	check(level.get_tree().get_nodes_in_group("enemies").size() >= 10, "enemy encounters missing")
	check(level.get_tree().get_nodes_in_group("hazards").size() >= 10, "hazards missing")
	var start_x := level.player.global_position.x
	Input.action_press("move_right")
	for i in 18: await get_tree().physics_frame
	Input.action_release("move_right")
	check(level.player.global_position.x > start_x + 10.0, "player movement failed")
	Input.action_press("jump")
	await get_tree().physics_frame
	Input.action_release("jump")
	await get_tree().physics_frame
	check(level.player.velocity.y < 0.0, "jump failed")
	level.player.start_attack()
	check(level.player.combo_step == 1 and level.player.attack_left > 0.0, "attack startup failed")
	var stamina_before := level.player.stamina
	level.player.start_dodge()
	check(level.player.stamina < stamina_before and level.player.invulnerable_left > 0.0, "dodge or i-frames failed")
	var enemy: Enemy = level.get_tree().get_first_node_in_group("enemies")
	check(is_instance_valid(enemy), "enemy instance unavailable")
	if is_instance_valid(enemy):
		enemy.take_damage(999, Vector2.ZERO)
		check(enemy.state == Enemy.State.DEAD, "enemy cannot be defeated")
	level._on_checkpoint_activated(1, Vector2(1900, 600))
	check(GameState.checkpoint_id == 1 and level.player.flasks == 3, "checkpoint failed")
	var deaths_before := GameState.deaths
	level.player.invulnerable_left = 0.0
	level.player.take_damage(999, Vector2.ZERO)
	await get_tree().create_timer(0.82).timeout
	check(GameState.deaths == deaths_before + 1, "death count failed")
	check(is_instance_valid(level.player) and not level.player.is_dead, "fast respawn failed")
	level.toggle_pause()
	check(get_tree().paused, "pause failed")
	level.toggle_pause()
	check(not get_tree().paused, "resume failed")
	level.begin_boss()
	check(level.boss_active and level.hud.boss_panel.visible, "boss intro or HP bar failed")
	level.boss.state = BellWardenBoss.State.IDLE
	level.boss.hp = 230
	level.boss.take_damage(25, Vector2.ZERO)
	check(level.boss.phase == 2, "boss phase transition failed")
	level.boss.state = BellWardenBoss.State.IDLE
	var clear_state := {"done": false}
	level.game_completed.connect(func() -> void: clear_state.done = true)
	level.boss.take_damage(999, Vector2.ZERO)
	check(level.boss.state == BellWardenBoss.State.DEAD, "boss defeat failed")
	await get_tree().create_timer(3.3).timeout
	check(bool(clear_state.done), "game-clear transition signal failed")
	level.queue_free()
	await get_tree().process_frame
