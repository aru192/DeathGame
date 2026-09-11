@tool
class_name SoulCheckpoint
extends Area2D

signal activated(id: int, respawn_position: Vector2)

@export var checkpoint_id: int = 1
var is_active: bool = false
var pulse: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 42
	shape.shape = circle
	shape.position = Vector2(0, -30)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	is_active = GameState.checkpoint_id >= checkpoint_id
	queue_redraw()

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	pulse += delta
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if not body is Player or is_active: return
	is_active = true
	activated.emit(checkpoint_id, global_position + Vector2(0, 0))
	Audio.play("checkpoint")
	queue_redraw()

func _draw() -> void:
	var glow := 0.5 + sin(pulse * 4.2) * 0.2
	var color := Color("6ff5e1") if is_active else Color("607b8b")
	draw_circle(Vector2(0, -31), 26 + glow * 7, Color(color, 0.10 + glow * 0.12))
	draw_line(Vector2(0, 0), Vector2(0, -56), Color("718292"), 6)
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -49), Vector2(0, -73), Vector2(13, -49), Vector2(0, -28)]), color)
	draw_arc(Vector2(0, -51), 28 + glow * 4, 0, TAU, 18, Color(color, 0.55), 2)
