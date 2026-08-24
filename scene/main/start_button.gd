extends Button  
# "res://scene/main/start_button.gd"

# Play_Button Script
# We use a simple text string for the file path to completely avoid loading loops

@export_file("*.tscn") var game_scene_path: String = "res://scene/game/game.tscn"

func _on_pressed() -> void:
	# Program debuging toggle
	if Globals.debug:
		print("DEBUG -> start_button.gd ->_on_pressed()")

	# Add a print statement to verify the button physically registers your click
	print("Play button was pressed! Attempting to load: ", game_scene_path)
	
	if game_scene_path != "":
		# Switch directly via the file string path
		var error_code = get_tree().change_scene_to_file(game_scene_path)
		
		# Check if Godot ran into an error while transitioning
		if error_code != OK:
			push_error("Failed to switch scenes! Error code: ", error_code)
	else:
		push_error("The game scene path string is completely empty!")
