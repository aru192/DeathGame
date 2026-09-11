extends Node

const LevelScene := preload("res://scenes/level.tscn")
const TitleScene := preload("res://scenes/title_screen.tscn")

var current_level: Node
var overlay: CanvasLayer
var title_bg: TextureRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if has_node("TitleScreen"):
		overlay = $TitleScreen
		setup_title_screen()
		Audio.start_bgm()
	else:
		show_title()

func clear_children() -> void:
	get_tree().paused = false
	if is_instance_valid(current_level):
		current_level.queue_free()
		current_level = null
	if is_instance_valid(overlay):
		overlay.queue_free()
		overlay = null

func show_title() -> void:
	clear_children()
	Audio.start_bgm()
	overlay = TitleScene.instantiate()
	add_child(overlay)
	setup_title_screen()

func setup_title_screen() -> void:
	title_bg = overlay.get_node("Background")
	var panel: Panel = overlay.get_node("MenuPanel")
	var continue_btn: Button = panel.get_node("Continue")
	continue_btn.disabled = GameState.checkpoint_id == 0 and GameState.deaths == 0
	continue_btn.pressed.connect(start_game.bind(false))
	var new_btn: Button = panel.get_node("NewGame")
	new_btn.pressed.connect(start_game.bind(true))
	var controls_btn: Button = panel.get_node("Controls")
	controls_btn.pressed.connect(show_help)
	var settings_btn: Button = panel.get_node("Settings")
	settings_btn.pressed.connect(show_settings)
	var footer: Label = panel.get_node("Footer")
	footer.text = "10–15分の高難度短編  •  死亡 %d 回" % GameState.deaths
	new_btn.grab_focus()

func modulate_background(node: TextureRect) -> void:
	node.modulate = Color(0.72, 0.79, 0.90, 1.0)

func start_game(new_run: bool) -> void:
	if new_run:
		GameState.new_game()
	clear_children()
	current_level = LevelScene.instantiate()
	add_child(current_level)
	current_level.return_to_title.connect(show_title)
	current_level.game_completed.connect(show_clear)

func show_clear() -> void:
	GameState.mark_complete()
	Audio.play("victory")
	if is_instance_valid(current_level): current_level.queue_free()
	current_level = null
	overlay = CanvasLayer.new()
	overlay.layer = 80
	add_child(overlay)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0a1020")
	overlay.add_child(bg)
	var crown := make_label("✦", 82, Color("7ce8df"))
	crown.position = Vector2(608, 90)
	overlay.add_child(crown)
	var title := make_label("THE BELL FALLS SILENT", 40, Color("e6f5ff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(290, 210)
	title.size = Vector2(700, 60)
	overlay.add_child(title)
	var body := make_label("灰の番人は倒れ、暁は再び谷を照らした。\nあなたの死は %d 回。すべてが道標になった。" % GameState.deaths, 20, Color("aebdd0"))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.position = Vector2(290, 292)
	body.size = Vector2(700, 80)
	overlay.add_child(body)
	var retry := make_button("もう一度", Vector2(475, 410), Vector2(330, 52))
	retry.pressed.connect(start_game.bind(true))
	overlay.add_child(retry)
	var menu := make_button("タイトルへ", Vector2(475, 478), Vector2(330, 52))
	menu.pressed.connect(show_title)
	overlay.add_child(menu)
	retry.grab_focus()

func show_help() -> void:
	var modal := make_modal("操作説明")
	var text := make_label("移動  A / D・← →・左スティック\nジャンプ  Space・下ボタン（長押しで高く）\n攻撃  J・左クリック・左ボタン（3段コンボ）\n回避  K / Shift・右ボタン（無敵あり）\n回復  R・上ボタン\n一時停止  Esc・メニューボタン\nデバッグ表示  F3\n\n青白い光＝安全 / 深紅の光＝攻撃予兆\n敵の予備動作を見て、欲張らずに切り抜けよう。", 19, Color("d3deec"))
	text.position = Vector2(48, 78)
	text.add_theme_font_size_override("font_size", 19)
	text.add_theme_color_override("font_color", Color("d3deec"))
	modal.add_child(text)

func show_settings() -> void:
	var modal := make_modal("設定")
	var y := 92.0
	for spec in [["master", "マスター"], ["bgm", "BGM"], ["sfx", "効果音"]]:
		var label := make_label(spec[1], 18, Color("d3deec"))
		label.position = Vector2(55, y)
		modal.add_child(label)
		var slider := HSlider.new()
		slider.position = Vector2(190, y + 2)
		slider.size = Vector2(280, 28)
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = float(GameState.settings[spec[0]])
		slider.value_changed.connect(_on_volume_changed.bind(spec[0]))
		modal.add_child(slider)
		y += 68
	var debug := CheckButton.new()
	debug.text = "デバッグ表示を有効化（F3でも切替）"
	debug.position = Vector2(50, y + 12)
	debug.button_pressed = bool(GameState.settings.debug)
	debug.toggled.connect(_on_debug_toggled)
	modal.add_child(debug)

func _on_volume_changed(value: float, key: String) -> void:
	GameState.update_setting(key, value)

func _on_debug_toggled(value: bool) -> void:
	GameState.update_setting("debug", value)

func make_modal(title_text: String) -> Panel:
	var modal := make_panel(Vector2(350, 95), Vector2(580, 530))
	overlay.add_child(modal)
	var title := make_label(title_text, 30, Color("e5f3ff"))
	title.position = Vector2(42, 24)
	modal.add_child(title)
	var close := make_button("閉じる", Vector2(170, 450), Vector2(240, 44))
	close.pressed.connect(modal.queue_free)
	modal.add_child(close)
	close.grab_focus()
	return modal

func make_panel(pos: Vector2, panel_size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = panel_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.09, 0.94)
	style.border_color = Color("38516a")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)
	return panel

func make_label(text: String, size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	return label

func make_button(text: String, pos: Vector2, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = button_size
	button.add_theme_font_size_override("font_size", 18)
	return button
