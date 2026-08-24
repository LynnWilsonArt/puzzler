extends Node
# Puzzle toggle puzzle display script
#

var toggle_puzzle = false

func _input(event):
	if event.is_action_pressed("toggle_puzzle"):
		toggle_puzzle = !toggle_puzzle
		print("Puzzle Toggled: ", toggle_puzzle)
		$puzzle_display.visible = toggle_puzzle	
