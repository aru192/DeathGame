@tool
class_name Player
extends CharacterBody2D

signal died
signal stats_changed(hp: int, max_hp: int, stamina: float, max_stamina: float, flasks: int)
signal attack_landed(world_position: Vector2)
signal landed(world_position: Vector2)

@export var balance: PlayerBalance

var hp: int
var stamina: float
var flasks: int = 3
var facing: float = 1.0
var coyote_left: float = 0.0
var jump_buffer_left: float = 0.0
var dodge_left: float = 0.0
var invulnerable_left: float = 0.0
var attack_left: float = 0.0
var attack_cooldown: float = 0.0
var combo_window: float = 0.0
var combo_step: int = 0
var heal_left: float = 0.0
var is_dead: bool = false
var was_on_floor: bool = false
var hit_targets: Dictionary = {}
var body_shape: CollisionShape2D
var hurtbox: Area2D
var attack_area: Area2D
var attack_shape: CollisionShape2D

func _ready() -> void:
	if balance == null: balance = PlayerBalance.new()
	if Engine.is_editor_hint():
		queue_redraw()
		return
	hp = balance.max_hp
	stamina = balance.max_stamina
	setup_collision()
	queue_redraw()
	emit_stats()

func setup_collision() -> void:
	body_shape = CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 12.0
	capsule.height = 42.0
	body_shape.shape = capsule
	body_shape.position = Vector2(0, -21)
	add_child(body_shape)
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 2
	hurtbox.collision_mask = 0
	var hurt_shape := CollisionShape2D.new()
	hurt_shape.shape = capsule.duplicate()
	hurt_shape.position = Vector2(0, -21)
	hurtbox.add_child(hurt_shape)
	add_child(hurtbox)
	attack_area = Area2D.new()
	attack_area.collision_layer = 0
	attack_area.collision_mask = 4
	attack_area.monitoring = false
	attack_area.area_entered.connect(_on_attack_area_entered)
	attack_shape = CollisionShape2D.new()
	var slash_shape := RectangleShape2D.new()
	slash_shape.size = Vector2(62, 45)
	attack_shape.shape = slash_shape
	attack_area.add_child(attack_shape)
	add_child(attack_area)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if is_dead: return
	update_timers(delta)
	if Input.is_action_just_pressed("jump"): jump_buffer_left = balance.jump_buffer_time
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0 and dodge_left <= 0.0 and heal_left <= 0.0:
		start_attack()
	if Input.is_action_just_pressed("dodge") and stamina >= balance.dodge_cost and dodge_left <= 0.0 and heal_left <= 0.0:
		start_dodge()
	if Input.is_action_just_pressed("heal") and flasks > 0 and hp < balance.max_hp and is_on_floor() and attack_left <= 0.0 and dodge_left <= 0.0:
		start_heal()
	if dodge_left > 0.0:
		velocity.x = facing * balance.dodge_speed
		velocity.y = 0.0
		move_and_slide()
		queue_redraw()
		return
	if heal_left > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, balance.deceleration * delta)
	else:
		handle_movement(delta)
	apply_gravity(delta)
	var before_floor := is_on_floor()
	move_and_slide()
	if is_on_floor():
		coyote_left = balance.coyote_time
		if not before_floor and velocity.y >= 0.0: landed.emit(global_position)
	elif was_on_floor:
		coyote_left = balance.coyote_time
	was_on_floor = is_on_floor()
	if jump_buffer_left > 0.0 and coyote_left > 0.0 and heal_left <= 0.0:
		velocity.y = balance.jump_velocity
		jump_buffer_left = 0.0
		coyote_left = 0.0
		Audio.play("jump")
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= balance.jump_cut_multiplier
	if global_position.y > 860.0:
		die()
	stamina = minf(balance.max_stamina, stamina + balance.stamina_regen * delta)
	emit_stats()
	queue_redraw()

func handle_movement(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.05:
		facing = signf(axis)
		velocity.x = move_toward(velocity.x, axis * balance.run_speed, balance.acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, balance.deceleration * delta)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var multiplier := balance.fall_gravity_multiplier if velocity.y > 0.0 else 1.0
		velocity.y += balance.gravity * multiplier * delta
		velocity.y = minf(velocity.y, 900.0)

func update_timers(delta: float) -> void:
	coyote_left = maxf(0.0, coyote_left - delta)
	jump_buffer_left = maxf(0.0, jump_buffer_left - delta)
	dodge_left = maxf(0.0, dodge_left - delta)
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	attack_left = maxf(0.0, attack_left - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	combo_window = maxf(0.0, combo_window - delta)
	if combo_window <= 0.0 and attack_left <= 0.0: combo_step = 0
	if heal_left > 0.0:
		heal_left -= delta
		if heal_left <= 0.0:
			hp = mini(balance.max_hp, hp + balance.heal_amount)
			Audio.play("heal")
			flash(Color("78ffe0"), 0.24)
	attack_area.position = Vector2(facing * 37.0, -22.0)
	if attack_left > 0.0:
		var active := attack_left < 0.18 and attack_left > 0.07
		attack_area.set_deferred("monitoring", active)
	else:
		attack_area.set_deferred("monitoring", false)

func start_attack() -> void:
	combo_step = (combo_step % 3) + 1
	attack_left = 0.28 if combo_step < 3 else 0.36
	attack_cooldown = 0.20 if combo_step < 3 else 0.32
	combo_window = 0.50
	hit_targets.clear()
	Audio.play("slash", 0.92 + combo_step * 0.11)

func start_dodge() -> void:
	if absf(Input.get_axis("move_left", "move_right")) > 0.05:
		facing = signf(Input.get_axis("move_left", "move_right"))
	stamina -= balance.dodge_cost
	dodge_left = balance.dodge_duration
	invulnerable_left = maxf(invulnerable_left, balance.dodge_invulnerability)
	Audio.play("dodge")

func start_heal() -> void:
	flasks -= 1
	heal_left = balance.heal_time
	Audio.play("warning", 0.72)
	emit_stats()

func _on_attack_area_entered(area: Area2D) -> void:
	var target := area.get_parent()
	if not target.has_method("take_damage"): return
	var id := target.get_instance_id()
	if hit_targets.has(id): return
	hit_targets[id] = true
	var damage: int = [0, 20, 24, 34][combo_step]
	target.take_damage(damage, Vector2(facing * (250.0 + combo_step * 40.0), -90.0))
	attack_landed.emit(area.global_position)
	Audio.play("hit", 1.0 + combo_step * 0.08)

func take_damage(amount: int, knockback: Vector2) -> void:
	if is_dead or invulnerable_left > 0.0: return
	hp -= amount
	velocity = knockback
	invulnerable_left = balance.hurt_invulnerability
	attack_left = 0.0
	heal_left = 0.0
	Audio.play("hurt")
	flash(Color("ff365f"), 0.38)
	emit_stats()
	if hp <= 0: die()

func die() -> void:
	if is_dead: return
	is_dead = true
	hp = 0
	body_shape.set_deferred("disabled", true)
	hurtbox.monitorable = false
	Audio.play("death")
	queue_redraw()
	died.emit()

func refill() -> void:
	hp = balance.max_hp
	stamina = balance.max_stamina
	flasks = 3
	emit_stats()

func flash(color: Color, duration: float) -> void:
	modulate = color
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, duration)

func emit_stats() -> void:
	stats_changed.emit(hp, balance.max_hp, stamina, balance.max_stamina, flasks)

func _draw() -> void:
	var bob := sin(Time.get_ticks_msec() * 0.008) * 1.5 if is_on_floor() and absf(velocity.x) < 10.0 else 0.0
	if is_dead:
		draw_circle(Vector2(0, -7), 19, Color(0.20, 0.24, 0.32, 0.7))
		draw_line(Vector2(-26, -2), Vector2(25, -14), Color("7ce8df"), 3)
		return
	var cloak := Color("25334c") if dodge_left <= 0.0 else Color(0.35, 0.86, 0.88, 0.5)
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -35 + bob), Vector2(14, -35 + bob), Vector2(18, 0), Vector2(-20, 0)]), cloak)
	draw_circle(Vector2(0, -43 + bob), 11, Color("d6d7ce"))
	draw_circle(Vector2(facing * 5, -45 + bob), 2.3, Color("72f3e4"))
	draw_line(Vector2(facing * 6, -29 + bob), Vector2(facing * 27, -19 + bob), Color("a9d6de"), 4)
	if attack_left > 0.0:
		var reach := 51.0 + combo_step * 7.0
		draw_arc(Vector2(facing * 15, -24), 34.0, -1.15 if facing > 0 else PI + 0.15, 1.1 if facing > 0 else PI * 2.0 - 1.1, 14, Color("b9fff5"), 5.0)
		draw_line(Vector2(facing * 20, -21), Vector2(facing * reach, -29), Color("eafcff"), 4)
	if heal_left > 0.0:
		draw_arc(Vector2(0, -22), 27, 0, TAU, 20, Color("6affe0"), 3)
	if invulnerable_left > 0.0 and int(invulnerable_left * 18.0) % 2 == 0:
		draw_arc(Vector2(0, -22), 24, 0, TAU, 18, Color(0.7, 0.95, 1.0, 0.5), 2)
