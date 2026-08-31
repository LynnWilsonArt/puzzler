extends Button

func _on_pressed()-> void:
	if OS.has_feature("web"): 
		print("End_game -> Lynn_Wilson_Art_Link.gd -> _on_pressed() -> Web -> https://lynnwilsonart.com")
		# Delete the saved game 
		Globals.g_delete_puzzle()
		# Log to webserver end session
		ApiData._send_api_data(false)
		
		await get_tree().create_timer(Globals.quit_wait_time).timeout
		# Attempt to close the browser window/tab  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href =  Globals.lwa_url
		
	else:
		print("End_game -> Lynn_Wilson_Art_Link.gd -> _on_pressed() -> Web -> https://lynnwilsonart.com")
		# 1. Open the website in the default browser
	OS.shell_open(Globals.lwa_url)
	
	# 2. Terminate the app immediately
	get_tree().quit()
		
	
