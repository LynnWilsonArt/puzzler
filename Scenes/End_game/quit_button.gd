extends Button

func _on_pressed()-> void:
	if OS.has_feature("web"): 
		print("End_game -> quit_button.gd -> _on_pressed() -> Web ->Delete saved Game")
		# Delete the saved game 
		Globals.g_delete_puzzle()
		# Log to webserver end session
		ApiData._send_api_data(false)
		
		await get_tree().create_timer(Globals.quit_wait_time).timeout
		# Attempt to close the browser window/tab  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href =  Globals.web_home_page
		
	else: 
		print("End_game -> quit_button.gd -> _on_pressed() -> Android -> Delete saved Game")
		# Delete the saved game 
		Globals.g_delete_puzzle() 
		# Log to webserver end session
		ApiData._send_api_data(false)
		
		# Standard behavior for Android, Windows, macOS, etc.
		# Pause for exactly 3 seconds
		await get_tree().create_timer(Globals.quit_wait_time).timeout
		get_tree().quit()
		
