# res://Scenes/End_game/end_game.gd
extends Node2D

var end_game: Node = null
var puzzle_node: Node = null

func _ready() -> void:
	#Stop the autosave timer
	Globals.autosave_timer.stop()
