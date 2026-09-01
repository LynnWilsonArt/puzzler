# res://Scenes/End_game/lwnn_wilson_art_link.gd
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
	# Handle Android OS
	print("End_game -> quit_button.gd -> _on_pressed() -> Android -> Delete saved Game")
	# Delete the saved game 
	Globals.g_delete_puzzle() 		
	if OS.has_feature("android"):
		BackButtonHandler._move_app_to_background()
	else:
		# Standard behavior for Android, Windows, macOS, etc.
		# Pause for exactly 3 seconds for data to be sent
		ApiData._send_api_data(false)
		await get_tree().create_timer(Globals.quit_wait_time).timeout
		get_tree().quit()
		
	
