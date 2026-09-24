extends Button
# res://Scenes/Shop/cancel.gd

var scene_path: String = "res://Scenes/End_game/end_game.tscn"


func _on_pressed() -> void:
	if scene_path != "":

		# Switch directly via the file string path
		var error_code = get_tree().change_scene_to_file(scene_path)
		
		# Check if Godot ran into an error while transitioning
		if error_code != OK:
			push_error("[Shop -> Close Button -> Failed to switch scenes! Error code: ", error_code)
	else:
		push_error("[Shop] -> Close Button -> The Main scene path string is completely empty!")
