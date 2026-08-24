extends Node2D

@export var num_columns : int = 4
@export var num_rows    : int = 4
@export var grid_size   : Vector2 = Vector2(1152, 648)
@export var image_url   : String = "https://puzzler.lynnwilsonart.com/1951Puzzles/whimiscal/p1.jpg"

var pieces : Array[Texture2D] = []
var first_selected_piece : TextureRect = null

var http_request : HTTPRequest

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))

	if image_url == "":
		push_error("You forgot to set image_url.")
		return

	var err = http_request.request(image_url)
	if err != OK:
		push_error("HTTPRequest failed: %s" % err)

func _on_request_completed(_result, response_code, _headers, body) -> void:
	if response_code != 200:
		push_error("Download failed, HTTP %d" % response_code)
		return

	var img = Image.new()
	var err = img.load_jpg_from_buffer(body)    # use JPG loader if your image is JPG
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

	# Remove old children
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	# Add new children
	for tex in pieces:
		var rect = TextureRect.new()
		rect.texture = tex
		rect.mouse_filter = Control.MOUSE_FILTER_STOP

		# Attach our click script
		rect.set_script(load("res://scene/scripts/puzzle_piece_swap.gd"))

		# Connect the click signal
		rect.connect("piece_clicked", Callable(self, "_on_piece_clicked"))

		grid.add_child(rect)

# ----------  SWAP LOGIC  ----------

func _on_piece_clicked(piece : TextureRect) -> void:
	if first_selected_piece == null:
		first_selected_piece = piece
		return

	# Second click – swap the textures
	var tmp = first_selected_piece.texture
	first_selected_piece.texture = piece.texture
	piece.texture = tmp

	# Reset for the next turn
	first_selected_piece = null
