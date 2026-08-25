# res://scene/puzzle/toggle_puzzle_display.gd
extends Node

# --------------------------------------------------------------------
# This node only handles the reference-image PREVIEW overlay
# (show/hide on right-click, auto-hide timer). Actual puzzle save/load
# lives in game_script.gd, since that's what owns the grid, the piece
# metadata, and the click/swap logic. The two methods below just
# forward to it so existing menu wiring (which calls save_puzzle() /
# load_puzzle() on this node) keeps working unchanged.
# --------------------------------------------------------------------

@onready var puzzle_image : TextureRect  = $Puzzle/puzzle_image

var toggle_puzzle : bool = false
var timer_token  : int   = 0

func _ready() -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _ready()")

func _on_right_click_triggered() -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _on_right_click_triggered()")
	toggle_puzzle = !toggle_puzzle
	print("Puzzle Toggled via Right-Click ", toggle_puzzle)
	$Puzzle.visible = toggle_puzzle

func _input(event):
	if event.is_action_pressed("toggle_puzzle"):
		_on_right_click_triggered()

func _start_puzzle_timer() -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _start_puzzle_timer()")
	timer_token += 1
	var my_token = timer_token
	print("Puzzle Display Timer started!")
	await get_tree().create_timer(5.0).timeout
	if my_token != timer_token:
		return
	_on_timer_timeout()

func _on_timer_timeout() -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _on_timer_timeout()")
	if toggle_puzzle:
		print("Puzzle preview time's up! -> hiding reference image")
		toggle_puzzle = false
		$Puzzle.visible = false

func _on_puzzle_toggle_requested(state: bool) -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _on_puzzle_toggle_requested()")
	toggle_puzzle = state
	$Puzzle.visible = toggle_puzzle

func _on_change_puzzle_image_requested(img: Texture2D) -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _on_change_puzzle_image_requested()")
	if img == null:
		push_error("Received null texture!")
		return
	puzzle_image.texture = img
	toggle_puzzle = true
	$Puzzle.visible = true
	_start_puzzle_timer()
	print("Changed puzzle_image")

func _on_show_original_image_pressed() -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _on_show_original_image_pressed()")
	toggle_puzzle = !toggle_puzzle
	print("Show original image for reference: ", toggle_puzzle)
	$Puzzle.visible = toggle_puzzle

# --------------------------------------------------------------------
# Forwarders — the real save/load logic lives on the game root
# (game_script.gd), since $Puzzle is a child of that node.
# --------------------------------------------------------------------
func save_puzzle() -> void:
	var game_root = get_parent()
	if game_root and game_root.has_method("save_puzzle"):
		game_root.save_puzzle()
	else:
		push_error("Could not find game_script.gd on parent node to save the puzzle.")

func load_puzzle() -> void:
	var game_root = get_parent()
	if game_root and game_root.has_method("load_puzzle"):
		game_root.load_puzzle()
	else:
		push_error("Could not find game_script.gd on parent node to load the puzzle.")
