# res://scene/puzzle/handle_popup_menu_selections.gd
extends PopupMenu

@onready var puzzle_node: Node = get_node_or_null("../..")
@onready var game_scene: Node = get_node_or_null("../../..")

func _ready() -> void:

	print(" This the original script handle_popup_menu_selection")


func _on_id_pressed(id: int) -> void:
	print("handle_popup_menu_selections -> _on_id_pressed()")

	match id:
		0:
			print("Toggle Original Selected: ", id)
			if puzzle_node and puzzle_node.has_method("_on_show_original_image_pressed"):
				puzzle_node._on_show_original_image_pressed()
			else:
				print("Warning: Puzzle node or _on_show_original_image_pressed function not found!")

		1:
			print("Skip Selected: ", id)
			if game_scene and game_scene.has_method("_on_get_puzzle"):
				print(" Getting new image")
				print("Level: ",Globals.columns," , ",Globals.rows)
				game_scene.num_columns = Globals.columns
				game_scene.num_rows = Globals.rows
				game_scene._on_get_puzzle()
				if puzzle_node and puzzle_node.has_method("_start_puzzle_timer"):
					puzzle_node._start_puzzle_timer()
				print("Finished skip")
			else:
				print("Warning: game_scene node or _on_get_puzzle() function not found!")
				
		2:
			print("DEBUG -> Toggle Sound from Puzzle -> PupupMenu")
			if Globals.sound_mode:
				Globals.sound_mode = false   # Turn sound off
			else:
				Globals.sound_mode = true   # Turn sound on
			

		3:
			print("Load Puzzle Selected: ", id)
			# Load Puzzle
			if puzzle_node and puzzle_node.has_method("load_puzzle"):
				puzzle_node.load_puzzle()
			else:
				print("ERROR! -> Puzzle node or load_puzzle() not found!")
				
		4:
			
			print("DEBUG -> Saving puzzle from Puzzle -> PopupMenu -> Save button")
			Globals.g_save_puzzle()
				
		5:
			print("New Game Selected: ", id)
			if OS.has_feature("web"):  
				print("DEBUG -> New Game -> game deleting puzzle from Puzzle -> PopupMenu for web!")
				# Delete current puzzle and start a new game
				Globals.g_delete_puzzle()
				print("Puzzle deleted! -> from Puzzle -> PopupMenu")
				
				# reloading game  
				var win = JavaScriptBridge.get_interface("window")
				win.location.href = Globals.game_url
				  
			else:  
				print("DEBUG ->ERROR! - could not delete puzzle file -> PopupMenu for android!")
			
			
			# Delete current puzzle and start a new game
			Globals.g_delete_puzzle()
			print("Puzzle deleted! -> from Puzzle -> PopupMenu")
			Globals.switch_scene("res://scene/main/main.tscn")
				
		6:
			if OS.has_feature("web"):  
				print("DEBUG -> Quit -> game saving puzzle from Puzzle -> PopupMenu for web!")
				Globals.g_save_puzzle()
			
				# Attempt to close the browser window/tab  
				var win = JavaScriptBridge.get_interface("window")
				win.location.href = Globals.web_home_page
			  
			else:  
				print("DEBUG ->Quit- saving puzzle from Puzzle -> PopupMenu for android!")
				Globals.g_save_puzzle()
					
				print("Puzzle saved! -> from Puzzle -> PopupMenu")
				get_tree().quit()
				
					
		
