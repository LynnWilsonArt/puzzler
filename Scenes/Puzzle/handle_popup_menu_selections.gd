# res://scene/puzzle/handle_popup_menu_selections.gd
extends PopupMenu

@onready var puzzle_node: Node = get_node_or_null("../..")
@onready var game_scene: Node = get_node_or_null("../../..")

func _ready() -> void:
	# DEBUG
	print("Puzzle -> handle_popup_menu_selections.gd -> ready()")


func _on_id_pressed(id: int) -> void:
	# DEBUG
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
				print("Puzzle -> handle_popup_menu_selections.gd -> Level: ",Globals.columns," , ",Globals.rows)
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
			if Globals.sound_mode:
				Globals.sound_mode = false   # Turn sound off
			else:
				Globals.sound_mode = true   # Turn sound on
			

		3:
			print("Puzzle -> handle_popup_menu_selections.gd -> Load Puzzle Selected: ", id)
			# Load Puzzle
			if puzzle_node and puzzle_node.has_method("load_puzzle"):
				puzzle_node.load_puzzle()
			else:
				print("Puzzle -> handle_popup_menu_selections.gd -> ERROR! -> Puzzle node or load_puzzle() not found!")
				
		4:
			
			print("Puzzle -> handle_popup_menu_selections.gd ->  -> Saving puzzle from Puzzle -> PopupMenu -> Save button")
			Globals.g_save_puzzle()
				
		5:
			print("Puzzle -> handle_popup_menu_selections.gd -> New Game Selected: ", id)
			if OS.has_feature("web"):  
				print("Puzzle -> handle_popup_menu_selections.gd -> New Game -> game deleting puzzle from Puzzle -> PopupMenu for web!")
				# Delete current puzzle and start a new game
				Globals.g_delete_puzzle()
				print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle deleted! -> from Puzzle -> PopupMenu")
				
				# reloading game  
				var win = JavaScriptBridge.get_interface("window")
				win.location.href = Globals.game_url
				  
			else:  
				print("Puzzle -> handle_popup_menu_selections.gd -> ERROR! - could not delete puzzle file -> PopupMenu for android!")
			
			
			# Delete current puzzle and start a new game
			Globals.g_delete_puzzle()
			print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle deleted! -> from Puzzle -> PopupMenu")
			Globals.switch_scene("res://scene/main/main.tscn")
				
		6:
			if OS.has_feature("web"):  
				print("Puzzle -> handle_popup_menu_selections.gd -> Quit -> game saving puzzle from Puzzle -> PopupMenu for web!")
				Globals.g_save_puzzle()
			
				# Attempt to close the browser window/tab  
				var win = JavaScriptBridge.get_interface("window")
				win.location.href = Globals.web_home_page
			  
			else:  
				print("Puzzle -> handle_popup_menu_selections.gd -> Quit- saving puzzle from Puzzle -> PopupMenu for android!")
				Globals.g_save_puzzle()
					
				print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle saved! -> from Puzzle -> PopupMenu")
				get_tree().quit()
				
					
		
