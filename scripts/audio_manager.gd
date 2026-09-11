extends Node

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var tones: Dictionary = {}

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = &"BGM"
	add_child(bgm_player)
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		sfx_players.append(p)
	build_tones()

func build_tones() -> void:
	tones = {
		"jump": make_tone(420.0, 0.09, 0.22, true),
		"slash": make_tone(190.0, 0.10, 0.32, false),
		"hit": make_tone(85.0, 0.14, 0.50, false),
		"hurt": make_tone(62.0, 0.22, 0.52, false),
		"dodge": make_tone(280.0, 0.12, 0.20, true),
		"heal": make_tone(620.0, 0.34, 0.16, true),
		"checkpoint": make_chord([330.0, 440.0, 660.0], 0.55, 0.18),
		"warning": make_tone(740.0, 0.18, 0.20, false),
		"death": make_tone(48.0, 0.65, 0.50, false),
		"victory": make_chord([262.0, 392.0, 523.0], 1.2, 0.20)
	}

func play(name: String, pitch: float = 1.0) -> void:
	if not tones.has(name): return
	for p in sfx_players:
		if not p.playing:
			p.stream = tones[name]
			p.pitch_scale = pitch
			p.play()
			return

func start_bgm() -> void:
	if bgm_player.playing: return
	bgm_player.stream = make_ambient_loop()
	bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func make_tone(freq: float, seconds: float, volume: float, rising: bool) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(seconds * rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / rate
		var f := freq * (1.0 + (0.6 * t / seconds if rising else -0.25 * t / seconds))
		var env := pow(1.0 - float(i) / samples, 2.0)
		var sample := int(sin(TAU * f * t) * env * volume * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func make_chord(freqs: Array, seconds: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var samples := int(seconds * rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / rate
		var v := 0.0
		for f in freqs: v += sin(TAU * float(f) * t)
		v /= freqs.size()
		var env := sin(PI * float(i) / samples) * (1.0 - float(i) / samples * 0.3)
		data.encode_s16(i * 2, int(v * env * volume * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func make_ambient_loop() -> AudioStreamWAV:
	var rate := 22050
	var seconds := 8.0
	var samples := int(seconds * rate)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var notes := [55.0, 65.41, 73.42, 49.0]
	for i in samples:
		var t := float(i) / rate
		var note: float = notes[int(t / 2.0) % notes.size()]
		var v := sin(TAU * note * t) * 0.15 + sin(TAU * note * 1.5 * t) * 0.06
		v *= 0.45 + 0.25 * sin(TAU * t / 8.0)
		data.encode_s16(i * 2, int(v * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples
	wav.data = data
	return wav

