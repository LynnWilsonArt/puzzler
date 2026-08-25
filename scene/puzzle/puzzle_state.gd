# res://scene/puzzle/puzzle_state.gd
class_name PuzzleState
extends Resource

@export var image_path : String = ""          # Path to the puzzle texture
@export var pieces : Array[Dictionary] = []  # List of { name, pos, rot, scale }
