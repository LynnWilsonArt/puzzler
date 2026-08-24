extends Node2D

@export var num_columns : int = 4
@export var num_rows    : int = 4
@export var grid_size   : Vector2 = Vector2(1152, 648)
@export var image_url   : String = "https://puzzler.lynnwilsonart.com/1951Puzzles/whimiscal/p1.jpg"

var pieces : Array[Texture2D] = []
var first_selected_piece : TextureRect = null
var swapping : bool = false

var http_request : HTTPRequest

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	# FIXED: Godot 4 direct signal connection syntax
	http_request.request_completed.connect(_on_request_completed)

	if image_url == "":
		push_error("You forgot to set image_url.")
		return

	var err = http_request.request(image_url)
	if err != OK:
		push_error("HTTPRequest failed: %s" % err)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		push_error("Download failed, HTTP %d" % response_code)
		return

	var img = Image.new()
	var err = img.load_jpg_from_buffer(body)    # Keep as load_png_from_buffer if using PNGs
	if err != OK:
		push_error("Image load error: %s" % err)
		return

	img.convert(Image.FORMAT_RGBA8)
	var tex = ImageTexture.create_from_image(img)
	_slice_image(tex)
	_randomize_pieces()
	_place_pieces_on_grid()

func _slice_image(tex : Texture2D) -> void:
	pieces.clear()
	var img = tex.get_image()
	img.resize(grid_size.x, grid_size.y)
	var pw = float(img.get_width())  / num_columns
	var ph = float(img.get_height()) / num_rows

	for r in range(num_rows):
		for c in range(num_columns):
			var rect = Rect2i(int(c*pw), int(r*ph), int(pw), int(ph))
			var piece_img = img.get_region(rect)
			var piece_tex = ImageTexture.create_from_image(piece_img)
			pieces.append(piece_tex)

func _randomize_pieces() -> void:
	pieces.shuffle()

func _place_pieces_on_grid() -> void:
	var grid : GridContainer = $HUD/GridContainer
	grid.columns = num_columns
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)

	# Clean old pieces
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	var piece_width = grid_size.x / num_columns
	var piece_height = grid_size.y / num_rows
	var piece_script = load("res://scene/scripts/puzzle_piece_swap.gd")

	# Add new pieces
	for tex in pieces:
		var rect = TextureRect.new()
		rect.texture = tex
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Godot 4 sizing defaults for Grid layouts
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.custom_minimum_size = Vector2(piece_width, piece_height)
		
		rect.set_script(piece_script)
		
		# FIXED: Connect using Godot 4 custom signal syntax
		rect.piece_clicked.connect(_on_piece_clicked)
		grid.add_child(rect)

# ----------  SWAP LOGIC  ----------
func _on_piece_clicked(piece : TextureRect) -> void:
	if swapping:
		return

	if first_selected_piece == null:
		first_selected_piece = piece
		# Optional: Dim selection visual cue
		first_selected_piece.modulate = Color(0.8, 0.8, 1.0, 1.0)
		return

	if first_selected_piece == piece:
		first_selected_piece.modulate = Color.WHITE
		first_selected_piece = null
		return

	# Second click – start animated swap
	swapping = true
	var p1 = first_selected_piece
	var p2 = piece
	first_selected_piece = null
	
	p1.modulate = Color.WHITE

	# Track active transitions using a shared Lambda counter
	var state = {"finished": 0}
	
	# FIXED: Replaced nested function definition with a clean, scoped Callable lambda
	var finish_callback = func():
		state["finished"] += 1
		if state["finished"] == 2:
			# Execute physical layout swap post-animation
			var tmp = p1.texture
			p1.texture = p2.texture
			p2.texture = tmp
			swapping = false

	# Fire both animations
	p1.animate_swap(p2, finish_callback)
	p2.animate_swap(p1, finish_callback)
