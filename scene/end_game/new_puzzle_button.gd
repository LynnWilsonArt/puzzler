extends Button  
# res://scene/end_game/new_puzzle_button.gd


func _on_pressed() -> void:
	
	print("DEBUG -> end_game -> new_puzzle_button.gd  ->_on_pressed()")
	
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
