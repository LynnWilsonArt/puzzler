# res://scene/puzzle/handle_popup_menu_selections.gd
extends PopupMenu

@onready var puzzle_node: Node = get_node_or_null("../..")
@onready var game_scene: Node = get_node_or_null("../../..")

# FIX 1: Added leading slash for an absolute engine root path
@onready var main_node: Node = get_node_or_null("/root/Main") 



func _ready() -> void:
	print("Puzzle -> handle_popup_menu_selections.gd -> ready()")


func _on_id_pressed(id: int) -> void:
	print("Puzzle -> handle_popup_menu_selections.gd -> _on_id_pressed()")

	match id:
		0:
			print("Puzzle -> handle_popup_menu_selections.gd -> Toggle Original Selected: ", id)
			if puzzle_node and puzzle_node.has_method("_on_show_original_image_pressed"):
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
			Globals.sound_mode = !Globals.sound_mode # Cleaned up toggle logic

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
					Globals.stop_autosave()
					get_tree().change_scene_to_file("res://Scenes/Main/main.tscn")
			else:  
				Globals.stop_autosave()
				print("Puzzle -> handle_popup_menu_selections.gd -> ERROR! - could not delete puzzle file -> PopupMenu for android!")
				Globals.g_delete_puzzle()
				print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle deleted! -> from Puzzle -> PopupMenu")
				Globals.switch_scene("res://Scenes/Main/main.tscn")
				
		6:
			if OS.has_feature("web"):  
				print("Puzzle -> handle_popup_menu_selections.gd -> Quit -> game saving puzzle from Puzzle -> PopupMenu for web!")
				Globals.g_save_puzzle()				
				# Log to webserver end session
				ApiData._send_api_data(false)		
				await get_tree().create_timer(Globals.quit_wait_time).timeout
				var win = JavaScriptBridge.get_interface("window")
				if win:
					win.location.href = Globals.web_home_page
			else:  
				print("Puzzle -> handle_popup_menu_selections.gd -> Quit- saving puzzle from Puzzle -> PopupMenu for android!")
				Globals.g_save_puzzle()
				print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle saved! -> from Puzzle -> PopupMenu")
				# Pause for exactly x seconds
				await get_tree().create_timer(Globals.quit_wait_time).timeout
				if OS.has_feature("android"):
					Globals.stop_autosave()
					BackButtonHandler._move_app_to_background()
				else:
					# Standard behavior for Android, Windows, macOS, etc.
					# Pause for exactly 3 seconds for data to be sent
					ApiData._send_api_data(false)
					await get_tree().create_timer(Globals.quit_wait_time).timeout
					get_tree().quit()
			
