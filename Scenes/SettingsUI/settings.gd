# res://scripts/Settings.gd
extends Node

signal settings_changed

# --- Public properties ----------------------------------------------
var audio_volume: float = 0.5               # 0.0 – 1.0
var effects_volume: float = 1.0             # 0.0 – 1.0
var music_player = AudioStreamPlayer.new()
var effects_player = AudioStreamPlayer.new()
var bg_audio_mode: bool = true
var sound_effects_mode: bool = true


# --- Constants ------------------------------------------------------
const CONFIG_FILE := "user://settings.json"

# -------------------------------------------------------------------
func _ready() -> void:
	print("Settings-> ready()")
	_load_settings()
	_create_audio_streamer()
	_create_audio_effects_player()
	_apply_settings()
	# temp code
	print("Bus count: ", AudioServer.bus_count)
	for i in AudioServer.bus_count:
		print(i, ": ", AudioServer.get_bus_name(i))
		

func _notification(what: int) -> void:
	# NOTE: NOTIFICATION_APPLICATION_PAUSED only fires when a mobile app is
	# backgrounded — it is never sent on desktop, so relying on it alone
	# means settings never get saved when the window is closed there.
	# NOTIFICATION_WM_CLOSE_REQUEST is the desktop/web equivalent, sent when
	# the OS asks the window to close (e.g. clicking the "X").
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_save_settings()
			get_tree().quit() # default close behavior, since we intercepted it
		NOTIFICATION_APPLICATION_PAUSED:
			_save_settings()

# -------------------------------------------------------------------
func _apply_settings() -> void:
	print("Settings-> Pushes the stored settings into the engine.")
	
	# Audio (bus 0 = Master)
	#AudioServer.set_bus_volume_db(0, linear_to_db(clampf(audio_volume, 0.0, 1.0)))
	# Set bus volumes
	_set_music_volume(audio_volume)
	_set_effects_volume(effects_volume)
	
	# Set sound mode
	print("Apply Settings-> BG music mode: ",bg_audio_mode)
	_set_bg_music_mode(bg_audio_mode)
	_set_effects_audio_mode(sound_effects_mode)
	settings_changed.emit()

# -------------------------------------------------------------------
func _load_settings() -> void:
	print("Settings-> Load settings")
	if not FileAccess.file_exists(CONFIG_FILE):
		_save_settings()
		return

	var file := FileAccess.open(CONFIG_FILE, FileAccess.READ)
	if not file:
		return

	var json_data: Variant = JSON.parse_string(file.get_as_text())
	if json_data is Dictionary:
		# Typed Dictionary read (Godot 4.4+): values still come back as Variant
		# from JSON, so we keep the source dict untyped and cast on use.
		var data: Dictionary = json_data
		audio_volume = float(data.get("audio_volume", audio_volume))
		effects_volume = float(data.get("effects_volume", effects_volume))
		bg_audio_mode = bool(data.get("bg_audio_mode",bg_audio_mode))
		sound_effects_mode = bool(data.get("sound_effects_mode",sound_effects_mode))
		
		
# ------------------------------------------------------------------
	
####################################################
# Music Player
func _create_audio_streamer() -> void:
	print("Settings-> Create Music Player")
	var track_path = load('res://assets/sound/alex-morgan-piano.mp3')
	track_path.loop = true
	music_player.stream = track_path
	music_player.bus = "Music"
	add_child(music_player)
	if music_player.playing:
		music_player.stop()
	print("Settings-> Created music_player: ")
	
####################################################
# Effects Audio Player
func _create_audio_effects_player() -> void:
	
	print("Settings-> Create Audio Effects Player")
	var track_path = load('res://assets/sound/swoosh.mp3')
	effects_player.stream = track_path
	effects_player.bus = "Effects"   # route to its own bus
	add_child(effects_player)
	if effects_player.playing:
		effects_player.stop()
	print("Settings-> Created effects_player: ")
	
# Set Effects Volume
func _set_effects_volume(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Effects")
	print("Effects vars, vol, bus_idx",effects_volume, bus_idx)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(effects_volume))
	
	
func _set_music_volume(value: float) -> void:
	audio_volume = clampf(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Music")
	print("Music vars, vol, bus_idx",effects_volume, bus_idx)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(audio_volume))
	
# -------------------------------------------------------------------
func _save_settings() -> void:
	print("Settings-> Save settings")
	var data: Dictionary[String, Variant] = {
		"audio_volume": audio_volume,
		"effects_volume": effects_volume,
		"bg_audio_mode": bg_audio_mode,
		"sound_effects_mode": sound_effects_mode,
		
	}
	var file := FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		

# Set music mode
func _set_bg_music_mode(mode) -> void:
	bg_audio_mode = mode
	if mode:
		print("Set Mode-> BG Music Play")
		music_player.play()
	else:
		print("Set Mode-> BG Music Stop")
		music_player.stop()
			
# Set sound effects mode (mute toggle only — does NOT trigger playback)
func _set_effects_audio_mode(mode) -> void:
	sound_effects_mode = mode
	print("Effects Mode set to: ", mode)
	# Optionally mute the bus directly instead of stopping the player
	var bus_idx = AudioServer.get_bus_index("Effects")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, not mode)
# Call this from wherever your game triggers an effect (button click, etc.)
func play_effect(stream: AudioStream) -> void:
	if not sound_effects_mode:
		return
	effects_player.stream = stream
	effects_player.play()
