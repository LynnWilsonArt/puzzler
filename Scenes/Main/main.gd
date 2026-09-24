# res://Scenes/Main/main.gd
extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("[main.gd] -> _ready()")
	# Stopping -> starts in game.gd
	Globals.autosave_timer.stop()
	var has_plugin: bool = Engine.has_singleton("GodotGooglePlayBilling") 
	print("Got Google billing plugin: ",has_plugin)
