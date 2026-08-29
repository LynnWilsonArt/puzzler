extends Button
# "res://scene/main/quit_button.gd"


func _on_pressed() -> void:
	# DEBUG
	print("Main -> quit_button.gd -> _on_pressed()")
		
	if OS.has_feature("web"): 
		# Attempt to close the browser window/tab  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href =  Globals.web_home_page
	else:  
		# Standard behavior for Android, Windows, macOS, etc. 
		get_tree().quit()
