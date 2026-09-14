# res://Scenes/SettingsUI/settings.gd
extends Node

#--------------------------------------------------------------------
# Signals
#--------------------------------------------------------------------
signal settings_changed

# ------------------------------------------------------------------
# Public properties
#--------------------------------------------------------------------
var music_volume: float = 0.5               # 0.0 – 1.0
var effects_volume: float = 1.0             # 0.0 – 1.0
var music_player = AudioStreamPlayer.new()
var effects_player = AudioStreamPlayer.new()
var sound_effects_mode: bool = true
var radio_mode: bool = false # Playing / Not Playing
var station_url: String = ""
# Add near your other public properties
var custom_stations: Array[String] = []

# ------------------------------------------------------------------
# Constants
#--------------------------------------------------------------------
const CONFIG_FILE := "user://settings.json"


# -------------------------------------------------------------------
# Ready
#--------------------------------------------------------------------
func _ready() -> void:
	print("Settings.gd -> _ready()")
	_load_settings()
	_create_radio_palyer()
	_create_audio_effects_player()
	_apply_settings()
	print("Settings.gd -> End of _ready()")
	
#--------------------------------------------------------------------
# Detect notifications
#--------------------------------------------------------------------
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
# Apply settings
#--------------------------------------------------------------------
func _apply_settings() -> void:
	print("Settings.gd -> _apply_settings()")
	print("Settings.gd -> _apply_settings() -> Push the stored settings into the engine.")
	
	# Audio (bus 0 = Master)
	#AudioServer.set_bus_volume_db(0, linear_to_db(clampf(music_volume, 0.0, 1.0)))
	# Set bus volumes
	_set_music_volume(music_volume)
	_set_effects_volume(effects_volume)
	_set_effects_audio_mode(sound_effects_mode)
	# Wait for radio to initilize befor applying settings
	await get_tree().create_timer(3.0, true, true).timeout
	_set_bg_music_mode(radio_mode)
	_save_settings() # save the just applied settings.
	settings_changed.emit()
	print("Settings.gd -> _apply_settings() -> SUCCESS! Saved settings applied!")
	

# -------------------------------------------------------------------
# Load settings
#--------------------------------------------------------------------
func _load_settings() -> void:
	print("Settings.gd -> _load_settings()")
	if not FileAccess.file_exists(CONFIG_FILE):
		print("Settings.gd -> Load_settings -> Config file does not exist - Creating one!")
		_save_settings() # Create the file
		return

	var file := FileAccess.open(CONFIG_FILE, FileAccess.READ)
	if not file:
		push_error("Settings.gd ->  Load_settings -> Config file does not exist!")
		return

	var json_data: Variant = JSON.parse_string(file.get_as_text())
	if json_data is Dictionary:
		# Typed Dictionary read (Godot 4.4+): values still come back as Variant
		# from JSON, so we keep the source dict untyped and cast on use.
		var data: Dictionary = json_data
		music_volume = float(data.get("music_volume", music_volume))
		effects_volume = float(data.get("effects_volume", effects_volume))
		Radio.station_url = String(data.get("station_url",station_url))
		sound_effects_mode = bool(data.get("sound_effects_mode",sound_effects_mode))
		radio_mode = bool(data.get("radio_mode",radio_mode)) # sets radio the playing or not playing

		var raw_stations: Array = data.get("custom_stations", [])
		custom_stations.clear()
		for s in raw_stations:
			custom_stations.append(String(s))

		print("Settings.gd -> _load_settings() -> SUCCESS! Loaded saved settings.")
	else:
		push_error("Settings.gd -> ERROR! Unable to load settings")
#------------------------------------------------------------------
# Music Player
#--------------------------------------------------------------------
func _create_radio_palyer() -> void:
	print("Settings.gd -> _create_radio_player()")
	music_player.bus = "Music"
	add_child(music_player)
	print("Settings.gd -> _create_radio_player() -> SUCCESS! Created radio_player! ")
	
#----------------------------------------------------------------------
# Effects Audio Player
#--------------------------------------------------------------------
func _create_audio_effects_player() -> void:
	print("Settings.gd -> _create_audio_effects_player()")
	var track_path = load('res://assets/sound/swoosh.mp3')
	print("Settings.gd -> _create_audio_effects_player() -> Loaded track swoosh.mp3")
	effects_player.stream = track_path
	print("Settings.gd -> _create_audio_effects_player() -> Assigned to Effects bus")
	effects_player.bus = "Effects"   # route to its own bus
	add_child(effects_player)
	if effects_player.playing:
		effects_player.stop()
	print("Settings.gd -> _create_audio_effects_player() -> SUCCESS! Created effects_player!")
	
#---------------------------------------------------------------------	
# Set Effects Volume
#--------------------------------------------------------------------
func _set_effects_volume(value: float) -> void:
	print("Settings.gd -> _set_effects_volume(value)")
	effects_volume = clampf(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Effects")
	print("Settings.gd -> _set_effects_volume() -> Effects vars, vol, bus_idx",effects_volume, bus_idx)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(effects_volume))
	print("Settings.gd -> _set_effects_volume -> Done!")
	
#------------------------------------------------------------------------
# Set music volume
#--------------------------------------------------------------------
func _set_music_volume(value: float) -> void:
	print("Settings.gd -> _set_music_volume(value)")
	music_volume = clampf(value, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Music")
	print("Settings.gd -> _set_music_volume() -> Music vars, vol, bus_idx",effects_volume, bus_idx)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(music_volume))
	print("Settings.gd -> _set_music_volume() -> Done!")
	
# -------------------------------------------------------------------
# Save settings
#--------------------------------------------------------------------
func _save_settings() -> void:
	print("Settings.gd -> _save_settings()")
	var data: Dictionary[String, Variant] = {
		"music_volume": music_volume, # radio volume
		"effects_volume": effects_volume,
		"station_url": Radio.station_url,
		"sound_effects_mode": sound_effects_mode,
		"radio_mode": radio_mode,
		"custom_stations": custom_stations
	}
	var file := FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		
#---------------------------------------------------------------------
# Set music mode
#--------------------------------------------------------------------
func _set_bg_music_mode(mode) -> void:
	print("Settings.gd -> _set_bg_music_mode(mode): ", mode)
	# Sets music on or off
	radio_mode = mode
	Radio.radio_player.stream_paused = !mode
#--------------------------------------------------------------------
# Set sound effects mode (mute toggle only — does NOT trigger playback)
#--------------------------------------------------------------------
func _set_effects_audio_mode(mode) -> void:
	print("Settings.gd -> _set_effects_audio_mode(mode): ", mode)
	sound_effects_mode = mode
	print("Settings.gd -> _set_effects_audio_mode(mode) -> Effects Mode set to: ", mode)
	print("Settings.gd -> _set_effects_audio_mode(mode) -> Assigned to Effects bus.")
	var bus_idx = AudioServer.get_bus_index("Effects")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, not mode)
		
	print("Settings.gd -> _set_effects_audio_mode(mode) -> SUCCESS! Set effects audio mode: ",mode)
		
#-----------------------------------------------------------------------
# Call this from wherever your game triggers an effect (button click, etc.)
#------------------------------------------------------------------------
func _play_effect(stream: AudioStream) -> void:
	print("Settings.gd -> _play_effect(stream) ")
	print("Settings.gd -> _play_effect() -> Playing sound effect!")
	if not sound_effects_mode:
		print("Settings.gd -> _play_effect() -> Could not play effect - sound_effects_mode = false")
		return
	# Play the effect
	effects_player.stream = stream
	effects_player.play()
	
func _add_custom_station(url: String) -> void:
	print("Settings.gd -> _add_custom_station(): ", url)
	if url.is_empty():
		return
	if custom_stations.has(url):
		print("Settings.gd -> _add_custom_station() -> URL already saved, skipping.")
		return
	custom_stations.append(url)
	_save_settings()
