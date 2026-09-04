# res://Scenes/End_game/lwnn_wilson_art_link.gd
extends Button

func _on_pressed()-> void:
	if OS.has_feature("web"): 
		print("End_game -> puzzler_website.gd -> _on_pressed() -> Web -> https://puzzler.lynnwilsonart.com")
		# Delete the saved game 
		Globals.g_delete_puzzle()
		# Attempt to close the browser window/tab  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href =  Globals.puzzler_website_url
	else:
		print("End_game -> puzzler_website.gd -> _on_pressed() -> Web -> https://puzzler.lynnwilsonart.com")
		# 1. Open the website in the default browser
	OS.shell_open(Globals.puzzler_website_url)
	# Handle Android OS
	print("End_game -> quit_button.gd -> _on_pressed() -> Android -> Delete saved Game")
	# Delete the saved game 
	Globals.g_delete_puzzle() 		
	if OS.has_feature("android"):
		BackButtonHandler._move_app_to_background()
	else:
		# Standard behavior for Android, Windows, macOS, etc.
		get_tree().quit()
		
	
