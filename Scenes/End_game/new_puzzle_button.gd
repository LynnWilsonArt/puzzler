extends Button  
# res://Scenes/End_game/new_puzzle_button.gd


func _on_pressed() -> void:
	
	print("End_game -> new_puzzle_button.gd  -> _on_pressed()")
	
	if OS.has_feature("web"):  
		print("End_game -> WEB -> new_puzzle_button.gd  -> deleting puzzle from Puzzle -> PopupMenu for web!")
		# Delete current puzzle and start a new game
		Globals.g_delete_puzzle()
		print("End_game -> WEB -> new_puzzle_button.gd  -> Saved Puzzle deleted!")
		
		# reloading game  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href = Globals.game_url
		  
	else:  
		print("End_game -> new_puzzle_button.gd -> ERROR! - could not delete puzzle file -> PopupMenu for android!")
	
	
	# Delete current puzzle and start a new game
	Globals.g_delete_puzzle()
	print("End_game -> new_puzzle_button.gd -> Puzzle deleted! -> APP ->from Puzzle -> PopupMenu")
	Globals.switch_scene("res://Scenes/Main/main.tscn")
