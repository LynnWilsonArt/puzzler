# res://Scenes/End_game/end_game.gd
extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Stop the autosave timer. Game's over
	Globals.autosave_timer.stop()
	
