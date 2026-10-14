# res://Scenes/Ads/banner.gd
extends Node2D

@onready var http_request : HTTPRequest = $HTTPRequest
@onready var timer : Timer = $Timer
@onready var sprite : Sprite2D = $Sprite

const BASE_URL : String = "https://images.lynnwilsonart.com/ads/banner/"
const CACHE_DIR : String = "user://banner_cache/"
const NUM_IMAGES : int = 5

# Cache lifetime – 24 hours = 86400 seconds
const REFRESH_INTERVAL : float = Globals.CACHE_REFRESH_INTERVAL

# How long each image stays on screen – 5 minutes = 300 seconds
const IMAGE_DISPLAY_TIME : float = Globals.BANNER_REFRESH_INTERVAL

var image_urls : Array[String] = []
var textures : Array[Texture2D] = []
var current_index : int = 0
var downloaded_count : int = 0

var request_queue : Array[String] = []
var is_requesting : bool = false
var current_request_index : int = -1

# ------------------------------------------------------------------
# 1️⃣ Setup on ready
# ------------------------------------------------------------------
func _ready() -> void:
	print("[Banner] -> _ready()")

	# Modern Godot 4 signal connections
	http_request.request_completed.connect(_on_request_completed)
	timer.timeout.connect(_on_timer_timeout)

	var err = DirAccess.make_dir_absolute(CACHE_DIR)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("Failed to create cache directory: %s" % err)

	# Build URLs
	for i in range(NUM_IMAGES):
		image_urls.append(BASE_URL + str(i + 1) + ".png")

	textures.resize(NUM_IMAGES)
	_queue_all_images()
	_try_start_next()

# ------------------------------------------------------------------
# 2️⃣ Queue every URL for download / cache check
# ------------------------------------------------------------------
func _queue_all_images() -> void:
	print("[Banner] -> _queue_all_images()")
	request_queue.clear()
	for url in image_urls:
		request_queue.append(url)

# ------------------------------------------------------------------
# 3️⃣ Start the next queued request (or use cache)
# ------------------------------------------------------------------
func _try_start_next() -> void:
	print("[Banner] -> _try_start_next()")
	if is_requesting or request_queue.is_empty():
		return

	var url = request_queue.pop_front()
	current_request_index = image_urls.find(url)

	var cache_path = CACHE_DIR + str(current_request_index + 1) + ".png"
	if FileAccess.file_exists(cache_path):
		var mod_time = FileAccess.get_modified_time(cache_path)
		var now = Time.get_unix_time_from_system()
		if now - mod_time < REFRESH_INTERVAL:
			# Use cached image
			textures[current_request_index] = _load_local_image(cache_path)
			downloaded_count += 1
			if downloaded_count == NUM_IMAGES:
				_start_animation()
			
			# Continue processing the rest of the queue on cache hit
			_try_start_next()
			return

	# No valid cache – download from network
	var err = http_request.request(url)
	if err == OK:
		print("Requesting image from server: ", url)
		is_requesting = true
	else:
		push_error("Failed to request %s: %s" % [url, err])
		is_requesting = false
		_try_start_next()

# ------------------------------------------------------------------
# 4️⃣ Handle HTTP responses (images only)
# ------------------------------------------------------------------
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("[Banner] -> _on_request_completed()")
	is_requesting = false

	var tex : Texture2D = null
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var img = Image.new()
		var err = img.load_png_from_buffer(body)
		if err == OK:
			tex = ImageTexture.create_from_image(img)
			
			# Cache the successfully downloaded PNG
			var cache_path = CACHE_DIR + str(current_request_index + 1) + ".png"
			var file = FileAccess.open(cache_path, FileAccess.WRITE)
			if file:
				file.store_buffer(body)
				file.close()
			else:
				push_error("Could not write cache file: %s" % cache_path)
		else:
			push_error("Failed to parse PNG buffer for index %d" % current_request_index)

	if tex == null:
		# Fallback to local asset path in res://
		var fallback_path = "res://Assets/Ads/fallback_%d.png" % (current_request_index + 1)
		tex = _load_local_image(fallback_path)
		if tex == null:
			push_error("Could not load fallback for index %d. Using PlaceholderTexture2D." % current_request_index)
			var placeholder = PlaceholderTexture2D.new()
			placeholder.size = Vector2(200, 50)
			tex = placeholder

	textures[current_request_index] = tex
	downloaded_count += 1

	if downloaded_count == NUM_IMAGES:
		_start_animation()

	_try_start_next()

# ------------------------------------------------------------------
# 5️⃣ Load a local image (from cache or res://assets) — FIXED STATIC CALL
# ------------------------------------------------------------------
func _load_local_image(path: String) -> Texture2D:
	print("[Banner] -> _load_local_image(): ", path)
	if not FileAccess.file_exists(path):
		return null
		
	# Correct static call to Image.load_from_file()
	var img = Image.load_from_file(path)
	if img != null:
		return ImageTexture.create_from_image(img)
		
	push_error("Failed to load image from file '%s'" % path)
	return null

# ------------------------------------------------------------------
# 6️⃣ Start the banner animation
# ------------------------------------------------------------------
func _start_animation() -> void:
	print("[Banner] -> _start_animation()")
	if textures.is_empty():
		push_error("No textures to animate")
		return

	sprite.texture = textures[0]
	current_index = 0

	# Show each image for IMAGE_DISPLAY_TIME seconds
	timer.wait_time = IMAGE_DISPLAY_TIME
	timer.start()

	# After the whole cycle, refresh the cache every REFRESH_INTERVAL seconds
	get_tree().create_timer(REFRESH_INTERVAL).timeout.connect(_refresh_cache)

# ------------------------------------------------------------------
# 7️⃣ Timer callback – switch to next image
# ------------------------------------------------------------------
func _on_timer_timeout() -> void:
	if textures.is_empty():
		return

	current_index = (current_index + 1) % textures.size()
	sprite.texture = textures[current_index]

# ------------------------------------------------------------------
# 8️⃣ Re‑download all images (overwrite cache)
# ------------------------------------------------------------------
func _refresh_cache() -> void:
	print("[Banner] -> _refresh_cache()")
	downloaded_count = 0
	textures.resize(NUM_IMAGES)
	_queue_all_images()
	_try_start_next()
