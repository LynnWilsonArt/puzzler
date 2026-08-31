extends Button
# "res://scene/main/quit_button.gd"

	
func _on_pressed() -> void:
	print("Main -> quit_button.gd -> _on_pressed()")
		
	if OS.has_feature("web"): 
		# Log to webserver end session
		ApiData._send_api_data(false)
		# Pause for exactly x seconds
		await get_tree().create_timer(Globals.quit_wait_time).timeout
		# Attempt to close the browser window/tab  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href =  Globals.web_home_page
	else:  
		# Log to webserver end session
		ApiData._send_api_data(false)
		# Standard behavior for Android, Windows, macOS, etc. 
		# Pause for exactly x seconds
		await get_tree().create_timer(Globals.quit_wait_time).timeout
		BackButtonHandler._move_app_to_background()
	
