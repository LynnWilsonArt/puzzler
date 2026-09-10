# "res://Globals.gd"
extends Node

# Global variables accessible from any script
var columns = 4
var rows = 4
var timer_token  : int   = 0
var autosave_timer: Timer
var category: String ="stilllife"
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
var sound_effects: bool = true




func _ready() -> void:

	# Autosave every 2 minutes
	autosave_timer = Timer.new()
	autosave_timer.wait_time = auto_save_time   # 1 minutes 60 seconds
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave_timeout)



####################################################
# Global Timmer

func _timer(method: int,seconds: int) -> void:
	print("Globals -> Globals.gd -> _timer()")
	timer_token += 1
	var my_token = timer_token
	print("Globals -> Globals.gd ->timer() started!")
	await get_tree().create_timer(seconds).timeout
	if my_token != timer_token:
		return
	_on_timer_timeout(method)

func _on_timer_timeout(method: int) -> void:
	print("Globals -> Globals.gd -> _on_timer_timeout()")
		
		# Do something here
		# Methods to run
	match method:
		1:
			print("Globals -> Globals.gd ->_timer() -> method 1")
			g_save_puzzle( )
				
			
		

		
# in Globals.gd
func start_autosave() -> void:
	print(" Globals _> Auto save timer started")
	autosave_timer.start()

func stop_autosave_timer() -> void:
	print(" Globals -> Auto save timer stoped")
	autosave_timer.stop()
	
##################################################
# --------------------------------------------------------------------
# Forwarders — the real save/load logic lives on the game root
# (game_script.gd), since $Puzzle is a child of that node.
# --------------------------------------------------------------------
func g_save_puzzle() -> void:
	
	var game_root = get_tree().current_scene

	print(" game_root: ", game_root)
	if game_root and game_root.has_method("save_puzzle"):
		game_root.save_puzzle()
		print("Globals -> Globals.gd ->Saved puzzle from Globals")
	else:
		push_error("Globals -> Could not find game_script.gd on current scene to save the puzzle.")


func g_load_puzzle() -> void:
	var game_root = get_parent().current_scene
	if game_root and game_root.has_method("load_puzzle"):
		print("Globals -> Globals.gd -> Loaded puzzle from Globals")
		game_root.load_puzzle()
	else:
		push_error("Globals -> Globals.gd -> Could not find game_script.gd on parent node to load the puzzle.")
		
		
func _on_autosave_timeout() -> void:
	print("Globals -> Globals.gd -> autosave puzzle -> saving puzzle")
	g_save_puzzle()





# Method to delete the puzzle file
func g_delete_puzzle() -> void:
	var error: Error = OK
	
	# FIX: Use FileAccess.file_exists (static) instead of DirAccess.file_exists
	if FileAccess.file_exists(SAVE_PATH):
		error = DirAccess.remove_absolute(SAVE_PATH)
		
		if error == OK:
			print("Globals -> Globals.gd -> File deleted successfully!")
		else:
			print("Globals -> Globals.gd -> Failed to delete file. Error code: ", error)
	else:
		print("Globals -> Globals.gd -> Delete skipped: No save file exists at ", SAVE_PATH)


	
##################################################
# Scene switcher

func switch_scene(game_scene_path):
# Switch directly via the file string path
		var error_code = get_tree().change_scene_to_file(game_scene_path)
		
		# Check if Godot ran into an error while transitioning
		if error_code != OK:
			push_error("Globals -> Globals.gd -> Failed to switch scenes! Error code: ", error_code)
