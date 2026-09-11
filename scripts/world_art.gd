class_name WorldArt
extends Node2D

var platforms: Array[Rect2] = []

func _draw() -> void:
	for rect in platforms:
		draw_rect(rect, Color("171e2e"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 7)), Color("526278"))
		for x in range(int(rect.position.x) + 20, int(rect.end.x), 48):
			draw_line(Vector2(x, rect.position.y + 8), Vector2(x - 13, rect.position.y + 32), Color("252e40"), 3)
	for x in range(100, 4900, 210):
		draw_line(Vector2(x, 600), Vector2(x + 30, 530 - (x % 3) * 22), Color(0.13, 0.17, 0.25, 0.65), 6)

