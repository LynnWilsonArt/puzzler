extends Button
# "res://scene/main/quit_button.gd"


func _on_pressed() -> void:
	print("Quitting game...")
	if OS.has_feature("web"): 
		# Attempt to close the browser window/tab  
		var win = JavaScriptBridge.get_interface("window")
		win.location.href = "https://puzzler.lynnwilsonart.com"  
	else:  
		# Standard behavior for Android, Windows, macOS, etc. 
		get_tree().quit()
