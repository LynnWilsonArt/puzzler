extends Button


func _on_pressed()-> void:
	if OS.has_feature("web"): 
		print("End_game -> quit_button.gd -> _on_pressed() -> Web ->Delete saved Game")
		# Delete the saved game 
		Globals.g_delete_puzzle()
		# Attempt to close the browser window/tab  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href =  Globals.web_home_page
	else: 
		print("End_game -> quit_button.gd -> _on_pressed() -> Android -> Delete saved Game")
		# Delete the saved game 
		Globals.g_delete_puzzle() 
		# Standard behavior for Android, Windows, macOS, etc. 
		get_tree().quit()
