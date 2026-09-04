
# res://Scenes/End_game/contact_form.gd
extends Button

func _on_pressed()-> void:
	if OS.has_feature("web"): 
		print("End_game -> Lynn_Wilson_Art_Link.gd -> _on_pressed() -> Web -> https://lynnwilsonart.com")
		# Delete the saved game 
		Globals.g_delete_puzzle()
		
		# Attempt to close the browser window/tab  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href =  Globals.lwa_contact_url
	else:
		print("End_game -> Lynn_Wilson_Art_Link.gd -> _on_pressed() -> Web -> https://lynnwilsonart.com")
		# 1. Open the website in the default browser
	OS.shell_open(Globals.lwa_contact_url)
	# Handle Android OS
	print("End_game -> quit_button.gd -> _on_pressed() -> Android -> Delete saved Game")
	# Delete the saved game 
	Globals.g_delete_puzzle() 		
	if OS.has_feature("android"):
		BackButtonHandler._move_app_to_background()
	else:
		# Standard behavior for Android, Windows, macOS, etc.
		get_tree().quit()
