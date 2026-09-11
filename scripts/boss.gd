@tool
class_name BellWardenBoss
extends CharacterBody2D

signal health_changed(current: int, maximum: int, phase: int)
signal phase_changed(phase: int)
signal defeated

enum State { DORMANT, INTRO, IDLE, WINDUP, ATTACK, RECOVER, HURT, DEAD }
enum Attack { CLEAVE, SHOCKWAVE, SLAM, BELL_RAIN, RAVEN_DASH }

@export var max_hp: int = 420
var hp: int
var phase: int = 1
var state: State = State.DORMANT
var state_time: float = 0.0
var target: Player
var facing: float = -1.0
var current_attack: Attack = Attack.CLEAVE
var attack_index: int = 0
var hurtbox: Area2D
var attack_area: Area2D
var attack_shape: CollisionShape2D
var already_hit: bool = false
var gravity: float = 1550.0
var arena_left: float = 4110.0
var arena_right: float = 4770.0
var intro_started: bool = false
var dash_count: int = 0

const ProjectileScene := preload("res://scenes/projectile.tscn")

func _ready() -> void:
	hp = max_hp
	if Engine.is_editor_hint():
		state = State.IDLE
		queue_redraw()
		return
	setup_collision()
	queue_redraw()

func setup_collision() -> void:
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 24
	capsule.height = 76
	shape.shape = capsule
	shape.position = Vector2(0, -38)
	add_child(shape)
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	var hs := CollisionShape2D.new()
	hs.shape = capsule.duplicate()
	hs.position = Vector2(0, -38)
	hurtbox.add_child(hs)
	add_child(hurtbox)
	attack_area = Area2D.new()
	attack_area.collision_layer = 0
	attack_area.collision_mask = 2
	attack_area.monitoring = false
	attack_area.area_entered.connect(_on_attack_area_entered)
	attack_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(125, 76)
	attack_shape.shape = rect
	attack_area.add_child(attack_shape)
	add_child(attack_area)

func set_target(player: Player) -> void:
	target = player

func begin_intro() -> void:
	if intro_started: return
	intro_started = true
	state = State.INTRO
	state_time = 2.2
	modulate.a = 0.0
	scale = Vector2(1.45, 1.45)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.7)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_BACK)
	health_changed.emit(hp, max_hp, phase)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if state == State.DORMANT or state == State.DEAD: return
	state_time -= delta
	if not is_on_floor(): velocity.y += gravity * delta
	if is_instance_valid(target) and not target.is_dead:
		var dx := target.global_position.x - global_position.x
		if absf(dx) > 5.0: facing = signf(dx)
	match state:
		State.INTRO:
			velocity.x = 0.0
			if state_time <= 0.0: change_state(State.IDLE, 0.55)
		State.IDLE:
			velocity.x = move_toward(velocity.x, facing * (75.0 if phase == 1 else 105.0), 520.0 * delta)
			if state_time <= 0.0: choose_attack()
		State.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
			if state_time <= 0.0: execute_attack()
		State.ATTACK:
			update_attack(delta)
			if state_time <= 0.0:
				attack_area.set_deferred("monitoring", false)
				change_state(State.RECOVER, 0.58 if phase == 1 else 0.40)
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
			if state_time <= 0.0: change_state(State.IDLE, 0.38)
		State.HURT:
			if state_time <= 0.0: change_state(State.IDLE, 0.25)
	global_position.x = clampf(global_position.x, arena_left, arena_right)
	attack_area.position = Vector2(facing * 70, -39)
	move_and_slide()
	queue_redraw()

func choose_attack() -> void:
	attack_index += 1
	var sequence_phase1: Array[Attack] = [Attack.CLEAVE, Attack.SHOCKWAVE, Attack.CLEAVE, Attack.SLAM]
	var sequence_phase2: Array[Attack] = [Attack.RAVEN_DASH, Attack.BELL_RAIN, Attack.CLEAVE, Attack.SHOCKWAVE, Attack.SLAM]
	current_attack = (sequence_phase1 if phase == 1 else sequence_phase2)[attack_index % (4 if phase == 1 else 5)]
	var windup := 0.62
	match current_attack:
		Attack.SHOCKWAVE: windup = 0.82
		Attack.SLAM: windup = 0.95
		Attack.BELL_RAIN: windup = 1.05
		Attack.RAVEN_DASH: windup = 0.72
	change_state(State.WINDUP, windup)
	Audio.play("warning", 0.70 if phase == 1 else 0.92)

func execute_attack() -> void:
	already_hit = false
	match current_attack:
		Attack.CLEAVE:
			attack_shape.shape.size = Vector2(145, 84)
			attack_area.set_deferred("monitoring", true)
			change_state(State.ATTACK, 0.30)
		Attack.SHOCKWAVE:
			spawn_wave(facing, 390.0 if phase == 1 else 475.0)
			change_state(State.ATTACK, 0.32)
		Attack.SLAM:
			attack_shape.shape.size = Vector2(185, 55)
			attack_area.position = Vector2(0, -18)
			attack_area.set_deferred("monitoring", true)
			spawn_wave(-1.0, 300.0)
			spawn_wave(1.0, 300.0)
			change_state(State.ATTACK, 0.34)
		Attack.BELL_RAIN:
			spawn_bell_rain()
			change_state(State.ATTACK, 1.15)
		Attack.RAVEN_DASH:
			dash_count = 0
			attack_shape.shape.size = Vector2(95, 72)
			attack_area.set_deferred("monitoring", true)
			change_state(State.ATTACK, 0.56)
	Audio.play("slash", 0.52)

func update_attack(_delta: float) -> void:
	if current_attack == Attack.RAVEN_DASH:
		velocity.x = facing * 690.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1300.0 * _delta)

func spawn_wave(dir_x: float, wave_speed: float) -> void:
	var p: EnemyProjectile = ProjectileScene.instantiate()
	p.global_position = global_position + Vector2(dir_x * 38, -10)
	p.direction = Vector2(dir_x, 0)
	p.speed = wave_speed
	p.damage = 24 if phase == 1 else 28
	p.radius = 11
	p.tint = Color("f05a72")
	p.lifetime = 2.2
	get_parent().add_child(p)

func spawn_bell_rain() -> void:
	if not is_instance_valid(target): return
	for i in 6:
		var p: EnemyProjectile = ProjectileScene.instantiate()
		p.global_position = Vector2(clampf(target.global_position.x - 220 + i * 88, arena_left + 20, arena_right - 20), 250 - (i % 2) * 55)
		p.direction = Vector2(0.08 * (i - 3), 1).normalized()
		p.speed = 310.0
		p.damage = 22
		p.radius = 9
		p.tint = Color("e15389")
		p.lifetime = 2.0
		get_parent().add_child(p)

func _on_attack_area_entered(area: Area2D) -> void:
	if already_hit and current_attack != Attack.RAVEN_DASH: return
	var player := area.get_parent()
	if player.has_method("take_damage"):
		already_hit = true
		player.take_damage(30 if current_attack != Attack.RAVEN_DASH else 26, Vector2(facing * 430, -210))

func take_damage(amount: int, knockback: Vector2) -> void:
	if state in [State.DORMANT, State.INTRO, State.DEAD]: return
	hp -= amount
	velocity = knockback * 0.24
	Audio.play("hit", 0.7)
	flash()
	if hp <= 0:
		die()
	elif phase == 1 and hp <= max_hp / 2:
		phase = 2
		phase_changed.emit(phase)
		change_state(State.WINDUP, 1.15)
		current_attack = Attack.BELL_RAIN
	else:
		change_state(State.HURT, 0.16)
	health_changed.emit(maxi(hp, 0), max_hp, phase)

func die() -> void:
	state = State.DEAD
	attack_area.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	velocity = Vector2.ZERO
	health_changed.emit(0, max_hp, phase)
	Audio.play("death", 0.55)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color("ffdde4"), 0.25)
	tween.tween_property(self, "scale", Vector2(1.7, 1.7), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.65)
	tween.tween_callback(defeated.emit)

func change_state(next: State, duration: float) -> void:
	state = next
	state_time = duration
	queue_redraw()

func flash() -> void:
	modulate = Color("ff7d91")
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.18)

func state_name() -> String:
	return State.keys()[state]

func attack_name() -> String:
	return Attack.keys()[current_attack]

func _draw() -> void:
	if state == State.DORMANT: return
	var pulse := 0.5 + sin(Time.get_ticks_msec() * 0.018) * 0.3
	if state == State.WINDUP:
		var radius := 48.0
		if current_attack == Attack.BELL_RAIN: radius = 72.0
		draw_circle(Vector2(0, -40), radius, Color(0.94, 0.14, 0.26, 0.12 + pulse * 0.18))
		draw_arc(Vector2(0, -40), radius, 0, TAU, 30, Color("ff526d"), 3)
	var armor := Color("5a2538") if phase == 1 else Color("75213c")
	draw_colored_polygon(PackedVector2Array([Vector2(-34, 0), Vector2(-24, -65), Vector2(24, -65), Vector2(35, 0)]), armor)
	draw_circle(Vector2(0, -76), 19, Color("b9aaa5"))
	draw_colored_polygon(PackedVector2Array([Vector2(-22, -87), Vector2(-9, -112), Vector2(0, -88), Vector2(11, -114), Vector2(22, -86)]), Color("22283b"))
	draw_circle(Vector2(facing * 8, -78), 3.5, Color("ff365d"))
	draw_line(Vector2(facing * 15, -54), Vector2(facing * 54, -23), Color("c7ccd5"), 8)
	draw_circle(Vector2(facing * 58, -20), 12, Color("31394b"))
	if state == State.ATTACK:
		draw_arc(Vector2(facing * 18, -39), 62, -1.4 if facing > 0 else PI + 0.1, 1.25 if facing > 0 else PI * 2 - 1.25, 18, Color("ff8092"), 8)
