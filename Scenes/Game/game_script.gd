# res://Scenes/Game/game_script.gd
extends Node2D

signal puzzle_toggle_requested(is_visible: bool)
signal change_puzzle_image(image: Texture2D)
@export var num_columns : int = Globals.columns
@export var num_rows    : int = Globals.rows
@export var grid_size   : Vector2 = Vector2(1152, 648)
@export var game_scene_path : String = "res://Scenes/End_game/end_game.tscn"
@export var puzzle_image = Image.new()
const SAVE_PATH := "user://puzzle_state.save"

# ----------  BACKUP IMAGE SOURCE (used when Pixabay is rate-limited / fails)  ----------
@export var backup_image_base_url : String = "https://images.lynnwilsonart.com/images/"
@export var backup_image_min_index : int = 0
@export var backup_image_max_index : int = 321   # adjust to match how many images actually exist on the server
@export var pixabay_timeout_seconds : float = 6.0
@export var backup_max_attempts : int = 5        # how many random indexes to try before giving up

# FIXED: Change to an array of Dictionaries to hold textures alongside their correct indexes
var pieces_data : Array[Dictionary] = []
var first_selected_piece : TextureRect = null
var swapping : bool = false
var http_request : HTTPRequest
var count = 0

# Backup-fetch state
var pixabay_timeout_timer : Timer = null
var backup_attempts_made : int = 0
var backup_request_in_flight : bool = false
var used_backup_indexes : Array[int] = []
var puzzle_resolved : bool = false   # true once EITHER Pixabay or the backup has delivered an image

func _ready() -> void:
	print("Game -> game_script.gd ->  _ready()")
	Globals.start_autosave()

	# Connect the image_ready signal to the _on_image_ready function
	Pixabay.image_ready.connect(_on_image_ready)

	# OPTIONAL: hook into an explicit failure / rate-limit signal on the Pixabay
	# singleton if one exists. This is defensive — if Pixabay doesn't expose
	# one, we still catch failures via the timeout timer below.
	if Pixabay.has_signal("request_failed"):
		Pixabay.request_failed.connect(_on_pixabay_request_failed)
	if Pixabay.has_signal("rate_limited"):
		Pixabay.rate_limited.connect(_on_pixabay_request_failed)

	# HTTPRequest node used for pulling backup images directly.
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_backup_image_downloaded)

	# Timer used to detect a Pixabay request that never responds
	# (e.g. silently rate-limited with no explicit error signal).
	pixabay_timeout_timer = Timer.new()
	pixabay_timeout_timer.one_shot = true
	pixabay_timeout_timer.wait_time = pixabay_timeout_seconds
	add_child(pixabay_timeout_timer)
	pixabay_timeout_timer.timeout.connect(_on_pixabay_timeout)

	if $Puzzle:
		puzzle_toggle_requested.connect($Puzzle._on_puzzle_toggle_requested)
		change_puzzle_image.connect($Puzzle._on_change_puzzle_image_requested)
		print("Game -> game_script ->  ✅ Connection Successful: game_scene linked to Puzzle script!")
	else:
		print("Game -> game_script -> ❌  Connection Failed: Could not find Puzzle node at path '$Puzzle'")

	# Resume a saved puzzle if one exists, otherwise fetch a fresh one.
	if FileAccess.file_exists(SAVE_PATH):
		print("Game -> game_script -> Found saved puzzle — loading instead of fetching a new one.")
		load_puzzle()
	else:
		_on_get_puzzle()


# Request a new image from pixabay.com
func _on_get_puzzle()-> void:
	print("Game -> _game_script.gd -> _on_get_puzzle()")

	puzzle_resolved = false
	backup_attempts_made = 0
	used_backup_indexes.clear()
	# if pixabay fails it reverts to my image server https://images.lynnwilsonart.com
	Pixabay.fetch_puzzle_image(Globals.category)

	# Start (or restart) the timeout watchdog for this request.
	pixabay_timeout_timer.stop()
	pixabay_timeout_timer.start()


# Process the image from pixabay.com
func _on_image_ready(pixabay_imageTexture: ImageTexture) -> void:
	print("Game -> _game_script.gd -> _on_image_ready()")

	if puzzle_resolved:
		# A backup image already won the race (e.g. Pixabay answered late,
		# after the timeout already kicked in the backup path). Ignore it.
		print("Game -> game_script.gd -> Ignoring late Pixabay response — puzzle already resolved by backup source.")
		return

	puzzle_resolved = true
	pixabay_timeout_timer.stop()

	_start_puzzle_from_texture(pixabay_imageTexture)


# ----------  FALLBACK TRIGGERS  ----------

# Called if the Pixabay singleton exposes an explicit failure / rate-limit signal.
func _on_pixabay_request_failed(_err = null) -> void:
	print("Game -> game_script.gd -> _on_pixabay_request_failed() -> Pixabay reported a failure/rate-limit.")
	if puzzle_resolved:
		return
	pixabay_timeout_timer.stop()
	_fetch_backup_puzzle_image()


# Called if Pixabay never responds within pixabay_timeout_seconds.
func _on_pixabay_timeout() -> void:
	print("Game -> game_script.gd -> _on_pixabay_timeout() -> No response from Pixabay in time (likely rate-limited). Falling back.")
	if puzzle_resolved:
		return
	_fetch_backup_puzzle_image()


# ----------  BACKUP IMAGE FETCH (images.lynnwilsonart.com)  ----------

func _fetch_backup_puzzle_image() -> void:
	print("Game -> game_script.gd -> _fetch_backup_puzzle_image()")

	if puzzle_resolved:
		return

	if backup_request_in_flight:
		print("Game -> game_script.gd -> Backup request already in flight, skipping duplicate call.")
		return

	if backup_attempts_made >= backup_max_attempts:
		push_error("Game -> game_script.gd -> Exhausted backup attempts (" + str(backup_max_attempts) + "). Could not load any puzzle image.")
		return

	backup_attempts_made += 1

	# Pick a random index we haven't already tried this session.
	var index := -1
	var range_size = backup_image_max_index - backup_image_min_index + 1
	if used_backup_indexes.size() >= range_size:
		# We've tried every index in the range at least once — just retry a random one.
		index = randi_range(backup_image_min_index, backup_image_max_index)
	else:
		while true:
			var candidate = randi_range(backup_image_min_index, backup_image_max_index)
			if not used_backup_indexes.has(candidate):
				index = candidate
				break
	used_backup_indexes.append(index)

	var url = backup_image_base_url + str(index) + ".jpg"
	print("Game -> game_script.gd -> Requesting backup image: " + url)

	backup_request_in_flight = true
	var error_code = http_request.request(url)
	if error_code != OK:
		push_error("Game -> game_script.gd -> Failed to start HTTPRequest for backup image. Error code: " + str(error_code))
		backup_request_in_flight = false
		# Try another index instead of stalling forever.
		call_deferred("_fetch_backup_puzzle_image")


func _on_backup_image_downloaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	backup_request_in_flight = false

	if puzzle_resolved:
		# Race condition guard: Pixabay might have resolved things already.
		return

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or body.size() == 0:
		print("Game -> game_script.gd -> Backup image request failed (result=" + str(result) + ", code=" + str(response_code) + "). Trying another index.")
		_fetch_backup_puzzle_image()
		return

	var img := Image.new()
	var load_error = img.load_jpg_from_buffer(body)
	if load_error != OK:
		push_error("Game -> game_script.gd -> Failed to decode backup image (error " + str(load_error) + "). Trying another index.")
		_fetch_backup_puzzle_image()
		return

	print("Game -> game_script.gd -> Backup image downloaded and decoded successfully.")
	puzzle_resolved = true

	var tex = ImageTexture.create_from_image(img)
	_start_puzzle_from_texture(tex)


# Shared entry point once we have a valid Texture2D, whether it came from
# Pixabay or the lynnwilsonart backup source.
func _start_puzzle_from_texture(tex: Texture2D) -> void:
	puzzle_image = tex.get_image()

	# Saves the original image for popup
	change_puzzle_image.emit(tex) # makes orig image visible
	_slice_image(tex)
	_randomize_pieces()
	_place_pieces_on_grid()


func _slice_image(tex : Texture2D) -> void:

	print("Game -> _game_script.gd ->  _slice_image(tex: Texture2D)")
	pieces_data.clear()
	var img = tex.get_image()    # convert testure to image
	img.resize(1152,648)          # Resizing to puzzle size

	@warning_ignore("narrowing_conversion")
	var pw = float(img.get_width())  / num_columns
	var ph = float(img.get_height()) / num_rows

	var index := 0
	for r in range(num_rows):
		for c in range(num_columns):
			var rect = Rect2i(int(c*pw), int(r*ph), int(pw), int(ph))
			var piece_img = img.get_region(rect)
			var piece_tex = ImageTexture.create_from_image(piece_img)

			# STORE: Save both the texture and its correct position ID together
			pieces_data.append({
				"texture": piece_tex,
				"id": index
			})
			index += 1

func _randomize_pieces() -> void:
	print("Game -> _game_script.gd -> _randomize_pieces()")

	pieces_data.shuffle()

func _place_pieces_on_grid() -> void:
	print("Game -> _game_script.gd ->  _place_pieces_on_grid()")

	first_selected_piece = null   # clear stale selection from previous puzzle
	swapping = false              # Add this: just in case a swap was mid-flight when Skip was pressed

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

	# FIXED: Track slot positions explicitly from 0 to total pieces
	for slot_idx in range(pieces_data.size()):
		var data = pieces_data[slot_idx]
		_build_piece(grid, slot_idx, data["texture"], data["id"], piece_width, piece_height, piece_script)

# ----------  SHARED PIECE-BUILDING HELPER  ----------
# Used by both _place_pieces_on_grid() (fresh puzzle) and load_puzzle()
# (restored puzzle) so every piece is wired up identically.
func _build_piece(grid: GridContainer, slot_idx: int, tex: Texture2D, texture_id: int, piece_width: float, piece_height: float, piece_script: GDScript) -> TextureRect:
	count += 1
	if count == 1:
		print("Game -> game_script.gd -> _build_piece()")

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

# ----------  SWAP LOGIC  ----------
func _on_piece_clicked(piece : TextureRect) -> void:
	print("Game -> _game_script.gd -> _on_piece_clicked()")

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
		print("Game -> game_script.gd -> finish_callback()")
		state["finished"] += 1
		if state["finished"] == 2:
			# Swap textures
			var tmp_tex = p1.texture
			p1.texture = p2.texture
			p2.texture = tmp_tex

			# FIXED: Swap the metadata tracking tracking variables
			var id1 = p1.get_meta("current_texture_id")
			var id2 = p2.get_meta("current_texture_id")
			p1.set_meta("current_texture_id", id2)
			p2.set_meta("current_texture_id", id1)

			swapping = false

			# CHECK FOR WIN STATE
			_check_win_condition()

	p1.animate_swap(p2, finish_callback)
	p2.animate_swap(p1, finish_callback)

# ----------  ENDGAME CHECK  ----------
func _check_win_condition() -> void:
	print("Game -> _game_script.gd -> _check_win_condition()")

	var grid : GridContainer = $Puzzle/GridContainer

	for rect in grid.get_children():
		if rect is TextureRect:
			var slot_id = rect.get_meta("correct_slot_id")
			var current_tex_id = rect.get_meta("current_texture_id")

			# If any single piece does not line up with its slot, stop checking
			if slot_id != current_tex_id:
				return

	_trigger_victory()
# Alert popup
func _alert_top_left_dialog() ->void:
	print("Game -> game_script.gd -> _alert_top_left_dialog()")
	$Alert_Completed.popup()
	$Alert_Completed.popup()


func _trigger_victory() -> void:
	print("Game -> _game_script.gd -> _trigger_victory()")
	print("Pause game until ok clicked")
	_alert_top_left_dialog()
	await $Alert_Completed.confirmed


	print("Game -> game_script.gd -> Puzzle Complete! All pieces are in the correct place!")
	# Disable interaction entirely
	swapping = true
	print("Game -> game_script.gd -> puzzle_toggle_rquested -> emitted signal")
	puzzle_toggle_requested.emit(true)

	if game_scene_path != "":
		# Switch directly via the file string path
		var error_code = get_tree().change_scene_to_file(game_scene_path)

		# Check if Godot ran into an error while transitioning
		if error_code != OK:
			push_error("Game -> game_script.gd -> Failed to switch scenes! Error code: ", error_code)


# ======================================================================
# SAVE / LOAD — persists the CURRENT grid arrangement (not the original
# shuffle), so resuming puts every piece back exactly where you left it,
# fully clickable and swappable.
# ======================================================================

func save_puzzle() -> void:
	print("Game -> game_script -> save_puzzle()")

	var grid : GridContainer = $Puzzle/GridContainer
	if grid.get_child_count() == 0:
		push_error("Game -> game_script.gd -> Nothing to save — grid is empty.")
		return

	var grid_state : Array = []
	for rect in grid.get_children():
		if not (rect is TextureRect):
			continue
		var img : Image = null
		if rect.texture:
			img = rect.texture.get_image()
		grid_state.append({
			"tex_bytes"      : img.save_png_to_buffer() if img else PackedByteArray(),
			"correct_slot_id"   : rect.get_meta("correct_slot_id"),
			"current_texture_id": rect.get_meta("current_texture_id"),
		})

	var state := {

		"image_bytes": puzzle_image.save_png_to_buffer() if puzzle_image else PackedByteArray(),
		"num_columns": num_columns,
		"num_rows"   : num_rows,
		"grid"       : grid_state,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(state)
		file.close()
		print("Puzzle saved to ", SAVE_PATH)
	else:
		push_error("Game -> game_script.gd -> Could not open file for writing: " + SAVE_PATH)

func load_puzzle() -> void:
	print("Game -> game_script.gd -> load_puzzle()")
	if not FileAccess.file_exists(SAVE_PATH):
		push_error("Game -> game_script.gd -> No saved puzzle found at " + SAVE_PATH)
		return
	print(" Loading save image")
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var state = file.get_var()
	file.close()

	if state == null or not state.has("grid") or not state.has("image_bytes"):
		push_error("Game -> game_script.gd -> Save file is corrupt or in an unexpected format.")
		return

	num_columns = state.get("num_columns", num_columns)
	num_rows = state.get("num_rows", num_rows)

	# Restore the full reference image (used by the preview popup).
	var img_bytes : PackedByteArray = state["image_bytes"]
	if img_bytes.size() > 0:
		var full_img := Image.new()
		if full_img.load_png_from_buffer(img_bytes) == OK:
			puzzle_image = full_img
			# Need to resize here to puzzle size and save
			full_img.resize(1152,648)
			print(" Emitting change puzzle image ")
			change_puzzle_image.emit(ImageTexture.create_from_image(full_img))
		else:
			push_error("Game -> game_script.gd -> Could not decode saved reference image.")

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
		var tex_bytes : PackedByteArray = piece_data.get("tex_bytes", PackedByteArray())

		var piece_tex : Texture2D = null
		if tex_bytes.size() > 0:
			var piece_img := Image.new()
			if piece_img.load_png_from_buffer(tex_bytes) == OK:
				piece_tex = ImageTexture.create_from_image(piece_img)
			else:
				push_error("Game -> game_script.gd -> Could not decode saved piece texture at slot " + str(slot_idx))

		var texture_id : int = piece_data.get("current_texture_id", slot_idx)
		_build_piece(grid, slot_idx, piece_tex, texture_id, piece_width, piece_height, piece_script)

	print("Game -> game_script.gd -> Puzzle loaded from ", SAVE_PATH)
