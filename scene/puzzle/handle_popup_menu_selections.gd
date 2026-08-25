# res://scene/puzzle/handle_popup_menu_selections.gd
extends PopupMenu

@onready var puzzle_node: Node = get_node_or_null("../..")
@onready var game_scene: Node = get_node_or_null("../..")

func _ready() -> void:
	id_pressed.connect(_on_id_pressed)
	print(" This the original script handle_popup_menu_selection")

func _on_id_pressed(id: int) -> void:
	if Globals.debug:
		print("DEBUG -> handle_popup_menu_selections -> _on_id_pressed()")

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
				game_scene._on_get_puzzle()
				if puzzle_node and puzzle_node.has_method("_start_puzzle_timer"):
					puzzle_node._start_puzzle_timer()
				print("Finished skip")
			else:
				print("Warning: game_scene node or _on_get_puzzle() function not found!")
				
		2:
			print("Toggle Sound")
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
				print("Puzzle node or load_puzzle() not found!")
				
		4:
			print("Quit Selected: ", id)
			if OS.has_feature("web"):  
				print("Quiting game web!")
				if puzzle_node and puzzle_node.has_method("save_puzzle"):
					print("Puzzle saved!")
					puzzle_node.save_puzzle()
			
				# Attempt to close the browser window/tab  
				JavaScriptBridge.eval("window.location.href = 'https://puzzler.lynnwilsonart.com/play_puzzler/Puzzler.html'")  
			else:  
				print("Quiting game android!")
				if puzzle_node and puzzle_node.has_method("save_puzzle"):
					puzzle_node.save_puzzle()
					print("Puzzle saved!")
					get_tree().quit()
