@tool
class_name DeathHazard
extends Area2D

enum Kind { SPIKES, PERIODIC, PROXIMITY }

@export var kind: Kind = Kind.SPIKES:
	set(value):
		kind = value
		if Engine.is_editor_hint(): queue_redraw()
@export var size: Vector2 = Vector2(90, 28):
	set(value):
		size = value
		if Engine.is_editor_hint(): queue_redraw()
@export var damage: int = 28
@export var period: float = 2.4
@export var active_time: float = 0.72
@export var trigger_distance: float = 180.0

var active: bool = true
var timer: float = 0.0
var triggered: bool = false
var warning: bool = false
var hit_cooldown: Dictionary = {}
var target: Player

func _ready() -> void:
	if Engine.is_editor_hint():
		active = true
		queue_redraw()
		return
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	collision.shape = rect
	collision.position = Vector2(0, -size.y * 0.5)
	add_child(collision)
	monitoring = true
	if kind != Kind.SPIKES:
		active = false
		timer = 0.6 if kind == Kind.PERIODIC else 0.0
	queue_redraw()

func set_target(player: Player) -> void:
	target = player

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	for id in hit_cooldown.keys():
		hit_cooldown[id] = float(hit_cooldown[id]) - delta
		if hit_cooldown[id] <= 0.0: hit_cooldown.erase(id)
	match kind:
		Kind.PERIODIC:
			timer += delta
			var cycle := fmod(timer, period)
			warning = cycle > period - 0.42
			active = cycle < active_time
		Kind.PROXIMITY:
			if not triggered and is_instance_valid(target) and target.global_position.distance_to(global_position) < trigger_distance:
				triggered = true
				warning = true
				timer = 0.72
				Audio.play("warning", 1.15)
			if triggered and warning:
				timer -= delta
				if timer <= 0.0:
					warning = false
					active = true
					timer = 0.55
			elif active:
				timer -= delta
				if timer <= 0.0: active = false
	if active:
		for body in get_overlapping_bodies():
			if body.has_method("take_damage"): damage_body(body)
	queue_redraw()

func damage_body(body: Node) -> void:
	var id := body.get_instance_id()
	if hit_cooldown.has(id): return
	hit_cooldown[id] = 0.8
	var dir := signf(body.global_position.x - global_position.x)
	if dir == 0: dir = 1
	body.take_damage(damage, Vector2(dir * 230, -310))

func _draw() -> void:
	var base_color := Color("9b2948") if active else Color("3e4051")
	if warning: base_color = Color("ffb347")
	match kind:
		Kind.SPIKES, Kind.PERIODIC:
			var count := maxi(2, int(size.x / 18.0))
			var step := size.x / count
			for i in count:
				var x := -size.x * 0.5 + i * step
				var height := size.y if active else 7.0
				draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + step * 0.5, -height), Vector2(x + step, 0)]), base_color)
			draw_line(Vector2(-size.x * 0.5, 0), Vector2(size.x * 0.5, 0), Color("2b3141"), 4)
		Kind.PROXIMITY:
			draw_rect(Rect2(-size.x * 0.5, -8, size.x, 8), Color("282d3b"))
			if warning:
				draw_line(Vector2(-size.x * 0.5, -42), Vector2(size.x * 0.5, -42), Color("ffb347"), 3)
			if active:
				for i in 5:
					var x := -size.x * 0.4 + i * size.x * 0.2
					draw_line(Vector2(x, -75), Vector2(x, -5), base_color, 9)
