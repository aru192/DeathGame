@tool
class_name Enemy
extends CharacterBody2D

signal defeated(enemy: Enemy)

enum Kind { WARDEN, HEXER, LURKER }
enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVER, HURT, DEAD }

@export var kind: Kind = Kind.WARDEN:
	set(value):
		kind = value
		if Engine.is_editor_hint():
			configure_kind()
			queue_redraw()
@export var max_hp: int = 55
@export var detection_range: float = 390.0
@export var attack_range: float = 64.0
@export var move_speed: float = 105.0

var hp: int
var state: State = State.IDLE
var state_time: float = 0.0
var facing: float = -1.0
var target: Player
var home_x: float
var hurtbox: Area2D
var attack_area: Area2D
var attack_shape: CollisionShape2D
var already_hit: bool = false
var gravity: float = 1500.0
var revealed: bool = false

const ProjectileScene := preload("res://scenes/projectile.tscn")

func _ready() -> void:
	home_x = global_position.x
	configure_kind()
	hp = max_hp
	if Engine.is_editor_hint():
		revealed = true
		queue_redraw()
		return
	setup_collision()
	queue_redraw()

func configure_kind() -> void:
	match kind:
		Kind.WARDEN:
			max_hp = 62; detection_range = 380.0; attack_range = 65.0; move_speed = 115.0
		Kind.HEXER:
			max_hp = 44; detection_range = 510.0; attack_range = 300.0; move_speed = 78.0
		Kind.LURKER:
			max_hp = 48; detection_range = 290.0; attack_range = 220.0; move_speed = 550.0

func setup_collision() -> void:
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 14
	capsule.height = 42
	shape.shape = capsule
	shape.position = Vector2(0, -21)
	add_child(shape)
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	var hs := CollisionShape2D.new()
	hs.shape = capsule.duplicate()
	hs.position = Vector2(0, -21)
	hurtbox.add_child(hs)
	add_child(hurtbox)
	attack_area = Area2D.new()
	attack_area.collision_layer = 0
	attack_area.collision_mask = 2
	attack_area.monitoring = false
	attack_area.area_entered.connect(_on_attack_area_entered)
	attack_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(70, 45)
	attack_shape.shape = rect
	attack_area.add_child(attack_shape)
	add_child(attack_area)

func set_target(player: Player) -> void:
	target = player

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if state == State.DEAD: return
	state_time -= delta
	if not is_on_floor(): velocity.y += gravity * delta
	if not is_instance_valid(target) or target.is_dead:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		move_and_slide()
		return
	var dx := target.global_position.x - global_position.x
	var distance := absf(dx)
	if distance > 1.0: facing = signf(dx)
	match state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if distance < detection_range and absf(target.global_position.y - global_position.y) < 190.0:
				if kind == Kind.LURKER:
					revealed = true
					change_state(State.WINDUP, 0.75)
				else: change_state(State.CHASE, 0.1)
		State.CHASE:
			if kind == Kind.HEXER:
				var desired := -facing * move_speed if distance < 205.0 else facing * move_speed
				velocity.x = move_toward(velocity.x, desired, 550.0 * delta)
				if distance <= attack_range and state_time <= 0.0: change_state(State.WINDUP, 0.72)
			else:
				velocity.x = move_toward(velocity.x, facing * move_speed, 700.0 * delta)
				if distance <= attack_range: change_state(State.WINDUP, 0.48)
				elif distance > detection_range * 1.45: change_state(State.IDLE, 0.2)
		State.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 1000.0 * delta)
			if state_time <= 0.0: begin_attack()
		State.ATTACK:
			if kind == Kind.LURKER:
				velocity.x = facing * move_speed
			else: velocity.x = move_toward(velocity.x, 0.0, 850.0 * delta)
			if state_time <= 0.0:
				attack_area.set_deferred("monitoring", false)
				change_state(State.RECOVER, 0.55 if kind != Kind.LURKER else 0.78)
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 950.0 * delta)
			if state_time <= 0.0: change_state(State.CHASE, 0.12)
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			if state_time <= 0.0: change_state(State.CHASE, 0.12)
	attack_area.position = Vector2(facing * (46.0 if kind != Kind.LURKER else 38.0), -21)
	move_and_slide()
	queue_redraw()

func begin_attack() -> void:
	already_hit = false
	if kind == Kind.HEXER:
		fire_projectile()
		change_state(State.ATTACK, 0.20)
	else:
		attack_area.set_deferred("monitoring", true)
		change_state(State.ATTACK, 0.24 if kind == Kind.WARDEN else 0.43)
	Audio.play("slash", 0.65 if kind == Kind.WARDEN else 0.82)

func fire_projectile() -> void:
	if not is_instance_valid(target): return
	var projectile: EnemyProjectile = ProjectileScene.instantiate()
	projectile.global_position = global_position + Vector2(facing * 24, -32)
	projectile.direction = (target.global_position + Vector2(0, -22) - projectile.global_position).normalized()
	projectile.speed = 315.0
	projectile.damage = 18
	projectile.tint = Color("d95b93")
	get_parent().add_child(projectile)

func _on_attack_area_entered(area: Area2D) -> void:
	if already_hit: return
	var player := area.get_parent()
	if player.has_method("take_damage"):
		already_hit = true
		var damage := 22 if kind == Kind.WARDEN else 26
		player.take_damage(damage, Vector2(facing * 310.0, -165.0))

func take_damage(amount: int, knockback: Vector2) -> void:
	if state == State.DEAD: return
	hp -= amount
	velocity = knockback
	Audio.play("hit")
	if hp <= 0:
		die()
	else:
		change_state(State.HURT, 0.24)
		flash()

func die() -> void:
	state = State.DEAD
	attack_area.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	velocity = Vector2.ZERO
	queue_redraw()
	defeated.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 0.15), 0.22)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.32)
	tween.tween_callback(queue_free)

func change_state(next: State, duration: float) -> void:
	state = next
	state_time = duration
	queue_redraw()

func flash() -> void:
	modulate = Color("ff7187")
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.22)

func state_name() -> String:
	return State.keys()[state]

func _draw() -> void:
	if kind == Kind.LURKER and not revealed:
		draw_colored_polygon(PackedVector2Array([Vector2(-16, 0), Vector2(0, -16), Vector2(16, 0)]), Color("151b2c"))
		return
	var telegraph := state == State.WINDUP
	if telegraph:
		var pulse := 0.55 + sin(Time.get_ticks_msec() * 0.025) * 0.35
		draw_circle(Vector2(0, -24), 30, Color(0.95, 0.18, 0.30, pulse * 0.32))
	match kind:
		Kind.WARDEN:
			draw_colored_polygon(PackedVector2Array([Vector2(-17, 0), Vector2(-13, -40), Vector2(13, -40), Vector2(19, 0)]), Color("4c2c3d"))
			draw_circle(Vector2(0, -45), 12, Color("b8a8a5"))
			draw_line(Vector2(facing * 8, -28), Vector2(facing * 31, -12), Color("c9ced5"), 5)
		Kind.HEXER:
			draw_colored_polygon(PackedVector2Array([Vector2(-19, 0), Vector2(-10, -43), Vector2(10, -43), Vector2(19, 0)]), Color("372758"))
			draw_circle(Vector2(0, -47), 10, Color("927db0"))
			draw_circle(Vector2(facing * 19, -29), 6, Color("ee72bd") if telegraph else Color("8a4a88"))
		Kind.LURKER:
			draw_colored_polygon(PackedVector2Array([Vector2(-24, -3), Vector2(-8, -36), Vector2(19, -31), Vector2(25, 0)]), Color("26394b"))
			draw_line(Vector2(facing * 8, -22), Vector2(facing * 32, -19), Color("e34d65"), 6)
	if state == State.ATTACK:
		draw_line(Vector2(facing * 10, -22), Vector2(facing * 51, -22), Color("ff6b79"), 5)
