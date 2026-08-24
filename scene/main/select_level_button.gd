extends Button
# "res://scene/main/select_level_button.gd"



func _on_pressed() -> void:
	if  Globals.debug:
		print("DEBUG -> select_level_botton.gd -> _on_pressed()")
		
	print("Select level button pressed")
