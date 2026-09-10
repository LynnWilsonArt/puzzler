# res://Scenes/Puzzle/handle_popup_menu_selections.gd
extends PopupMenu

@onready var puzzle_node: Node = get_node_or_null("../..")
@onready var game_scene: Node = get_node_or_null("../../..")
@onready var main_node: Node = get_node_or_null("/root/Main") 
var music_player = AudioStreamPlayer.new()

func _ready() -> void:
	print("Puzzle -> handle_popup_menu_selections.gd -> ready()")
	_create_audio_streamer()
	


func _on_id_pressed(id: int) -> void:
	print("Puzzle -> handle_popup_menu_selections.gd -> _on_id_pressed()")
	
	match id:
		0:
			print("Puzzle -> handle_popup_menu_selections.gd -> Toggle Original Selected: ", id)
			if puzzle_node and puzzle_node.has_method("_on_show_original_image_pressed"):
				puzzle_node.toggle_puzzle = !puzzle_node.toggle_puzzle  # comes in false 
				print(" Menu Selection 0: ",puzzle_node.toggle_puzzle)
				puzzle_node._on_show_original_image_pressed()
			else:
				print("Puzzle -> handle_popup_menu_selections.gd -> Warning: Puzzle node or _on_show_original_image_pressed function not found!")

		1:
			print("Puzzle -> handle_popup_menu_selections.gd -> Skip Selected: ", id)
			if game_scene and game_scene.has_method("_on_get_puzzle"):
				print("Puzzle -> handle_popup_menu_selections.gd -> Getting new image")
				print("Puzzle -> handle_popup_menu_selections.gd -> Level: ", Globals.columns, " , ", Globals.rows)
				game_scene.num_columns = Globals.columns
				game_scene.num_rows = Globals.rows
				game_scene._on_get_puzzle()
				if puzzle_node and puzzle_node.has_method("_start_puzzle_timer"):
					puzzle_node._start_puzzle_timer()
				print("Puzzle -> handle_popup_menu_selections.gd -> Finished skip")
			else:
				print("Puzzle -> handle_popup_menu_selections.gd -> Warning: game_scene node or _on_get_puzzle() function not found!")
				
		2:
			print("Puzzle -> handle_popup_menu_selections.gd -> Toggle Sound from Puzzle -> PupupMenu")
			_toggle_sound()
			

		3:
			print("Puzzle -> handle_popup_menu_selections.gd -> Load Puzzle Selected: ", id)
			if puzzle_node and puzzle_node.has_method("load_puzzle"):
				puzzle_node.load_puzzle()
			else:
				print("Puzzle -> handle_popup_menu_selections.gd -> ERROR! -> Puzzle node or load_puzzle() not found!")
				
		4:
			print("Puzzle -> handle_popup_menu_selections.gd ->  -> Saving puzzle from Puzzle -> PopupMenu -> Save button")
			Globals.g_save_puzzle()
				
		5:
			print("Puzzle -> handle_popup_menu_selections.gd -> New Puzzle Selected: ", id)
			if OS.has_feature("web"):  
				print("Puzzle -> handle_popup_menu_selections.gd -> New Game -> game deleting puzzle from Puzzle -> PopupMenu for web!")
				Globals.g_delete_puzzle()
				print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle deleted! -> from Puzzle -> PopupMenu")
				# need to swithch scenes not restart app
				var win = JavaScriptBridge.get_interface("window")
				if win:
					Globals.stop_autosave_timer()
					get_tree().change_scene_to_file("res://Scenes/Main/main.tscn")
			else:  
				Globals.stop_autosave_timer()
				print("Puzzle -> handle_popup_menu_selections.gd -> ERROR! - could not delete puzzle file -> PopupMenu for android!")
				Globals.g_delete_puzzle()
				print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle deleted! -> from Puzzle -> PopupMenu")
				Globals.switch_scene("res://Scenes/Main/main.tscn")
				
		6:
			if OS.has_feature("web"):  
				print("Puzzle -> handle_popup_menu_selections.gd -> Quit - web!")
				Globals.stop_autosave_timer()
				Globals.g_save_puzzle()
				var win = JavaScriptBridge.get_interface("window")
				if win:
					win.location.href = Globals.web_home_page
			else:  
				print("Puzzle -> handle_popup_menu_selections.gd -> Quit - android!")
				if OS.has_feature("android"):
					Globals.stop_autosave_timer()
					Globals.g_save_puzzle()					
					BackButtonHandler._move_app_to_background()
				else:
					# Standard behavior for Android, Windows, macOS, etc.
					print("Puzzle -> handle_popup_menu_selections.gd -> Quit - Desktop")
					Globals.stop_autosave_timer()
					Globals.g_save_puzzle()
					get_tree().quit()
			


# Called when the node enters the scene tree for the first time.
func _create_audio_streamer() -> void:
	var track_path = load('res://assets/sound/alex-morgan-piano.mp3')
	music_player.stream = track_path
	add_child(music_player)
	print("Puzzle - PopupMenu - Created music_player: ")


func _toggle_sound() -> void:
	if music_player.playing:
		
		music_player.stop()
		print("Music_player Stop:")
		
	else:
		music_player.play()
		print("Music_player Play:")
