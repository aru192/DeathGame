extends Node

signal settings_changed
signal save_changed

const SAVE_PATH := "user://ashen_vigil_save.json"
const VERSION := 1

var deaths: int = 0
var checkpoint_id: int = 0
var checkpoint_position: Vector2 = Vector2(115, 600)
var completed: bool = false
var settings: Dictionary = {
	"master": 0.85,
	"bgm": 0.70,
	"sfx": 0.85,
	"debug": false
}

func _ready() -> void:
	load_game()

func new_game() -> void:
	deaths = 0
	checkpoint_id = 0
	checkpoint_position = Vector2(115, 600)
	completed = false
	save_game()

func set_checkpoint(id: int, pos: Vector2) -> void:
	if id < checkpoint_id:
		return
	checkpoint_id = id
	checkpoint_position = pos
	save_game()

func record_death() -> void:
	deaths += 1
	save_game()

func mark_complete() -> void:
	completed = true
	save_game()

func save_game() -> void:
	var data := {
		"version": VERSION,
		"deaths": deaths,
		"checkpoint_id": checkpoint_id,
		"checkpoint": [checkpoint_position.x, checkpoint_position.y],
		"completed": completed,
		"settings": settings
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		save_changed.emit()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		apply_audio_settings()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		apply_audio_settings()
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		apply_audio_settings()
		return
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		apply_audio_settings()
		return
	var data: Dictionary = parsed
	deaths = maxi(0, int(data.get("deaths", 0)))
	checkpoint_id = clampi(int(data.get("checkpoint_id", 0)), 0, 2)
	var cp: Array = data.get("checkpoint", [115.0, 600.0])
	if cp.size() == 2:
		checkpoint_position = Vector2(float(cp[0]), float(cp[1]))
	completed = bool(data.get("completed", false))
	var loaded_settings: Variant = data.get("settings", {})
	if loaded_settings is Dictionary:
		for key in settings.keys():
			if loaded_settings.has(key): settings[key] = loaded_settings[key]
	apply_audio_settings()

func apply_audio_settings() -> void:
	for bus_name: String in ["Master", "BGM", "SFX"]:
		var key: String = bus_name.to_lower()
		var value: float = clampf(float(settings.get(key, 0.8)), 0.0, 1.0)
		var idx := AudioServer.get_bus_index(bus_name)
		if idx >= 0:
			AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.001)))
	settings_changed.emit()

func update_setting(key: String, value: Variant) -> void:
	settings[key] = value
	apply_audio_settings()
	save_game()
