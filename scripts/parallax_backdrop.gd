@tool
class_name ParallaxBackdrop
extends Control

var camera: Camera2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var cam_x := camera.global_position.x if is_instance_valid(camera) else 0.0
	draw_rect(Rect2(Vector2.ZERO, size), Color("080d1a"))
	var moon_x := 1050.0 - fmod(cam_x * 0.025, 1450.0)
	draw_circle(Vector2(moon_x, 145), 88, Color("74243e"))
	draw_circle(Vector2(moon_x - 15, 138), 74, Color("0a1020"))
	var far_offset := -fmod(cam_x * 0.08, 340.0)
	for i in 7:
		var x := far_offset + i * 340.0 - 120.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 530), Vector2(x + 155, 230 + (i % 3) * 55), Vector2(x + 340, 530)]), Color("131b2c"))
	var mid_offset := -fmod(cam_x * 0.18, 260.0)
	for i in 8:
		var x := mid_offset + i * 260.0 - 80.0
		draw_rect(Rect2(x, 355 + (i % 2) * 55, 52, 250), Color("101727"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 14, 360 + (i % 2) * 55), Vector2(x + 26, 305 + (i % 2) * 55), Vector2(x + 66, 360 + (i % 2) * 55)]), Color("101727"))
	var fog_offset := -fmod(cam_x * 0.32, 420.0)
	for i in 5:
		draw_circle(Vector2(fog_offset + i * 420.0, 570 + sin(i) * 25), 180, Color(0.18, 0.27, 0.36, 0.07))
