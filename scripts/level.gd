class_name AshenLevel
extends Node2D

signal return_to_title
signal game_completed

const PlayerScene := preload("res://scenes/player.tscn")
const BossScene := preload("res://scenes/boss.tscn")

var player: Player
var camera: Camera2D
var hud: GameHUD
var backdrop: ParallaxBackdrop
var boss: BellWardenBoss
var boss_active: bool = false
var gate: StaticBody2D
var respawning: bool = false
var shake_strength: float = 0.0
var tutorial_stage: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	backdrop = $Environment/BackgroundLayer/Backdrop
	hud = $HUD
	hud.resume_requested.connect(toggle_pause)
	hud.retry_requested.connect(_on_retry_requested)
	hud.title_requested.connect(_on_title_requested)
	player = $Actors/Player
	player.global_position = corrected_spawn(GameState.checkpoint_position)
	configure_player(player)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_target(player)
	for hazard in get_tree().get_nodes_in_group("hazards"):
		hazard.set_target(player)
	for checkpoint in $Checkpoints.get_children():
		checkpoint.activated.connect(_on_checkpoint_activated)
	boss = $Actors/Boss
	configure_boss(boss)
	Audio.start_bgm()
	hud.show_message("灰哭きの参道", 2.1)

func create_wall(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 16
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	shape_node.shape = shape
	shape_node.position = rect.position + rect.size * 0.5
	body.add_child(shape_node)
	add_child(body)
	return body

func spawn_player(pos: Vector2) -> void:
	player = PlayerScene.instantiate()
	player.global_position = corrected_spawn(pos)
	$Actors.add_child(player)
	configure_player(player)

func configure_player(active_player: Player) -> void:
	player = active_player
	player.stats_changed.connect(hud.update_player)
	player.died.connect(_on_player_died)
	player.attack_landed.connect(_on_attack_landed)
	player.landed.connect(_on_landed)
	player.refill()
	camera = Camera2D.new()
	camera.position = Vector2(150, -95)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	camera.limit_left = 0
	camera.limit_right = 4970
	camera.limit_top = 0
	camera.limit_bottom = 720
	player.add_child(camera)
	camera.make_current()
	backdrop.camera = camera
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_target(player)
	for hazard in get_tree().get_nodes_in_group("hazards"):
		hazard.set_target(player)
	if is_instance_valid(boss): boss.set_target(player)

func corrected_spawn(pos: Vector2) -> Vector2:
	if GameState.checkpoint_id == 0: return Vector2(115, 600)
	return Vector2(pos.x, 600)

func spawn_boss() -> void:
	boss = BossScene.instantiate()
	boss.global_position = Vector2(4625, 600)
	$Actors.add_child(boss)
	configure_boss(boss)

func configure_boss(active_boss: BellWardenBoss) -> void:
	boss = active_boss
	boss.set_target(player)
	boss.health_changed.connect(hud.show_boss)
	boss.phase_changed.connect(_on_boss_phase)
	boss.defeated.connect(_on_boss_defeated)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player): return
	if shake_strength > 0.05 and is_instance_valid(camera):
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		shake_strength *= 0.84
	elif is_instance_valid(camera): camera.offset = camera.offset.lerp(Vector2.ZERO, 0.28)
	update_tutorials()
	if not boss_active and player.global_position.x > 4140:
		begin_boss()
	if Input.is_action_just_pressed("debug_toggle"):
		hud.toggle_debug()
	if hud.debug_label.visible:
		var boss_info := "なし"
		if is_instance_valid(boss): boss_info = "%s / %s / HP %d" % [boss.state_name(), boss.attack_name(), boss.hp]
		hud.update_debug("Player (%.0f, %.0f)\nHP %d  ST %.0f\nGround %s  iFrame %.2f\nBoss %s" % [player.global_position.x, player.global_position.y, player.hp, player.stamina, player.is_on_floor(), player.invulnerable_left, boss_info])

func update_tutorials() -> void:
	var x := player.global_position.x
	if tutorial_stage == 0 and x > 210:
		tutorial_stage = 1; hud.show_message("A / D で移動　Space でジャンプ", 2.5)
	elif tutorial_stage == 1 and x > 760:
		tutorial_stage = 2; hud.show_message("J で斬る　連打で三連撃", 2.3)
	elif tutorial_stage == 2 and x > 1180:
		tutorial_stage = 3; hud.show_message("深紅の予兆を見たら K / Shift で回避", 2.8)
	elif tutorial_stage == 3 and x > 1800:
		tutorial_stage = 4; hud.show_message("霊火に触れると回復薬を補充し、記録する", 2.8)
	elif tutorial_stage == 4 and x > 2400:
		tutorial_stage = 5; hud.area_label.text = "嘆き鐘の回廊"

func begin_boss() -> void:
	boss_active = true
	gate = create_wall(Rect2(4065, 330, 30, 270))
	var gate_visual := Polygon2D.new()
	gate_visual.polygon = PackedVector2Array([Vector2(4065, 600), Vector2(4065, 330), Vector2(4095, 330), Vector2(4095, 600)])
	gate_visual.color = Color("5c263b")
	gate_visual.z_index = 2
	$Stage.add_child(gate_visual)
	hud.area_label.text = "終鐘の礼拝堂"
	hud.show_message("鐘守ヴァルグリム", 2.2)
	boss.begin_intro()
	shake(14.0)

func _on_checkpoint_activated(id: int, pos: Vector2) -> void:
	GameState.set_checkpoint(id, pos)
	player.refill()
	hud.show_message("霊火が記憶を結んだ", 1.8)
	spawn_fx(pos + Vector2(0, -40), Color("68ffe5"), 90, 0.65, 14)
	shake(5.0)

func _on_attack_landed(pos: Vector2) -> void:
	spawn_fx(pos, Color("d8fff8"), 36, 0.22, 7)
	shake(4.5)
	hit_stop()

func _on_landed(pos: Vector2) -> void:
	spawn_fx(pos + Vector2(0, -2), Color(0.48, 0.68, 0.74, 0.55), 22, 0.20, 5)

func spawn_fx(pos: Vector2, color: Color, radius: float, duration: float, rays: int) -> void:
	var fx := FXBurst.new().setup(color, radius, duration, rays)
	fx.global_position = pos
	fx.z_index = 10
	$RuntimeEffects.add_child(fx)

func shake(amount: float) -> void:
	shake_strength = maxf(shake_strength, amount)

func hit_stop() -> void:
	Engine.time_scale = 0.12
	await get_tree().create_timer(0.045, true, false, true).timeout
	Engine.time_scale = 1.0

func _on_player_died() -> void:
	if respawning: return
	respawning = true
	GameState.record_death()
	shake(16.0)
	hud.show_message("YOU DIED", 0.55)
	spawn_fx(player.global_position + Vector2(0, -25), Color("d12e58"), 100, 0.55, 16)
	await get_tree().create_timer(0.68).timeout
	respawn_player()

func respawn_player() -> void:
	if is_instance_valid(player): player.queue_free()
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
		projectile.queue_free()
	if boss_active:
		if is_instance_valid(boss): boss.queue_free()
		if is_instance_valid(gate): gate.queue_free()
		boss_active = false
		hud.hide_boss()
		spawn_boss()
	spawn_player(GameState.checkpoint_position)
	respawning = false
	hud.show_message("再起", 0.55)

func _on_boss_phase(_phase: int) -> void:
	hud.show_message("第二相 ― 弔鐘が哭く", 1.4)
	shake(18.0)
	spawn_fx(boss.global_position + Vector2(0, -45), Color("ff4168"), 145, 0.9, 18)

func _on_boss_defeated() -> void:
	hud.hide_boss()
	hud.show_message("終鐘は沈黙した", 1.8)
	shake(22.0)
	spawn_fx(boss.global_position + Vector2(0, -45), Color("8ffff0"), 210, 1.35, 24)
	await get_tree().create_timer(2.0).timeout
	game_completed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var next := not get_tree().paused
	get_tree().paused = next
	hud.set_paused(next)

func _on_retry_requested() -> void:
	get_tree().paused = false
	hud.set_paused(false)
	if is_instance_valid(player) and not player.is_dead: player.die()

func _on_title_requested() -> void:
	get_tree().paused = false
	return_to_title.emit()
