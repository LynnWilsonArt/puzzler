extends Button


var shop_scene_path: String = "res://Scenes/Shop/shop.tscn"


func _on_pressed() -> void:
	if shop_scene_path != "":

		# Switch directly via the file string path
		var error_code = get_tree().change_scene_to_file(shop_scene_path)
		
		# Check if Godot ran into an error while transitioning
		if error_code != OK:
			push_error("[End_game] -> RemoveAds Button -> Failed to switch scenes! Error code: ", error_code)
	else:
		push_error("[End_game] -> RemoveAds Button -> The shop scene path string is completely empty!")
