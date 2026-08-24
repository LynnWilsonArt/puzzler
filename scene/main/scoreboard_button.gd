extends Button
# "res://scene/main/scoreboard_button.gd"


func _on_pressed() -> void:
	if  Globals.debug:
		print("DEBUG -> scoreboard_button.gd -> _on_pressed()")
		
	print("Scoreboard button pressed")
