# res://helper_scripts/Globals.gd
extends Node
#----------------------------------------------------------------------
# Global variables accessible from any script
#----------------------------------------------------------------------
var columns = 4
var rows = 4
var timer_token  : int   = 0
var autosave_timer: Timer
var category: String ="animals"
const SAVE_PATH := "user://puzzle_state.save"
#var game_url = "https://puzzler.lynnwilsonart.com/play_puzzler/Puzzler.html"
var web_home_page = "https://puzzler.lynnwilsonart.com"
var puzzler_website_url: String = "https://puzzler.lynnwilsonart.com"
var lwa_contact_url: String = "https://lynnwilsonart.com/contact/"
var  auto_save_time: int = 30     # Autosave puzzle every x seconds
# Scene manager
var current_scene = null
var quit_wait_time: float= 1.0
var upload_password: String = "Topp3r@19511969!"

# Storing Array of Dictionaries: [{"station_name": String, "url": String}]
var stations_array: Array[Dictionary] = [
	{"station_name": "Awesome 80s", "url": "https://listen.181fm.com/181-awesome80s_128k.mp3"},
	{"station_name": "The Buzz", "url": "https://listen.181fm.com/181-buzz_128k.mp3"},
	{"station_name": "Kickin' Country", "url": "https://listen.181fm.com/181-kickincountry_128k.mp3"},
	{"station_name": "The Beat", "url": "https://listen.181fm.com/181-beat_128k.mp3"}, 
	{"station_name": "Rock 181", "url": "https://listen.181fm.com/181-rock_128k.mp3"},
	{"station_name": "Power 181 (Top 40)", "url": "https://listen.181fm.com/181-power_128k.mp3"},
	{"station_name": "Blues", "url": "https://listen.181fm.com/181-blues_128k.mp3"},
	{"station_name": "Classical", "url": "https://listen.181fm.com/181-classical_128k.mp3"},
	{"station_name": "Classical Guitar", "url": "https://listen.181fm.com/181-classicalguitar_128k.mp3"},
	{"station_name": "Classical Jazz", "url": "https://listen.181fm.com/181-classicaljazz_128k.mp3"},
]


#---------------------------------------------------------------------
# Ready
#---------------------------------------------------------------------
func _ready() -> void:
	print("Globals.gd -> _ready")

	# Autosave every 2 minutes
	autosave_timer = Timer.new()
	autosave_timer.wait_time = auto_save_time   # 1 minutes 60 seconds
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave_timeout)



#----------------------------------------------------------------------
# Global Timmer
#----------------------------------------------------------------------
func _timer(method: int,seconds: int) -> void:
	print("Globals.gd -> _timer()")
	timer_token += 1
	var my_token = timer_token
	print("Globals.gd ->timer() started!")
	await get_tree().create_timer(seconds).timeout
	if my_token != timer_token:
		return
	_on_timer_timeout(method)

func _on_timer_timeout(method: int) -> void:
	print("Globals.gd -> _on_timer_timeout()")
		
		# Do something here
		# Methods to run
	match method:
		1:
			print("Globals.gd ->_timer() -> method 1")
			_g_save_puzzle()

#----------------------------------------------------------------------
# Autosave timer
#----------------------------------------------------------------------
func _start_autosave_timer() -> void:
	print(" Globals.gd -> _start_autosave_timer()")
	autosave_timer.start()

func _stop_autosave_timer() -> void:
	print(" Globals.gd -> _stop_autosave_timer()")
	autosave_timer.stop()
	
# --------------------------------------------------------------------
# Forwarders — the real save/load logic lives on the game root
# (game_script.gd), since $Puzzle is a child of that node.
# --------------------------------------------------------------------
func _g_save_puzzle() -> void:
	print("Globals.gd ->  _g_save_puzzle")
	
	var game_root = get_tree().current_scene

	print(" game_root: ", game_root)
	if game_root and game_root.has_method("_save_puzzle"):
		game_root._save_puzzle()
		print("Globals.gd ->Saved puzzle from Globals")
	else:
		push_error("Globals.gd -> Could not find game_script.gd on current scene to save the puzzle.")

#-----------------------------------------------------------------
# NOT USED - Butt keeping it.
#------------------------------------------------------------------
func _g_load_puzzle() -> void:
	print("Globals.gd -> _g_load_puzzle()")
	var game_root = get_parent().current_scene
	if game_root and game_root.has_method("_load_puzzle"):
		print("Globals.gd -> Loaded puzzle from Globals")
		game_root._load_puzzle()
	else:
		push_error("Globals.gd -> Could not find game_script.gd on parent node to load the puzzle.")
		
		
func _on_autosave_timeout() -> void:
	print("Globals.gd -> _on_autosave_timeout() -> saving puzzle")
	_g_save_puzzle()

#--------------------------------------------------------------------------
# Method to delete the puzzle file
#--------------------------------------------------------------------------
func _g_delete_puzzle() -> void:
	print("Globals.gd -> _g_delete_puzzle()")
	var error: Error = OK
	
	# FIX: Use FileAccess.file_exists (static) instead of DirAccess.file_exists
	if FileAccess.file_exists(SAVE_PATH):
		error = DirAccess.remove_absolute(SAVE_PATH)
		
		if error == OK:
			print("Globals.gd -> File deleted successfully!")
		else:
			print("Globals.gd -> Failed to delete file. Error code: ", error)
	else:
		print("Globals.gd -> Delete skipped: No save file exists at ", SAVE_PATH)


	
#----------------------------------------------------------------------------
# Scene switcher
#----------------------------------------------------------------------------
func _switch_scene(game_scene_path):
	print("Globals.gd -> _switch_scene(scene_path)")
	# Switch directly via the file string path
	var error_code = get_tree().change_scene_to_file(game_scene_path)
		
	# Check if Godot ran into an error while transitioning
	if error_code != OK:
		push_error("Globals.gd -> Failed to switch scenes! Error code: ", error_code)
