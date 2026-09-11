class_name GameHUD
extends CanvasLayer

signal resume_requested
signal retry_requested
signal title_requested

var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var flask_label: Label
var death_label: Label
var area_label: Label
var boss_panel: Control
var boss_bar: ProgressBar
var boss_name: Label
var message_label: Label
var pause_panel: Panel
var debug_label: Label

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	if has_node("StatusPanel"):
		bind_authored_nodes()
	else:
		build_hud()

func bind_authored_nodes() -> void:
	hp_bar = $StatusPanel/HPBar
	stamina_bar = $StatusPanel/StaminaBar
	flask_label = $StatusPanel/FlaskLabel
	death_label = $StatusPanel/DeathLabel
	area_label = $AreaLabel
	boss_panel = $BossPanel
	boss_bar = $BossPanel/BossBar
	boss_name = $BossPanel/BossName
	message_label = $MessageLabel
	debug_label = $DebugLabel
	pause_panel = $PausePanel
	$PausePanel/Resume.pressed.connect(resume_requested.emit)
	$PausePanel/Retry.pressed.connect(retry_requested.emit)
	$PausePanel/Title.pressed.connect(title_requested.emit)
	debug_label.visible = bool(GameState.settings.debug)

func build_hud() -> void:
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.02, 0.03, 0.06, 0.08)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	var panel := Panel.new()
	panel.position = Vector2(24, 22)
	panel.size = Vector2(335, 105)
	panel.add_theme_stylebox_override("panel", panel_style())
	add_child(panel)
	hp_bar = make_bar(Vector2(70, 17), Vector2(240, 22), Color("b52d4a"))
	hp_bar.max_value = 100
	panel.add_child(hp_bar)
	stamina_bar = make_bar(Vector2(70, 52), Vector2(240, 16), Color("4db7a0"))
	stamina_bar.max_value = 100
	panel.add_child(stamina_bar)
	var hp_text := make_label("HP", 15, Color.WHITE)
	hp_text.position = Vector2(20, 15)
	panel.add_child(hp_text)
	var st_text := make_label("ST", 15, Color.WHITE)
	st_text.position = Vector2(20, 49)
	panel.add_child(st_text)
	flask_label = make_label("霊薬 × 3", 16, Color("8ce8d7"))
	flask_label.position = Vector2(19, 77)
	panel.add_child(flask_label)
	death_label = make_label("死亡 0", 16, Color("c5ccda"))
	death_label.position = Vector2(248, 77)
	panel.add_child(death_label)
	area_label = make_label("灰哭きの参道", 19, Color("dcecff"))
	area_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area_label.position = Vector2(410, 24)
	area_label.size = Vector2(460, 34)
	add_child(area_label)
	boss_panel = Control.new()
	boss_panel.position = Vector2(300, 628)
	boss_panel.size = Vector2(680, 72)
	boss_panel.visible = false
	add_child(boss_panel)
	boss_name = make_label("鐘守ヴァルグリム", 17, Color("e6e9f0"))
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.size = Vector2(680, 24)
	boss_panel.add_child(boss_name)
	boss_bar = make_bar(Vector2(0, 30), Vector2(680, 24), Color("8d2747"))
	boss_panel.add_child(boss_bar)
	message_label = make_label("", 25, Color("eaf8ff"))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.position = Vector2(240, 116)
	message_label.size = Vector2(800, 44)
	add_child(message_label)
	debug_label = make_label("", 13, Color("7ef0cc"))
	debug_label.position = Vector2(900, 24)
	debug_label.size = Vector2(350, 180)
	debug_label.visible = bool(GameState.settings.debug)
	add_child(debug_label)
	build_pause()

func build_pause() -> void:
	pause_panel = Panel.new()
	pause_panel.position = Vector2(430, 150)
	pause_panel.size = Vector2(420, 420)
	pause_panel.add_theme_stylebox_override("panel", panel_style())
	pause_panel.visible = false
	add_child(pause_panel)
	var title := make_label("PAUSED", 34, Color("eaf2ff"))
	title.position = Vector2(137, 28)
	pause_panel.add_child(title)
	var resume := make_button("再開", Vector2(80, 100))
	resume.pressed.connect(resume_requested.emit)
	pause_panel.add_child(resume)
	var retry := make_button("チェックポイントからリトライ", Vector2(80, 160))
	retry.pressed.connect(retry_requested.emit)
	pause_panel.add_child(retry)
	var title_btn := make_button("タイトルへ戻る", Vector2(80, 220))
	title_btn.pressed.connect(title_requested.emit)
	pause_panel.add_child(title_btn)
	var hint := make_label("Esc / メニューボタンで再開", 15, Color("8795aa"))
	hint.position = Vector2(92, 310)
	pause_panel.add_child(hint)

func update_player(hp: int, max_hp: int, stamina: float, max_stamina: float, flasks: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina
	flask_label.text = "霊薬 × %d" % flasks
	death_label.text = "死亡 %d" % GameState.deaths

func show_boss(current: int, maximum: int, phase: int) -> void:
	boss_panel.visible = true
	boss_bar.max_value = maximum
	boss_bar.value = current
	boss_name.text = "鐘守ヴァルグリム" + ("  — 第二相 —" if phase == 2 else "")

func hide_boss() -> void:
	boss_panel.visible = false

func show_message(text: String, duration: float = 2.0) -> void:
	message_label.text = text
	var tween := create_tween()
	message_label.modulate.a = 0.0
	tween.tween_property(message_label, "modulate:a", 1.0, 0.18)
	tween.tween_interval(duration)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.35)

func set_paused(value: bool) -> void:
	pause_panel.visible = value
	if value:
		var resume_button := pause_panel.get_node_or_null("Resume")
		if resume_button: resume_button.grab_focus()
		elif pause_panel.get_child_count() > 1: pause_panel.get_child(1).grab_focus()

func toggle_debug() -> void:
	debug_label.visible = not debug_label.visible
	GameState.update_setting("debug", debug_label.visible)

func update_debug(text: String) -> void:
	debug_label.text = text

func make_bar(pos: Vector2, bar_size: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = bar_size
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("111827")
	bg.set_border_width_all(1)
	bg.border_color = Color("506176")
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	return bar

func make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func make_button(text: String, pos: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = Vector2(260, 45)
	button.add_theme_font_size_override("font_size", 17)
	return button

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.045, 0.075, 0.94)
	style.border_color = Color("415873")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	return style
