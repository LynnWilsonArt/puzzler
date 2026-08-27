extends Node2D
# File: res://scene/game/game_script.gd

signal puzzle_toggle_requested(is_visible: bool)
signal change_puzzle_image(image: Texture2D)
@export var num_columns : int = Globals.columns
@export var num_rows    : int = Globals.rows
@export var grid_size   : Vector2 = Vector2(1152, 648)
@export var game_scene_path : String = "res://scene/end_game/end_game.tscn"
@export var puzzle_image = Image.new()


const SAVE_PATH := "user://puzzle_state.save"

# FIXED: Change to an array of Dictionaries to hold textures alongside their correct indexes
var pieces_data : Array[Dictionary] = []
var first_selected_piece : TextureRect = null
var swapping : bool = false
var http_request : HTTPRequest


func _ready() -> void:
	if Globals.debug:
		print("DEBUG -> game_script.gd ->  _ready()")

	if $Puzzle:
		puzzle_toggle_requested.connect($Puzzle._on_puzzle_toggle_requested)
		change_puzzle_image.connect($Puzzle._on_change_puzzle_image_requested)
		print("✅ Connection Successful: game_scene linked to Puzzle script!")
	else:
		print("❌ Connection Failed: Could not find Puzzle node at path '$Puzzle'")

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.set_use_threads(true)
	http_request.set_max_redirects(5)
	http_request.request_completed.connect(_on_request_completed)

	# Resume a saved puzzle if one exists, otherwise fetch a fresh one.
	if FileAccess.file_exists(SAVE_PATH):
		print("Found saved puzzle — loading instead of fetching a new one.")
		load_puzzle()
	else:
		_on_get_puzzle()
	
	
	# Enable redirect following and background thread usage
func _on_get_puzzle()-> void:
	
		print("DEBUG -> _game_script.gd -> _on_get_puzzle()")

		http_request.set_use_threads(true)
		http_request.set_max_redirects(5) 
	
		http_request.request_completed.connect(_on_request_completed)

		# 1. Define a list of image filenames available on your website directory
		var puzzle_pool: Array[String] = ["p1.jpg", "p2.jpg", "p3.jpg", "p4.jpg", "p5.jpg","p6.jpg"]
	
		# 2. Pick a random entry from your list
		randomize() # Seeds the random number generator
		
		@warning_ignore("unused_variable")
		var random_image_name = puzzle_pool[randi() % puzzle_pool.size()]

		# 3. Combine into your secure server path string
		var random_image_url = "https://picsum.photos/1152/648"
		#var random_image_url = "https://puzzler.lynnwilsonart.com/1951Puzzles/whimiscal/%s" % random_image_name
		print("Fetching custom puzzle artwork from: ", random_image_url)

		var err = http_request.request(random_image_url)
		if err != OK:
			push_error("HTTPRequest failed immediately: %s. Dropping to local fallback." % err)
			# 🎯 CALL IT HERE: Triggers if the game can't even start the web request
					
			_load_local_fallback() 





func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	
	print("DEBUG -> _game_script.gd -> _on_request_completed()")
	# Check if the HTTP request completely failed, timed out, or returned a bad server code
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("⚠️ Network error or file missing (HTTP %d). Loading fallback asset..." % response_code)
		# 🎯 CALL IT HERE: Triggers on website timeouts, bad hosting paths, or offline status codes
		# ToDo: No internet fall back to my website
		# 
		
		# No internet fall to local in app image
		_load_local_fallback()
		return

	
	var img = Image.new()
	
	# Use load_jpg_from_buffer to handle the incoming Picsum web stream stream
	var err = img.load_jpg_from_buffer(body)
	if err != OK:
		# Fallback just in case the server format stream returns PNG format data data bytes
		err = img.load_png_from_buffer(body)
		if err != OK:
			push_error("Image load error: %s" % err)
			return
	# Save image for popup and slice image
	img.convert(Image.FORMAT_RGBA8)
	puzzle_image = img   # save original image
	var tex = ImageTexture.create_from_image(img)
	# Saves the original image for popup
	change_puzzle_image.emit(tex)
	_slice_image(tex)
	_randomize_pieces()
	_place_pieces_on_grid()
	print(" stopped here??")
	
	
	


func _slice_image(tex : Texture2D) -> void:
	
	print("DEBUG -> _game_script.gd ->  _slice_image(tex: Texture2D)")
	
	pieces_data.clear()
	var img = tex.get_image()
	@warning_ignore("narrowing_conversion")
	img.resize(grid_size.x, grid_size.y)
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
	
	print("DEBUG -> _game_script.gd -> _randomize_pieces()")
		
	pieces_data.shuffle()

func _place_pieces_on_grid() -> void:
	
	print("DEBUG -> _game_script.gd ->  _place_pieces_on_grid()")
		
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
	var piece_script = load("res://scene/game/puzzle_piece_swap.gd")

	# FIXED: Track slot positions explicitly from 0 to total pieces
	for slot_idx in range(pieces_data.size()):
		var data = pieces_data[slot_idx]
		_build_piece(grid, slot_idx, data["texture"], data["id"], piece_width, piece_height, piece_script)

# ----------  SHARED PIECE-BUILDING HELPER  ----------
# Used by both _place_pieces_on_grid() (fresh puzzle) and load_puzzle()
# (restored puzzle) so every piece is wired up identically.
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

# ----------  SWAP LOGIC  ----------
func _on_piece_clicked(piece : TextureRect) -> void:
	
	print("DEBUG -> _game_script.gd -> _on_piece_clicked()")
		
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
	
	print("DEBUG -> _game_script.gd -> _check_win_condition()")
		
	var grid : GridContainer = $Puzzle/GridContainer
	
	for rect in grid.get_children():
		if rect is TextureRect:
			var slot_id = rect.get_meta("correct_slot_id")
			var current_tex_id = rect.get_meta("current_texture_id")
			
			# If any single piece does not line up with its slot, stop checking
			if slot_id != current_tex_id:
				return
				
	_trigger_victory()

func _trigger_victory() -> void:
		
	
	print("DEBUG -> _game_script.gd -> _trigger_victory()")
		
	print("Puzzle Complete! All pieces are in the correct place!")
	# Disable interaction entirely
	swapping = true 
	print("emitted signal")
	puzzle_toggle_requested.emit(true)
	
	if game_scene_path != "":
		# Switch directly via the file string path
		var error_code = get_tree().change_scene_to_file(game_scene_path)
		
		# Check if Godot ran into an error while transitioning
		if error_code != OK:
			push_error("Failed to switch scenes! Error code: ", error_code)

			
func _load_local_fallback() -> void:
	
	print("DEBUG -> _game_script.gd -> _load_local_fallback() -> internet or website unreachablle")
		
	print("📦 Network down or file missing. Scanning local assets for a random puzzle image...")
	
	# UPDATED: Path shifted to your puzzle_images subdirectory
	var folder_path = "res://assets/puzzle_images/"
	var dir = DirAccess.open(folder_path)
	
	if not dir:
		push_error("❌ Critical Error: Cannot open or find local assets folder at: " + folder_path)
		return
		
	var local_images: Array[String] = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# Ensure we only pick files and ignore directories
		if not dir.current_is_dir():
			# Filter for image extensions (case-insensitive checks)
			var ext = file_name.get_extension().to_lower()
			if ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp":
				local_images.append(folder_path + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Check if we actually found any local images to use
	if local_images.is_empty():
		push_error("❌ Critical Error: No valid image assets (.jpg, .png, .webp) found in " + folder_path)
		return
		
	# Pick a random image from our freshly scanned local list
	randomize()
	var chosen_image_path = local_images[randi() % local_images.size()]
	print("🎯 Selected random local asset: ", chosen_image_path)
	
	# Load the selected asset and start the puzzle grid
	var local_tex = load(chosen_image_path) as Texture2D
	if local_tex:
		var img = local_tex.get_image()
		_process_and_start_game(img)
	else:
		push_error("❌ Critical Error: Failed to load local asset texture: " + chosen_image_path)
			
func _process_and_start_game(img: Image) -> void:
	img.convert(Image.FORMAT_RGBA8)
	var tex = ImageTexture.create_from_image(img)
		# Saves the original image for popup
	change_puzzle_image.emit(tex)
	_slice_image(tex)
	_randomize_pieces()
	_place_pieces_on_grid()


# ======================================================================
# SAVE / LOAD — persists the CURRENT grid arrangement (not the original
# shuffle), so resuming puts every piece back exactly where you left it,
# fully clickable and swappable.
# ======================================================================
func save_puzzle() -> void:
	var grid : GridContainer = $Puzzle/GridContainer
	if grid.get_child_count() == 0:
		push_error("Nothing to save — grid is empty.")
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
		push_error("Could not open file for writing: " + SAVE_PATH)


func load_puzzle() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		push_error("No saved puzzle found at " + SAVE_PATH)
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var state = file.get_var()
	file.close()

	if state == null or not state.has("grid") or not state.has("image_bytes"):
		push_error("Save file is corrupt or in an unexpected format.")
		return

	num_columns = state.get("num_columns", num_columns)
	num_rows = state.get("num_rows", num_rows)

	# Restore the full reference image (used by the preview popup).
	var img_bytes : PackedByteArray = state["image_bytes"]
	if img_bytes.size() > 0:
		var full_img := Image.new()
		if full_img.load_png_from_buffer(img_bytes) == OK:
			puzzle_image = full_img
			change_puzzle_image.emit(ImageTexture.create_from_image(full_img))
		else:
			push_error("Could not decode saved reference image.")

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
	var piece_script = load("res://scene/game/puzzle_piece_swap.gd")

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
				push_error("Could not decode saved piece texture at slot " + str(slot_idx))

		var texture_id : int = piece_data.get("current_texture_id", slot_idx)
		_build_piece(grid, slot_idx, piece_tex, texture_id, piece_width, piece_height, piece_script)

	print("Puzzle loaded from ", SAVE_PATH)
