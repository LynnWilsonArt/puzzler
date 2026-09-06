# res://scene/Puzzle/toggle_puzzle_display.gd
extends Node
# --------------------------------------------------------------------
# This node only handles the reference-image PREVIEW overlay
# (show/hide on right-click, auto-hide timer). Actual puzzle save/load
# lives in game_script.gd, since that's what owns the grid, the piece
# metadata, and the click/swap logic. The two methods below just
# forward to it so existing menu wiring (which calls save_puzzle() /
# load_puzzle() on this node) keeps working unchanged.
@onready var puzzle_image : TextureRect  = $Puzzle/puzzle_image
var toggle_puzzle : bool = false
var timer_token  : int   = 0
var count = 0

func _ready() -> void:
	print("Puzzle -> toggle_puzzle_display.gd -> _ready()")
	# Used in logging
	count = 0

	# Hook up the photographer credit label. game_script.gd (our parent)
	# emits photographer_updated whenever a new image is loaded, whether
	# fresh from Pixabay, restored from save, or from the backup source.
	var game_scene = get_parent()
	if game_scene and game_scene.has_signal("photographer_updated"):
		game_scene.photographer_updated.connect(_on_photographer_updated)
		print("Puzzle -> toggle_puzzle_display.gd -> Connected to photographer_updated signal.")
	else:
		push_error("Puzzle -> toggle_puzzle_display.gd -> Could not connect photographer_updated — parent has no such signal.")

func _on_photographer_updated(pname: String) -> void:
	print("Puzzle -> toggle_puzzle_display.gd -> _on_photographer_updated() FIRED with: '", pname, "'")
	var credits_label : Label = null
	if has_node("Credits"):
		credits_label = $Credits
		print("Puzzle -> toggle_puzzle_display.gd -> Found Credits at $Credits")
	elif has_node("Puzzle/Credits"):
		credits_label = $Puzzle/Credits
		print("Puzzle -> toggle_puzzle_display.gd -> Found Credits at $Puzzle/Credits")
	else:
		push_error("Puzzle -> toggle_puzzle_display.gd -> Could not find a Credits node at $Credits or $Puzzle/Credits.")
		return

	if pname != "":
		credits_label.text = "Photo by: " + pname +" - Find them at pixabay.com"
	else:
		credits_label.text = ""

func _on_right_click_triggered() -> void:
	print(" Puzzle -> toggle_puzzle_display.gd -> _on_right_click_triggered()")

	toggle_puzzle = !toggle_puzzle
	print("Puzzle -> toggle_puzzle_display.gd -> Puzzle Toggled via Right-Click ", toggle_puzzle)
	$Puzzle.visible = toggle_puzzle
func _input(event):
	count += 1
	if count == 1:
		print("Puzzle -> toggle_puzzle_display.gd -> _input(event)")

	if event.is_action_pressed("toggle_puzzle"):
		_on_right_click_triggered()
func _start_puzzle_timer() -> void:
	print("Puzzle -> toggle_puzzle_display.gd -> _start_puzzle_timer()")

	timer_token += 1
	var my_token = timer_token
	print("Puzzle -> toggle_puzzle_display.gd -> Puzzle Display Timer started!")
	await get_tree().create_timer(5.0).timeout
	if my_token != timer_token:
		return
	_on_timer_timeout()
func _on_timer_timeout() -> void:
	print("Puzzle -> toggle_puzzle_display.gd -> _on_timer_timeout()")

	if toggle_puzzle:
		print("Puzzle preview time's up! -> hiding reference image")
		toggle_puzzle = false
		$Puzzle.visible = false
func _on_puzzle_toggle_requested(state: bool) -> void:
	print("Puzzle -> toggle_puzzle_display.gd -> _on_puzzle_toggle_requested()")

	toggle_puzzle = state
	$Puzzle.visible = toggle_puzzle
func _on_change_puzzle_image_requested(img: Texture2D) -> void:
	print("Puzzle -> toggle_puzzle_display.gd -> _on_change_puzzle_image_requested()")

	if img == null:
		push_error("Puzzle -> toggle_puzzle_display.gd -> Received null texture!")
		return
	puzzle_image.texture = img
	toggle_puzzle = true
	$Puzzle.visible = true
	_start_puzzle_timer()
	print("Puzzle -> toggle_puzzle_display.gd -> Changed puzzle_image")
func _on_show_original_image_pressed() -> void:
	print("Puzzle -> toggle_puzzle_display.gd -> _on_show_original_image_pressed()")
	print("Puzzle -> toggle_puzzle_display.gd -> Show original image for reference: ", toggle_puzzle)
	$Puzzle.visible = toggle_puzzle
# --------------------------------------------------------------------
# Forwarders — the real save/load logic lives on the game root
# (game_script.gd), since $Puzzle is a child of that node.
# --------------------------------------------------------------------
func save_puzzle() -> void:
	print("Puzzle -> toggle_puzzle_display.gd -> save_puzzle()")

	var game_root = get_parent()
	if game_root and game_root.has_method("save_puzzle"):
		game_root.save_puzzle()
	else:
		push_error("Puzzle -> toggle_puzzle_display.gd -> Could not find game_script.gd on parent node to save the puzzle.")
func load_puzzle() -> void:
	print("Puzzle -> toggle_puzzle_display.gd -> load_puzzle()")
	toggle_puzzle = !toggle_puzzle # Comes in false - switches to true
	var game_root = get_parent()
	if game_root and game_root.has_method("load_puzzle"):
		game_root.load_puzzle()
		_start_puzzle_timer()
		_on_show_original_image_pressed()
	else:
		push_error("Puzzle -> toggle_puzzle_display.gd -> Could not find game_script.gd on parent node to load the puzzle.")
