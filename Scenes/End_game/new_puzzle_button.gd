# res://Scenes/End_game/new_puzzle_button.gd
extends Button  

func _on_pressed() -> void:
	
	print("End_game -> new_puzzle_button.gd  -> _on_pressed()")
	
	if OS.has_feature("web"):  
		print("Puzzle -> handle_popup_menu_selections.gd -> New Game -> game deleting puzzle from Puzzle -> PopupMenu for web!")
		Globals._g_delete_puzzle()
		print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle deleted! -> from Puzzle -> PopupMenu")
		# need to swithch scenes not restart app
		var win = JavaScriptBridge.get_interface("window")
		if win:
			Globals._stop_autosave_timer()
			get_tree().change_scene_to_file("res://Scenes/Main/main.tscn")
	else:  
		Globals._stop_autosave_timer()
		print("Puzzle -> handle_popup_menu_selections.gd -> ERROR! - could not delete puzzle file -> PopupMenu for android!")
		Globals._g_delete_puzzle()
		print("Puzzle -> handle_popup_menu_selections.gd -> Puzzle deleted! -> from Puzzle -> PopupMenu")
		Globals._switch_scene("res://Scenes/Main/main.tscn")
