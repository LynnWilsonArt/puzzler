# res://Scenes/Puzzle/handle_popup_menu_selections.gd
extends PopupMenu

@onready var puzzle_node: Node = get_node_or_null("../..")
@onready var game_scene: Node = get_node_or_null("../../..")
@onready var main_node: Node = get_node_or_null("/root/Main") 
@onready var settings_ui: Control = $"../../SettingsUI"


func _ready() -> void:
	print("Puzzle -> handle_popup_menu_selections.gd -> ready()")
	
func _on_id_pressed(id: int) -> void:
	print("Puzzle -> handle_popup_menu_selections.gd -> _on_id_pressed()")
	
	match id:
		0: # Toggle the original image for reference
			print("Puzzle -> handle_popup_menu_selections.gd -> Toggle Original Selected: ", id)
			if puzzle_node and puzzle_node.has_method("_on_show_original_image_pressed"):
				puzzle_node.toggle_puzzle = !puzzle_node.toggle_puzzle  # comes in false 
				print(" Menu Selection 0: ",puzzle_node.toggle_puzzle)
				puzzle_node._on_show_original_image_pressed()
			else:
				print("Puzzle -> handle_popup_menu_selections.gd -> Warning: Puzzle node or _on_show_original_image_pressed function not found!")

		1: # Skip to next image
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
		
		2: # Load puzzle
			print("Puzzle -> handle_popup_menu_selections.gd -> Load Puzzle Selected: ", id)
			if puzzle_node and puzzle_node.has_method("_load_puzzle"):
				puzzle_node._load_puzzle()
			else:
				print("Puzzle -> handle_popup_menu_selections.gd -> ERROR! -> Puzzle node or load_puzzle() not found!")
				
		3: # Save puzzle
			print("Puzzle -> handle_popup_menu_selections.gd ->  -> Saving puzzle from Puzzle -> PopupMenu -> Save button")
			if puzzle_node and puzzle_node.has_method("_load_puzzle"):
				puzzle_node._save_puzzle()
			else:
				print("Puzzle -> handle_popup_menu_selections.gd -> ERROR! -> Puzzle node or load_puzzle() not found!")
				
		4: # Goto Main scene
			print("Puzzle -> handle_popup_menu_selections.gd -> New Puzzle Selected: ", id)
			if OS.has_feature("web"):  
				print("Puzzle -> handle_popup_menu_selections.gd -> New Game -> game deleting puzzle from Puzzle -> PopupMenu for web!")
				Globals._g_delete_puzzle()
				print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle deleted! -> from Puzzle -> PopupMenu")
				# need to swithch scenes not restart app
				var win = JavaScriptBridge.get_interface("window")
				if win:
					Globals._stop_autosave_timer()
					get_tree()._change_scene_to_file("res://Scenes/Main/main.tscn")
			else:  
				Globals._stop_autosave_timer()
				print("Puzzle -> handle_popup_menu_selections.gd -> ERROR! - could not delete puzzle file -> PopupMenu for android!")
				Globals._g_delete_puzzle()
				print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle deleted! -> from Puzzle -> PopupMenu")
				Globals._switch_scene("res://Scenes/Main/main.tscn")
				
		5: # Show settings panel
			settings_ui.show()
			 
		6: # Quit Game
			if OS.has_feature("web"):  
				print("Puzzle -> handle_popup_menu_selections.gd -> Quit - web!")
				Globals._stop_autosave_timer()
				Globals._g_save_puzzle()
				var win = JavaScriptBridge.get_interface("window")
				if win:
					win.location.href = Globals.web_home_page
			else:  
				print("Puzzle -> handle_popup_menu_selections.gd -> Quit - android!")
				if OS.has_feature("android"):
					Globals._stop_autosave_timer()
					Globals._g_save_puzzle()					
					BackButtonHandler._move_app_to_background()
				else:
					# Standard behavior for Android, Windows, macOS, etc.
					print("Puzzle -> handle_popup_menu_selections.gd -> Quit - Desktop")
					Globals._stop_autosave_timer()
					Globals._g_save_puzzle()
					get_tree().quit()
			
