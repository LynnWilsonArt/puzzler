extends Button  
# File: res://Scenes/Main/select_level_button.gd

# Play_Button Script
# We use a simple text string for the file path to completely avoid loading loops

@export_file("*.tscn") var game_scene_path: String = "res://Scenes/Game/game.tscn"

func _on_pressed() -> void:
	print("Main -> start_button.gd -> _on_pressed()")
		
	# Web start music if Globals.sound_mode = true
	if OS.has_feature("web"):  
		if Globals.sound_mode:
			if !Globals.music_player.playing:
				print("Main -> start_button.gd -> Music is not playing ")
				return
			else:
				Globals.music_player.play()
	
	# Add a print statement to verify the button physically registers your click
	print("Main -> start_button.gd -> Play button was pressed! Attempting to load: ", game_scene_path)
	
	if game_scene_path != "":

		# Switch directly via the file string path
		var error_code = get_tree().change_scene_to_file(game_scene_path)
		
		# Check if Godot ran into an error while transitioning
		if error_code != OK:
			push_error("Main -> start_button.gd -> Failed to switch scenes! Error code: ", error_code)
	else:
		push_error("Main -> start_button.gd -> The game scene path string is completely empty!")
