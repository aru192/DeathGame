@tool
class_name EditablePlatform
extends StaticBody2D

@export var size: Vector2 = Vector2(200, 40):
	set(value):
		size = value
		_sync_shape()
		queue_redraw()

@export var surface_color: Color = Color("526278"):
	set(value):
		surface_color = value
		queue_redraw()

@export var body_color: Color = Color("171e2e"):
	set(value):
		body_color = value
		queue_redraw()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_sync_shape()
	queue_redraw()

func _sync_shape() -> void:
	if not is_node_ready() or not is_instance_valid(collision_shape):
		return
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision_shape.shape = rectangle

func world_rect() -> Rect2:
	return Rect2(global_position - size * 0.5, size)

func _draw() -> void:
	draw_rect(Rect2(-size * 0.5, size), body_color)
	draw_rect(Rect2(Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(size.x, 7)), surface_color)
	for x in range(int(-size.x * 0.5) + 18, int(size.x * 0.5), 48):
		draw_line(Vector2(x, -size.y * 0.5 + 9), Vector2(x - 13, -size.y * 0.5 + 31), Color("252e40"), 3)

