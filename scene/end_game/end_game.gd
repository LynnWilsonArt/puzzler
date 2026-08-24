extends Node2D

var end_game: Node = null
var puzzle_node: Node = null

func _ready() -> void:
	# Search dynamically up the tree to find the root 'end_game'
	var current = self
	while current != null:
		if current.name == "end_game":
			end_game = current
			puzzle_node = current.get_node_or_null("Puzzle")
			break
		current = current.get_parent()

	if end_game == null:
		print("Warning: Could not find end_game root node up the tree layout.")
		return

	if puzzle_node == null:
		print("Warning: Could not find Puzzle node child inside end_game.")
		return

	var panel = puzzle_node.get_node_or_null("PanelContainer")
	if panel == null:
		print("Warning: Could not find PanelContainer inside Puzzle node.")
		return

	panel.visible = false
