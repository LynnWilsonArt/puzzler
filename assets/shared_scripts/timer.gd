extends Node

@export var timer_state: bool = false
@export var count: int = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_timer()

func start_timer() -> void:
	print("Timer started!")
	# Creates a lightweight, self-cleaning 15-second timer
	await get_tree().create_timer(count).timeout
	_on_timer_timeout()

func _on_timer_timeout() -> void:
	print("HUD Time's up!")
	# Handle your puzzle game state penalty or turn skipping here
	$HUD_display.visible = false
