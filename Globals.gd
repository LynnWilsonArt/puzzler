extends Node

# Global variables accessible from any script
# "res://Globals.gd"
var columns = 4
var rows = 4
var timer_token  : int   = 0
var autosave_timer: Timer
var REMOTE_IMAGE_PATH: String ="https://loremflickr.com/1152/648/stilllife"
const SAVE_PATH := "user://puzzle_state.save"
var  auto_save_time: int = 30     # Autosave puzzle every x seconds
var debug: bool = true
var game_url = "https://puzzler.lynnwilsonart.com/play_puzzler/Puzzler.html"
var web_home_page = "https://puzzler.lynnwilsonart.com"
# Scene manager
var current_scene = null

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

	# Autosave every 2 minutes
	autosave_timer = Timer.new()
	autosave_timer.wait_time = auto_save_time   # 1 minutes 60 seconds
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave_timeout)

	
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
	print("Globals -> _update_music_status()")
		
	if not is_instance_valid(music_player):
		return
		
	if not sound_mode:
		if music_player.playing:
			music_player.stop()
	else:
		if not music_player.playing and music_player.stream != null:
			music_player.play()
			
####################################################
# Globak Timmer

func _timer(method: int,seconds: int) -> void:
	print("DEBUG -> Globals -> _timer()")
	timer_token += 1
	var my_token = timer_token
	print("Global timer() started!")
	await get_tree().create_timer(seconds).timeout
	if my_token != timer_token:
		return
	_on_timer_timeout(method)

func _on_timer_timeout(method: int) -> void:
	print("DEBUG -> Globals -> _on_timer_timeout()")
		
		# Do something here
		# Methods to run
	match method:
		1:
			print("Globals -> _timer() -> method 1")
			g_save_puzzle( )
				
			
		

		
##################################################
# --------------------------------------------------------------------
# Forwarders — the real save/load logic lives on the game root
# (game_script.gd), since $Puzzle is a child of that node.
# --------------------------------------------------------------------
func g_save_puzzle() -> void:
	var game_root = get_tree().current_scene
	if game_root and game_root.has_method("save_puzzle"):
		game_root.save_puzzle()
		print("Saved puzzle from Globals")
	else:
		push_error("Could not find game_script.gd on current scene to save the puzzle.")


func g_load_puzzle() -> void:
	var game_root = get_parent().current_scene
	if game_root and game_root.has_method("load_puzzle"):
		print("Loaded puzzle from Globals")
		game_root.load_puzzle()
	else:
		push_error("Could not find game_script.gd on parent node to load the puzzle.")
		
		
func _on_autosave_timeout() -> void:
	print("Globals -> autosave puzzle -> saving puzzle")
	g_save_puzzle()




# Method to delete the puzzle file
# Method to delete the puzzle file
func g_delete_puzzle() -> void:
	var error: Error = OK
	
	# FIX: Use FileAccess.file_exists (static) instead of DirAccess.file_exists
	if FileAccess.file_exists(SAVE_PATH):
		error = DirAccess.remove_absolute(SAVE_PATH)
		
		if error == OK:
			print("File deleted successfully!")
		else:
			print("Failed to delete file. Error code: ", error)
	else:
		print("Delete skipped: No save file exists at ", SAVE_PATH)


	
##################################################
# Scene switcher

func switch_scene(game_scene_path):
# Switch directly via the file string path
		var error_code = get_tree().change_scene_to_file(game_scene_path)
		
		# Check if Godot ran into an error while transitioning
		if error_code != OK:
			push_error("Failed to switch scenes! Error code: ", error_code)
