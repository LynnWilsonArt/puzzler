
# res://Scenes/Main/app_id.gd
extends Node
var rng =  RandomNumberGenerator.new()
var app_id_file_path = "user://app_id.txt"

func _get_app_number():
	var app_number
	if FileAccess.file_exists(app_id_file_path):
		var file = FileAccess.open(app_id_file_path, FileAccess.READ)
		if file:
			var app_id = file.get_as_text().strip_edges()
			file.close()
			print("Existing App ID: ", app_id)
			# Proceed to main program
			app_number = app_id
		else:
			push_error("Failed to open app_id file for reading.")
			app_number = ""
	else:
		rng.randomize()
		var app_id = rng.randi()
		print("Generated App ID: ", app_id)
		var file = FileAccess.open(app_id_file_path, FileAccess.WRITE)
		if file:
			file.store_line(str(app_id)) # convert to string before saving
			file.close()
			# Proceed to main program
			app_number = str(app_id)
		else:
			push_error("Failed to open app_id file for writing.")
			app_number = ""
	return(app_number)
