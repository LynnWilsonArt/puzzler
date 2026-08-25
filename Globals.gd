extends Node

# Global variables accessible from any script
# "res://Globals.gd"
var debug: bool = true
var collums = 4
var rows = 4

# This node handles background music globally across all scenes
var music_player: AudioStreamPlayer

# Automatically monitors changes to sound_mode
var sound_mode: bool = false:
	set(value):
		sound_mode = value 
		_update_music_status()

func _ready() -> void:
	# 1. Programmatically create the player so it exists everywhere
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	# INITIALIZE TO 0 dB: Set the player volume directly
	music_player.volume_db = 0.0
	
	# 2. Load your default background music track
	var music_track = load("res://assets/sound/alex-morgan-piano.mp3")
	music_player.stream = music_track
	music_player.bus = "Master"
	
	
	# 3. For Web exports, we check if the browser allows audio yet.
	# If on Web, we only start the track if a user interaction has already occurred.
	if sound_mode:
		if OS.has_feature("web"):
			# On web, try to play. If blocked by the browser, Godot will auto-resume 
			# the music stream the exact millisecond the user clicks anywhere in the game.
			music_player.play()
		else:
			# Desktop behavior start playing
			music_player.play()
		

	_update_music_status()

func _update_music_status() -> void:
	if debug:
		print("Globals -> _update_music_status()")
		
	if not is_instance_valid(music_player):
		return
		
	if not sound_mode:
		if music_player.playing:
			music_player.stop()
	else:
		if not music_player.playing and music_player.stream != null:
			music_player.play()
			
