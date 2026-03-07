extends Node

## AudioManager (Autoload)
## 负责全局音效池、背景音乐切换、环境音混合以及音量总线控制。
## Automatically tries to load .ogg then .wav for sound keys.

# --- 常量配置 ---
const SFX_POOL_SIZE = 12
const SFX_POOL_2D_SIZE = 8

# --- 音频资源库 ---
var audio_library: Dictionary = {}

# --- 节点池 ---
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_2d: Array[AudioStreamPlayer2D] = []
var _current_pool_idx: int = 0
var _current_pool_2d_idx: int = 0

# --- 专用播放器 ---
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var _keep_alive_player: AudioStreamPlayer

# 防抖机制：防止同一种音效在极短时间内多次播放
var _last_played_time: Dictionary = {}
const MIN_PLAY_INTERVAL_MS = 100 # 100ms 最小间隔

# --- 初始化 ---
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_ensure_buses_exist()
	
	# FIX: Ensure Master bus is unmuted (AudioServer state protection)
	var master_bus_index = AudioServer.get_bus_index("Master")
	if master_bus_index != -1:
		AudioServer.set_bus_mute(master_bus_index, false)
		AudioServer.set_bus_volume_db(master_bus_index, 0.0)
	
	music_player = AudioStreamPlayer.new()
	ambient_player = AudioStreamPlayer.new()
	
	print("AudioManager: Scanning audio files...")
	
	# 动态加载所有音效 (优先 .ogg, 其次 .wav)
	# 键名对应 assets/audio/ 下的路径 (不含扩展名)
	var key_map = {
		"hover": "res://assets/audio/sfx/ui_hover",
		"click": "res://assets/audio/sfx/ui_click",
		"cancel": "res://assets/audio/sfx/ui_cancel",
		"jump": "res://assets/audio/sfx/player_jump",
		"land": "res://assets/audio/sfx/player_land",
		"footstep": "res://assets/audio/sfx/player_step",
		"footstep_grass": "res://assets/audio/sfx/player_step",  
		"footstep_dirt": "res://assets/audio/sfx/player_step", 
		"build": "res://assets/audio/sfx/build",
		"thunder": "res://assets/audio/sfx/thunder",
		"rain": "res://assets/audio/ambient/rain",
		"ui_hover": "res://assets/audio/sfx/ui_hover",
		"ui_click": "res://assets/audio/sfx/ui_click",
		"spell_fire": "res://assets/audio/sfx/spell_fire",
	}

	for k in key_map:
		var stream = _try_load(key_map[k])
		if stream:
			audio_library[k] = stream
			print("AudioManager: Loaded '%s' -> %s" % [k, key_map[k]])
		else:
			# Fallback: Try with .import check or direct load if resource exists in some form
			var res_path = key_map[k] + ".ogg"
			if ResourceLoader.exists(res_path):
				audio_library[k] = load(res_path)
			else:
				res_path = key_map[k] + ".wav"
				if ResourceLoader.exists(res_path):
					audio_library[k] = load(res_path)
			
			if audio_library.has(k):
				print("AudioManager: Loaded '%s' via ResourceLoader (Fallback) -> %s" % [k, res_path])
			else:
				printerr("AudioManager: FAILED to load '%s' (checked .ogg and .wav at %s)" % [k, key_map[k]])

	_setup_dedicated_players()
	_setup_pools()
	
	# 把 Keep-alive 的创建移到资源加载之后，确保它能拿到 ui_hover
	_setup_keep_alive()
	
	print("AudioManager FINAL KEYS: ", audio_library.keys())
	
	# Initial Warm-up: Play a silent sound to force the audio engine to wake up.
	# This fixes the issue where SFX wouldn't play unless an ambient track ('rain') was active.
	_warm_up_audio_engine()

func _ensure_buses_exist() -> void:
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx == -1: return

	# Check and Create SFX Bus
	if AudioServer.get_bus_index("SFX") == -1:
		print("AudioManager: Creating dynamic 'SFX' bus")
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

	# Check and Create Music Bus
	if AudioServer.get_bus_index("Music") == -1:
		print("AudioManager: Creating dynamic 'Music' bus")
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")

	# Check and Create Ambient Bus
	if AudioServer.get_bus_index("Ambient") == -1:
		print("AudioManager: Creating dynamic 'Ambient' bus")
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "Ambient")
		AudioServer.set_bus_send(idx, "Master")

	# Check and Create LowPass Filter Bus for Heavy SFX
	if AudioServer.get_bus_index("SFX_LowPass") == -1:
		print("AudioManager: Creating dynamic 'SFX_LowPass' bus")
		AudioServer.add_bus()
		var idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "SFX_LowPass")
		AudioServer.set_bus_send(idx, "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master")
		
		# Add LowPassFilter Effect
		var filter = AudioEffectLowPassFilter.new()
		filter.cutoff_hz = 3000 # Cut off high frequencies to remove sharpness
		filter.resonance = 0.5
		AudioServer.add_bus_effect(idx, filter)

func _setup_keep_alive() -> void:
	# 强力保活方案：创建一个永久循环的静音流
	if is_instance_valid(_keep_alive_player):
		_keep_alive_player.queue_free()
		
	_keep_alive_player = AudioStreamPlayer.new()
	_keep_alive_player.name = "AudioEngine_Stabilizer"
	_keep_alive_player.bus = "Master"
	add_child(_keep_alive_player)
	
	# 创建一个纯静音的 1秒循环流
	var playback = AudioStreamWAV.new()
	playback.data = PackedByteArray([0, 0, 0, 0])
	playback.format = AudioStreamWAV.FORMAT_8_BITS
	playback.loop_mode = AudioStreamWAV.LOOP_FORWARD
	playback.loop_begin = 0
	playback.loop_end = 1
	
	_keep_alive_player.stream = playback
	_keep_alive_player.volume_db = -80.0
	_keep_alive_player.play()
	
	# 特殊处理：强制刷新 AudioServer 状态
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	print("AudioManager: Audio stabilizer active (Hard-reset Master)")

func _warm_up_audio_engine() -> void:
	if audio_library.has("hover")||1:
		var p = AudioStreamPlayer.new()
		p.name = "WarmUp"
		p.stream = audio_library["hover"]
		p.volume_db = -80.0 # Silent
		p.bus = "Master"
		add_child(p)
		p.play()
		# Clean up after a short delay
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(p.queue_free)
		print("AudioManager: Engine warmed up (silent play)")
	
	# Fix: Pre-warm the audio engine to prevent first SFX failure
	# This mimics the side-effect of play_ambient("rain") but silently
	call_deferred("_warmup_audio_engine")

func _warmup_audio_engine() -> void:
	# Play a silent sound on Master to wake up the engine
	if audio_library.has("ui_hover") and audio_library["ui_hover"]:
		print("AudioManager: Warming up audio engine...")
		var p = AudioStreamPlayer.new()
		p.name = "AudioWarmup"
		p.bus = "Master"
		add_child(p)
		p.stream = audio_library["ui_hover"]
		p.volume_db = -80.0 # Silent
		p.play()
		p.finished.connect(p.queue_free)
	else:
		print("AudioManager: Could not find 'ui_hover' for audio warmup")

func _try_load(path_base: String) -> AudioStream:
	var path_ogg = path_base + ".ogg"
	if FileAccess.file_exists(path_ogg):
		return load(path_ogg)
	
	var path_wav = path_base + ".wav"
	if FileAccess.file_exists(path_wav):
		return load(path_wav) # .wav files are imported as AudioStreamWAV
	
	return null

func _setup_dedicated_players() -> void:
	# BGM
	if music_player.get_parent():
		music_player.get_parent().remove_child(music_player)
	music_player.name = "MusicPlayer"
	var music_bus_idx = AudioServer.get_bus_index("Music")
	music_player.bus = "Music" if music_bus_idx != -1 else "Master"
	add_child(music_player)
	
	# Ambient
	if ambient_player.get_parent():
		ambient_player.get_parent().remove_child(ambient_player)
	ambient_player.name = "AmbientPlayer"
	var ambient_bus_idx = AudioServer.get_bus_index("Ambient")
	ambient_player.bus = "Ambient" if ambient_bus_idx != -1 else "Master"
	add_child(ambient_player)

func _setup_pools() -> void:
	var sfx_bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	
	# Clear existing pool if re-initializing
	for p in _sfx_pool:
		if is_instance_valid(p): p.queue_free()
	_sfx_pool.clear()
	
	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = sfx_bus
		add_child(p)
		_sfx_pool.append(p)
		
	# Clear 2D pool
	for p in _sfx_pool_2d:
		if is_instance_valid(p): p.queue_free()
	_sfx_pool_2d.clear()
	
	for i in range(SFX_POOL_2D_SIZE):
		var p = AudioStreamPlayer2D.new()
		p.name = "SFXPlayer2D_%d" % i
		p.bus = sfx_bus
		p.max_distance = 1000.0 # 设置合理的 2D 衰减距离
		add_child(p)
		_sfx_pool_2d.append(p)

# --- API: SFX 播放 ---

func play_ui_sfx(sound_key: String, volume_db: float = 0.0, pitch_rand: float = 0) -> void:
	# UI 音效使用较低音量，或者是固定的
	play_sfx(sound_key, volume_db, pitch_rand)

func play_sfx(sound_key: String, volume_db: float = 0.0, pitch_rand: float = 0) -> void:
	# 强力调试日志：确认每个请求是否被处理
	# print("AudioManager REQ: ", sound_key)
	
	if audio_library.is_empty():
		printerr("CRITICAL: Audio Library is EMPTY!")

	if not audio_library.has(sound_key) or audio_library[sound_key] == null:
		# 统一懒加载逻辑
		var possible_paths = [
			"res://assets/audio/sfx/ui_" + sound_key + ".ogg",
			"res://assets/audio/sfx/" + sound_key + ".ogg",
			"res://assets/audio/ui/" + sound_key + ".ogg",
			"res://assets/audio/sfx/ui_" + sound_key + ".wav"
		]
		for path in possible_paths:
			if ResourceLoader.exists(path):
				audio_library[sound_key] = load(path)
				print("AudioManager: Lazy loaded '%s' from %s" % [sound_key, path])
				break
		
		# If still not found, bail
		if not audio_library.has(sound_key):
			printerr("AudioManager ERROR: Tool missing sound_key '%s'" % sound_key)
			return
	
	var stream = audio_library[sound_key]
	if stream is AudioStream:
		# 重要修复：确保流是循环关闭的，否则它可能像背景音一样“锁住”播放器
		if stream.has_method("set_loop"):
			stream.set_loop(false)
		elif "loop" in stream:
			stream.loop = false
	
	var player = _sfx_pool[_current_pool_idx]
	
	# 获取下一个可用播放器
	var found_player = false
	for i in range(SFX_POOL_SIZE):
		var idx = (_current_pool_idx + i) % SFX_POOL_SIZE
		if not _sfx_pool[idx].playing:
			player = _sfx_pool[idx]
			_current_pool_idx = idx
			found_player = true
			break
	
	# 如果都满了，强制中断并重用当前，确保 UI 反馈永远优先发出声音
	if not found_player:
		player.stop() 
		
	player.stream = stream
	player.volume_db = volume_db
	
	# 如果是法术音效，降低 pitch 模拟“沉重感”
	var base_pitch = 1.0
	var bus_target = "SFX"
	
	if sound_key == "spell_fire":
		base_pitch = 2 # 恢复正常音调，去除过度的“沉闷”
		bus_target = "SFX_LowPass"
	
	player.pitch_scale = base_pitch + randf_range(-pitch_rand, pitch_rand)
	
	# 彻底确保连接到树且 Bus 处于非静音状态
	if not player.is_inside_tree():
		add_child(player)
		
	# 播放前强制重同步总线状态
	# var bus_name = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	var bus_name = bus_target if AudioServer.get_bus_index(bus_target) != -1 else "Master"
	if bus_name == "Master" and AudioServer.get_bus_index("SFX") != -1:
		bus_name = "SFX" # Fallback to SFX if custom bus missing but SFX exists
		
	player.bus = bus_name
	
	player.play()
	
	# 特殊需求：法术出膛音只播放瞬间，截断尾音
	if sound_key == "spell_fire":
		# 0.1秒太短了，声音还没展开就断了，改为 0.18秒
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(player.stop)
	
	print("AudioManager SFX: '%s' | Player: %s | Bus: %s | Vol: %s" % [sound_key, player.name, player.bus, player.volume_db])
	
	_current_pool_idx = (_current_pool_idx + 1) % SFX_POOL_SIZE

func play_sfx_2d(sound_key: String, global_pos: Vector2, volume_db: float = 0.0, pitch_rand: float = 0.1) -> void:
	if not audio_library.has(sound_key) or audio_library[sound_key] == null:
		return
		
	# print("AudioManager: Playing SFX 2D '%s' at %s" % [sound_key, global_pos])
	var player = _sfx_pool_2d[_current_pool_2d_idx]
	player.global_position = global_pos
	player.stream = audio_library[sound_key]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_rand, pitch_rand)
	player.play()
	
	_current_pool_2d_idx = (_current_pool_2d_idx + 1) % SFX_POOL_2D_SIZE

# --- API: BGM/Ambient 切换 ---

func play_music(stream: AudioStream, fade_time: float = 2.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return
		
	if fade_time > 0 and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_time).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func(): _start_music(stream, fade_time))
	else:
		_start_music(stream, fade_time)

func _start_music(stream: AudioStream, fade_time: float) -> void:
	music_player.stream = stream
	music_player.volume_db = -80
	music_player.play()
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", 0, fade_time).set_trans(Tween.TRANS_SINE)

func play_ambient(sound_key: String, fade_time: float = 2.0) -> void:
	# Ensure the ambient player is in the tree and active
	if not ambient_player.is_inside_tree():
		add_child(ambient_player)
	
	if not audio_library.has(sound_key) or audio_library[sound_key] == null:
		# 尝试懒加载 fallback
		var direct_path = "res://assets/audio/ambient/" + sound_key + ".ogg"
		if ResourceLoader.exists(direct_path):
			audio_library[sound_key] = load(direct_path)
		else:
			return
	
	var stream = audio_library[sound_key]
	
	# 重要：环境音通常需要循环
	if stream is AudioStream:
		if stream.has_method("set_loop"):
			stream.set_loop(true)
		elif "loop" in stream:
			stream.loop = true
			
	if ambient_player.stream == stream and ambient_player.playing:
		return
		
	# 环境音播放
	ambient_player.stream = stream
	ambient_player.volume_db = 0 # 确保音量不是静音
	ambient_player.play()
	print("AudioManager DEBUG: Playing Ambient '%s' (Bus: %s)" % [sound_key, ambient_player.bus])
	
	# 特殊修复：如果 SFX 不响，强制一次总线刷新
	AudioServer.set_bus_send(AudioServer.get_bus_index("SFX"), "Master")

func stop_ambient(fade_time: float = 2.0) -> void:
	if ambient_player.playing:
		var tween = create_tween()
		tween.tween_property(ambient_player, "volume_db", -80, fade_time)
		tween.tween_callback(ambient_player.stop)

# --- API: 音量控制 ---

func set_bus_volume(bus_name: String, value: float) -> void:
	# value 为 0.0 到 1.0
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		var db = linear_to_db(clamp(value, 0.01, 1.0))
		AudioServer.set_bus_volume_db(bus_idx, db)
		AudioServer.set_bus_mute(bus_idx, value < 0.01)

func get_bus_volume(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 1.0
