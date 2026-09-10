# res://scripts/Settings.gd
extends Node

signal settings_changed

# --- Public properties ----------------------------------------------
var audio_volume: float = 1.0               # 0.0 – 1.0
var music_player = AudioStreamPlayer.new()
var bg_audio_mode: bool = true
@onready var sound_mode_box: CheckBox = $SettingsPanel/SoundMode


# --- Constants ------------------------------------------------------
const CONFIG_FILE := "user://settings.json"

# -------------------------------------------------------------------
func _ready() -> void:
	print("Settings-> ready()")
	_load_settings()
	_create_audio_streamer()
	_apply_settings()
		

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
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(audio_volume, 0.0, 1.0)))
	# Set sound mode
	print("Apply Settings-> BG music mode: ",bg_audio_mode)
	_set_bg_music_mode()

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
		bg_audio_mode = bool(data.get("bg_audio_mode",bg_audio_mode))
		
		
# ------------------------------------------------------------------
	
####################################################
# Music Player
func _create_audio_streamer() -> void:
	print("Settings-> Create Music Player")
	var track_path = load('res://assets/sound/alex-morgan-piano.mp3')
	music_player.stream = track_path
	add_child(music_player)
	if music_player.playing:
		music_player.stop()
	print("Settings-> Created music_player: ")
	
# -------------------------------------------------------------------
func _save_settings() -> void:
	print("Settings-> Save settings")
	var data: Dictionary[String, Variant] = {
		"audio_volume": audio_volume,
		"bg_audio_mode": bg_audio_mode,
		
	}
	var file := FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		
func _set_bg_music_mode() -> void:
	if !music_player.playing:
		if bg_audio_mode:
			print("Set Mode-> BG Music Play")
			music_player.play()
	else:
		if music_player.playing:
			print("Set Mode-> BG Music Stop")
			music_player.stop()
			
