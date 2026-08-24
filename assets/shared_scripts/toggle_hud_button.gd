extends Button

signal toggle_puzzle_display(state: bool)

# Tracks the state locally on the button
@export var toggle_puzzle: bool = false

func _ready() -> void:
	# Connect the button's built-in pressed signal to our custom function below
	pressed.connect(_on_button_pressed)
	
	# Fixed path: Looks up one level to game_scene, then down to Puzzle
	var puzzle_node = get_node_or_null("../../../../Puzzle")
	# connect to Puzzle function
	if puzzle_node:
		toggle_puzzle_display.connect(puzzle_node._on_puzzle_toggle_requested)
	else:
		print("Warning: Button could not find the Puzzle node sibling!")

func _on_button_pressed() -> void:
	# Flip the local tracking boolean
	toggle_puzzle = !toggle_puzzle
	
	# Emit the newly flipped state (true or false) to the Puzzle
	toggle_puzzle_display.emit(toggle_puzzle)
