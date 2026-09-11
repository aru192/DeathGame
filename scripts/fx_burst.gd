class_name FXBurst
extends Node2D

var color: Color = Color.WHITE
var radius: float = 8.0
var max_radius: float = 42.0
var duration: float = 0.35
var life: float = 0.0
var rays: int = 8

func setup(p_color: Color, p_max_radius: float = 42.0, p_duration: float = 0.35, p_rays: int = 8) -> FXBurst:
	color = p_color
	max_radius = p_max_radius
	duration = p_duration
	rays = p_rays
	return self

func _process(delta: float) -> void:
	life += delta
	if life >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := life / duration
	var r := lerpf(radius, max_radius, t)
	var c := Color(color, 1.0 - t)
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, c, 3.0 * (1.0 - t) + 1.0)
	for i in rays:
		var angle := TAU * i / rays
		draw_line(Vector2.from_angle(angle) * r * 0.5, Vector2.from_angle(angle) * r, c, 2.0)

