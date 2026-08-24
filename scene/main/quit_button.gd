extends Button
# "res://scene/main/quit_button.gd"


func _on_pressed() -> void:
	if  Globals.debug:
		print("DEBUG -> quit_button.gd -> _on_pressed()")
		
	print("Quit button pressed")
	
	get_tree().quit()
