class_name EnemyProjectile
extends Area2D

var direction: Vector2 = Vector2.LEFT
var speed: float = 330.0
var damage: int = 18
var lifetime: float = 4.0
var tint: Color = Color("f05b78")
var radius: float = 7.0
var gravity_force: float = 0.0

func _ready() -> void:
	add_to_group("enemy_projectiles")
	area_entered.connect(_on_area_entered)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	queue_redraw()

func _physics_process(delta: float) -> void:
	direction.y += gravity_force * delta
	global_position += direction.normalized() * speed * delta
	lifetime -= delta
	rotation += delta * 7.0
	if lifetime <= 0.0: queue_free()
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	var target := area.get_parent()
	if target.has_method("take_damage"):
		target.take_damage(damage, direction.normalized() * 260.0 + Vector2(0, -120))
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius + 4.0, Color(tint, 0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(-radius, 0), Vector2(0, -radius), Vector2(radius, 0), Vector2(0, radius)]), tint)
	draw_line(Vector2(-radius - 15, 0), Vector2(-radius, 0), Color(tint, 0.45), 3)
