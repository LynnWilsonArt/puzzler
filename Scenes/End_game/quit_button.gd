# res://Scenes/End_game/quit_button.gd
extends Button

func _on_pressed()-> void:
	# Handle web OS
	if OS.has_feature("web"): 
		print("End_game -> quit_button.gd -> _on_pressed() -> Web ->Delete saved Game")
		# Delete the saved game 
		Globals._g_delete_puzzle()
		
		# Attempt to close the browser window/tab  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href =  Globals.web_home_page
		
	else: 
		# Handle Android OS
		print("End_game -> quit_button.gd -> _on_pressed() -> Android -> Delete saved Game")
		# Delete the saved game 
		Globals._g_delete_puzzle() 		
		if OS.has_feature("android"):
			BackButtonHandler._move_app_to_background()
		else:
			# Standard behavior for Android, Windows, macOS, etc.
			Globals._g_delete_puzzle()
			get_tree().quit()
		
