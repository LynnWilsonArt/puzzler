extends Node2D

# ------------------------------------------------------------------
# 1️⃣  URLs of the four PNGs on your server
# ------------------------------------------------------------------
const IMAGE_URLS = [
	"https://puzzler.lynnwilsonart.com/ads/banner/1.png",
	"https://puzzler.lynnwilsonart.com/ads/banner/2.png",
	"https://puzzler.lynnwilsonart.com/ads/banner/3.png",
	"https://puzzler.lynnwilsonart.com/ads/banner/4.png",
	"https://puzzler.lynnwilsonart.com/ads/banner/5.png"
]

# ------------------------------------------------------------------
# 2️⃣  Runtime variables
# ------------------------------------------------------------------
var _textures : Array = []          # Holds ImageTexture objects in URL order
var _current_index : int = 0        # Which image is currently shown
var _downloaded_count : int = 0     # How many images have finished downloading

# Queue of URLs that are waiting to be fetched
var _request_queue : Array[String] = []
# Flag that tells us whether we’re already in the middle of a request
var _is_requesting : bool = false
# Index of the URL currently being requested (used for fallback)
var _current_request_index : int = -1

# ------------------------------------------------------------------
# 3️⃣  Called when the scene is ready
# ------------------------------------------------------------------
func _ready() -> void:
	# Connect signals using Callable (GDScript 4 syntax)
	$HTTPRequest.connect("request_completed", Callable(self, "_on_request_completed"))
	$Timer.connect("timeout", Callable(self, "_on_timer_timeout"))

	# Prepare the textures array so we can assign by index later
	_textures.resize(IMAGE_URLS.size())

	# Enqueue all URLs – we’ll start them one by one
	for url in IMAGE_URLS:
		_request_queue.append(url)

	# Timer is *not* started yet – we wait until *all* images are ready.
	$Timer.wait_time = 8.0
	$Timer.one_shot = false

	# Kick off the first request
	_try_start_next()

# ------------------------------------------------------------------
# 4️⃣  Helper that starts the next queued request (if any)
# ------------------------------------------------------------------
func _try_start_next() -> void:
	# If we’re already in the middle of a request, do nothing
	if _is_requesting:
		return

	# No URLs waiting – nothing to do
	if _request_queue.is_empty():
		return

	# Grab the next URL and fire it off
	var url = _request_queue.pop_front()
	_current_request_index = IMAGE_URLS.find(url)
	var err = $HTTPRequest.request(url)

	if err == OK:
		_is_requesting = true
	else:
		# If request() failed (e.g. ERR_BUSY), put the URL back on the queue
		_request_queue.push_front(url)
		_is_requesting = false

# ------------------------------------------------------------------
# 5️⃣  HTTPRequest callback – called for every finished download
# ------------------------------------------------------------------
func _on_request_completed(result: int, response_code: int,
	_headers: PackedStringArray, body: PackedByteArray) -> void:

	# Mark that we’re no longer busy – next request can start
	_is_requesting = false

	var tex : ImageTexture

	if result == OK and response_code == 200:
		# Convert the raw PNG bytes into an ImageTexture
		var img = Image.new()
		var err = img.load_png_from_buffer(body)
		if err == OK:
			tex = ImageTexture.create_from_image(img)
		else:
			push_error("Failed to load image from buffer – falling back to local file")
	else:
		push_error("HTTP request failed (code %d) – falling back to local file" % response_code)

	# If we couldn't create a texture from the network data, try local fallback
	if tex == null:
		tex = _load_local_image(_current_request_index)
		if tex == null:
			push_error("Failed to load local fallback image for index %d" % _current_request_index)
			# Create an empty placeholder to keep array size consistent
			tex = ImageTexture.new()

	# Store the texture at the correct index
	_textures[_current_request_index] = tex

	# Keep track of how many we have finished
	_downloaded_count += 1

	# When *all* images are ready, start the animation
	if _downloaded_count == IMAGE_URLS.size():
		_start_animation()

	# Start the next queued request (if any)
	_try_start_next()

# ------------------------------------------------------------------
# 6️⃣  Load a local image from res://assets/Ads/<index+1>.png
# ------------------------------------------------------------------
func _load_local_image(index: int) -> ImageTexture:
	var path = "res://assets/Ads/%d.png" % (index + 1)
	var tex_res = load(path)
	if tex_res is Texture2D:
		var img = tex_res.get_image()
		return ImageTexture.create_from_image(img)
	push_error("Unable to load local image '%s'" % path)
	return null

# ------------------------------------------------------------------
# 7️⃣  Start the timer once all textures are loaded
# ------------------------------------------------------------------
func _start_animation() -> void:
	print("Animation has started.")
	if _textures.is_empty():
		push_error("No textures to animate")
		return

	# Show the first image immediately
	$Sprite.texture = _textures[0]
	_current_index = 0

	# Start the timer – it will fire every 8 seconds
	$Timer.start()

# ------------------------------------------------------------------
# 8️⃣  Timer callback – switch to the next image
# ------------------------------------------------------------------
func _on_timer_timeout() -> void:
	if _textures.is_empty():
		return

	# Advance index (wrap around)
	_current_index = (_current_index + 1) % _textures.size()
	$Sprite.texture = _textures[_current_index]
