# res://Scenes/Game/game_script.gd
extends Node2D

signal puzzle_toggle_requested(is_visible: bool)
signal change_puzzle_image(image: Texture2D)
signal photographer_updated(name: String)

@export var num_columns : int = Globals.columns
@export var num_rows    : int = Globals.rows
@export var grid_size   : Vector2 = Vector2(1152, 648)
@export var game_scene_path : String = "res://Scenes/End_game/end_game.tscn"
@export var puzzle_image = Image.new()

const SAVE_PATH := "user://puzzle_state.save"

# Fallback Configuration
@export var fetch_timeout_seconds : float = 15.0
@export var backup_max_attempts : int = 3

var pieces_data : Array[Dictionary] = []
var first_selected_piece : TextureRect = null
var swapping : bool = false

var timeout_timer : Timer = null
var backup_attempts_made : int = 0
var puzzle_resolved : bool = false
var puzzle_photographer : String = ""

# Progress UI
var progress_layer : CanvasLayer
var progress_bar : ProgressBar
var progress_status_label : Label

func _ready() -> void:
	print("Game -> game_script.gd -> _ready()")
	Globals.start_autosave()
	_create_progress_popup_ui()

	Api.request_started.connect(_on_api_request_started)
	Api.progress_updated.connect(_on_api_progress_updated)
	Api.image_ready.connect(_on_image_ready)
	Api.request_failed.connect(_on_api_request_failed)

	timeout_timer = Timer.new()
	timeout_timer.one_shot = true
	timeout_timer.wait_time = fetch_timeout_seconds
	add_child(timeout_timer)
	timeout_timer.timeout.connect(_on_fetch_timeout)

	if $Puzzle:
		puzzle_toggle_requested.connect($Puzzle._on_puzzle_toggle_requested)
		change_puzzle_image.connect($Puzzle._on_change_puzzle_image_requested)

	if FileAccess.file_exists(SAVE_PATH):
		load_puzzle()
	else:
		_on_get_puzzle()

# ---------- PROGRESS UI ----------

func _create_progress_popup_ui() -> void:
	progress_layer = CanvasLayer.new()
	progress_layer.layer = 100
	progress_layer.visible = false
	add_child(progress_layer)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	progress_layer.add_child(overlay)

	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	progress_layer.add_child(center_container)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 160)
	center_container.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "Loading Image..."
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	progress_status_label = Label.new()
	progress_status_label.text = "Connecting to server..."
	progress_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(progress_status_label)

	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(380, 24)
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	vbox.add_child(progress_bar)

func _show_progress_popup(message: String) -> void:
	if progress_layer:
		progress_status_label.text = message
		progress_bar.value = 0
		progress_layer.visible = true

func _hide_progress_popup() -> void:
	if progress_layer:
		progress_layer.visible = false

func _on_api_request_started() -> void:
	_show_progress_popup("Fetching image from server...")

func _on_api_progress_updated(percent: float) -> void:
	if progress_bar:
		progress_bar.value = percent
		if percent < 30.0:
			progress_status_label.text = "Searching image category..."
		elif percent < 100.0:
			progress_status_label.text = "Downloading image payload (" + str(int(percent)) + "%)..."
		else:
			progress_status_label.text = "Processing image..."

# ---------- PUZZLE FETCH & SETUP ----------

func _on_get_puzzle() -> void:
	puzzle_resolved = false
	backup_attempts_made = 0
	Api.fetch_puzzle_image(Globals.category)
	timeout_timer.stop()
	timeout_timer.start()

func _on_image_ready(server_imageTexture: ImageTexture, photographer: String = "") -> void:
	if puzzle_resolved:
		return

	puzzle_resolved = true
	timeout_timer.stop()
	_hide_progress_popup()

	puzzle_photographer = photographer
	photographer_updated.emit(puzzle_photographer)
	_start_puzzle_from_texture(server_imageTexture)

func _on_api_request_failed(_err_msg = "") -> void:
	if puzzle_resolved:
		return
	_fetch_backup_puzzle_image()

func _on_fetch_timeout() -> void:
	if puzzle_resolved:
		return
	_fetch_backup_puzzle_image()

func _fetch_backup_puzzle_image() -> void:
	if puzzle_resolved:
		return

	if backup_attempts_made >= backup_max_attempts:
		_hide_progress_popup()
		push_error("Game -> game_script.gd -> Exhausted backup attempts.")
		$NoInternetPopup.show()
		return

	backup_attempts_made += 1
	_show_progress_popup("Fetching fallback image from 'default' category (" + str(backup_attempts_made) + "/" + str(backup_max_attempts) + ")...")

	timeout_timer.stop()
	timeout_timer.start()
	Api.fetch_puzzle_image("default")

func _start_puzzle_from_texture(tex: Texture2D) -> void:
	if tex == null:
		push_error("Game -> game_script.gd -> Received null texture!")
		return

	puzzle_image = tex.get_image()
	puzzle_image.resize(int(grid_size.x), int(grid_size.y))

	var resized_tex = ImageTexture.create_from_image(puzzle_image)
	change_puzzle_image.emit(resized_tex)

	_slice_image(resized_tex)
	_randomize_pieces()
	_place_pieces_on_grid()
	save_puzzle()

func _slice_image(tex : Texture2D) -> void:
	pieces_data.clear()
	var img = tex.get_image()
	img.resize(int(grid_size.x), int(grid_size.y))

	@warning_ignore("narrowing_conversion")
	var pw = float(img.get_width()) / num_columns
	var ph = float(img.get_height()) / num_rows

	var index := 0
	for r in range(num_rows):
		for c in range(num_columns):
			var rect = Rect2i(int(c * pw), int(r * ph), int(pw), int(ph))
			var piece_img = img.get_region(rect)
			var piece_tex = ImageTexture.create_from_image(piece_img)

			pieces_data.append({
				"texture": piece_tex,
				"id": index
			})
			index += 1

func _slice_image_to_map(tex: Texture2D) -> Dictionary:
	var map := {}
	var img = tex.get_image()
	img.resize(int(grid_size.x), int(grid_size.y))

	@warning_ignore("narrowing_conversion")
	var pw = float(img.get_width()) / num_columns
	var ph = float(img.get_height()) / num_rows

	var index := 0
	for r in range(num_rows):
		for c in range(num_columns):
			var rect = Rect2i(int(c * pw), int(r * ph), int(pw), int(ph))
			var piece_img = img.get_region(rect)
			map[index] = ImageTexture.create_from_image(piece_img)
			index += 1

	return map

func _randomize_pieces() -> void:
	pieces_data.shuffle()

func _place_pieces_on_grid() -> void:
	first_selected_piece = null
	swapping = false

	var grid : GridContainer = $Puzzle/GridContainer
	grid.columns = num_columns
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)

	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	var piece_width = grid_size.x / num_columns
	var piece_height = grid_size.y / num_rows
	var piece_script = load("res://Scenes/Game/puzzle_piece_swap.gd")

	for slot_idx in range(pieces_data.size()):
		var data = pieces_data[slot_idx]
		_build_piece(grid, slot_idx, data["texture"], data["id"], piece_width, piece_height, piece_script)

func _build_piece(grid: GridContainer, slot_idx: int, tex: Texture2D, texture_id: int, piece_width: float, piece_height: float, piece_script: GDScript) -> TextureRect:
	var rect = TextureRect.new()
	rect.texture = tex
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.custom_minimum_size = Vector2(piece_width, piece_height)
	rect.set_script(piece_script)

	if rect.has_method("initialize_piece_meta"):
		rect.initialize_piece_meta(slot_idx, texture_id)
	else:
		rect.set_meta("correct_slot_id", slot_idx)
		rect.set_meta("current_texture_id", texture_id)

	rect.piece_clicked.connect(_on_piece_clicked)
	grid.add_child(rect)
	return rect

func _on_piece_clicked(piece : TextureRect) -> void:
	if swapping:
		return

	if first_selected_piece == null:
		first_selected_piece = piece
		first_selected_piece.modulate = Color(0.8, 0.8, 1.0, 1.0)
		return

	if first_selected_piece == piece:
		first_selected_piece.modulate = Color.WHITE
		first_selected_piece = null
		return

	swapping = true
	var p1 = first_selected_piece
	var p2 = piece
	first_selected_piece = null

	p1.modulate = Color.WHITE
	var state = {"finished": 0}

	var finish_callback = func():
		state["finished"] += 1
		if state["finished"] == 2:
			var tmp_tex = p1.texture
			p1.texture = p2.texture
			p2.texture = tmp_tex

			var id1 = p1.get_meta("current_texture_id")
			var id2 = p2.get_meta("current_texture_id")
			p1.set_meta("current_texture_id", id2)
			p2.set_meta("current_texture_id", id1)

			swapping = false
			_check_win_condition()

	p1.animate_swap(p2, finish_callback)
	p2.animate_swap(p1, finish_callback)

func _check_win_condition() -> void:
	var grid : GridContainer = $Puzzle/GridContainer
	for rect in grid.get_children():
		if rect is TextureRect:
			var slot_id = rect.get_meta("correct_slot_id")
			var current_tex_id = rect.get_meta("current_texture_id")
			if slot_id != current_tex_id:
				return
	_trigger_victory()

func _trigger_victory() -> void:
	$Alert_Completed.popup()
	await $Alert_Completed.confirmed

	swapping = true
	puzzle_toggle_requested.emit(true)

	if game_scene_path != "":
		get_tree().change_scene_to_file(game_scene_path)

# ---------- SAVE & LOAD ----------

func save_puzzle() -> void:
	var grid : GridContainer = $Puzzle/GridContainer
	if grid.get_child_count() == 0 or puzzle_image == null:
		return

	var grid_state : Array = []
	for rect in grid.get_children():
		if not (rect is TextureRect):
			continue
		grid_state.append({
			"correct_slot_id"   : rect.get_meta("correct_slot_id"),
			"current_texture_id": rect.get_meta("current_texture_id"),
		})

	var state := {
		"image_bytes": puzzle_image.save_png_to_buffer(),
		"num_columns": num_columns,
		"num_rows"   : num_rows,
		"grid"       : grid_state,
		"photographer": puzzle_photographer,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(state)
		file.close()

func load_puzzle() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_on_get_puzzle()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_on_get_puzzle()
		return

	var state = file.get_var()
	file.close()

	# Reset save file if corrupted or from old incompatible version
	if state == null or not (state is Dictionary) or not state.has("grid"):
		push_warning("Game -> Corrupted save file detected. Deleting user://puzzle_state.save and fetching fresh puzzle...")
		DirAccess.remove_absolute(SAVE_PATH)
		_on_get_puzzle()
		return

	var img_bytes : PackedByteArray = state.get("image_bytes", PackedByteArray())
	if img_bytes.size() == 0:
		push_warning("Game -> Save file has empty image data. Deleting user://puzzle_state.save and fetching fresh puzzle...")
		DirAccess.remove_absolute(SAVE_PATH)
		_on_get_puzzle()
		return

	num_columns = state.get("num_columns", num_columns)
	num_rows = state.get("num_rows", num_rows)
	puzzle_photographer = state.get("photographer", "")
	photographer_updated.emit(puzzle_photographer)

	var full_img := Image.new()
	var err = full_img.load_from_buffer(img_bytes) if full_img.has_method("load_from_buffer") else full_img.load_png_from_buffer(img_bytes)
	if err != OK:
		push_warning("Game -> Could not decode image bytes from save file. Deleting user://puzzle_state.save and fetching fresh puzzle...")
		DirAccess.remove_absolute(SAVE_PATH)
		_on_get_puzzle()
		return

	puzzle_image = full_img
	puzzle_image.resize(int(grid_size.x), int(grid_size.y))

	var restored_tex = ImageTexture.create_from_image(puzzle_image)
	change_puzzle_image.emit(restored_tex)

	var texture_map := _slice_image_to_map(restored_tex)

	var grid : GridContainer = $Puzzle/GridContainer
	grid.columns = num_columns
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)

	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	first_selected_piece = null
	swapping = false

	var piece_width = grid_size.x / num_columns
	var piece_height = grid_size.y / num_rows
	var piece_script = load("res://Scenes/Game/puzzle_piece_swap.gd")

	var grid_state : Array = state["grid"]
	for slot_idx in range(grid_state.size()):
		var piece_data : Dictionary = grid_state[slot_idx]
		var texture_id : int = piece_data.get("current_texture_id", slot_idx)

		var piece_tex : Texture2D = texture_map.get(texture_id, null)
		_build_piece(grid, slot_idx, piece_tex, texture_id, piece_width, piece_height, piece_script)
