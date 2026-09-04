# res://Scenes/Main/quit_button.gd
extends Button

func _on_pressed() -> void:
	print("Main -> quit_button.gd -> _on_pressed()")
		
	if OS.has_feature("web"): 
		# Attempt to close the browser window/tab  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href =  Globals.web_home_page
	else:  
		# Standard behavior for Android, Windows, macOS, etc. 
		# Pause for exactly x seconds
		await get_tree().create_timer(Globals.quit_wait_time).timeout
		if OS.has_feature("android"):
			BackButtonHandler._move_app_to_background()
		else:
			# Standard behavior for Android, Windows, macOS, etc.
			get_tree().quit()
