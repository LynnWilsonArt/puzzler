# res://Scenes/Puzzle/puzzle_toggle_puzzle_display.gd
extends Control

var puzzle_image : TextureRect = null
var toggle_puzzle : bool = false
var timer_token   : int  = 0
var bg_music_mode: bool = true



func _ready() -> void:
	print("[Puzzle] -> toggle_puzzle_display.gd -> _ready()")
	_find_puzzle_image_node()
	var game_scene = get_parent()
	if game_scene and game_scene.has_signal("photographer_updated"):
		game_scene.photographer_updated.connect(_on_photographer_updated)
	
func _find_puzzle_image_node() -> void:
	print("[Puzzle] -> toggle_puzzle_display.gd -> _find_puzzle_image_node()")
	if has_node("puzzle_image"):
		puzzle_image = $puzzle_image as TextureRect
	elif has_node("Puzzle/puzzle_image"):
		puzzle_image = $Puzzle/puzzle_image as TextureRect

func _set_preview_visible(is_vis: bool) -> void:
	print("[Puzzle] -> toggle_puzzle_display.gd -> _set_preview_visible()")
	if has_node("Puzzle"):
		$Puzzle.visible = is_vis
	else:
		visible = is_vis

func _on_photographer_updated(pname: String) -> void:
	print("[Puzzle] -> toggle_puzzle_display.gd -> _on_photographer_updated()")
	var credits_label : Label = null
	if has_node("Credits"):
		credits_label = $Credits as Label
	elif has_node("Puzzle/Credits"):
		credits_label = $Puzzle/Credits as Label

	if credits_label:
		if pname != "":
			credits_label.text = "Photo by: " + pname + " - Find them at pixabay.com"
		else:
			credits_label.text = ""

func _on_right_click_triggered() -> void:
	print("[Puzzle] -> toggle_puzzle_display.gd -> _on_right_vlick_triggered()")
	toggle_puzzle = !toggle_puzzle
	_set_preview_visible(toggle_puzzle)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_puzzle"):
		_on_right_click_triggered()

func _start_puzzle_timer() -> void:
	print("[Puzzle] -> toggle_puzzle_display.gd -> _start_puzzle_timer()")
	print("[Puzzle] -> Shows original image 5 seconds before slicing it.")
	timer_token += 1
	var my_token = timer_token
	await get_tree().create_timer(5.0).timeout
	if my_token != timer_token:
		return
	_on_timer_timeout()

func _on_timer_timeout() -> void:
	print("[Puzzle] -> _start_puzzle_timer() -> Timed out.")
	if toggle_puzzle:
		toggle_puzzle = false
		_set_preview_visible(false)

func _on_puzzle_toggle_requested(state: bool) -> void:
	print("[Puzzle] -> toggle_puzzle_display.gd -> _on_puzzle_toggl_request()")
	toggle_puzzle = state
	_set_preview_visible(toggle_puzzle)

func _on_change_puzzle_image_requested(img: Texture2D) -> void:
	print("[Puzzle] -> toggle_puzzle_display.gd -> _on_puzzle_image_request()")
	if img == null:
		return

	if puzzle_image == null:
		_find_puzzle_image_node()

	if puzzle_image:
		puzzle_image.texture = img

	toggle_puzzle = true
	_set_preview_visible(true)
	_start_puzzle_timer()

func _on_show_original_image_pressed() -> void:
	print("[Puzzle] -> toggle_puzzle_display.gd -> _on_show_original_image_pressed()")
	_set_preview_visible(toggle_puzzle)

func _save_puzzle() -> void:
	print("[Puzzle] -> ggle_puzzle_display.gd -> _save_puzzle()")
	var game_root = get_parent()
	if game_root and game_root.has_method("save_puzzle"):
		game_root.save_puzzle()

func _load_puzzle() -> void:
	print("[Puzzle] -> toggle_puzzle_display.gd -> _load_puzzle()")
	toggle_puzzle = true
	var game_root = get_parent()
	if game_root and game_root.has_method("_load_puzzle"):
		game_root._load_puzzle()
		_start_puzzle_timer()
		_on_show_original_image_pressed()
