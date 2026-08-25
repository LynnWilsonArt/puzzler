# PuzzleState.gd
class_name PuzzleState
var tile_positions : PackedInt32Array = []
var moves : int = 0

func save() -> void:
	var data = {
		"tile_positions": tile_positions,
		"moves": moves
	}
	var file = FileAccess.open("user://puzzle_save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()

func load() -> void:
	if not FileAccess.file_exists("user://puzzle_save.json"):
		return
	var file = FileAccess.open("user://puzzle_save.json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	tile_positions = data["tile_positions"]
	moves = data["moves"]
