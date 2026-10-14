# res://Scenes/Ads/banner.gd
extends Node2D

@onready var http_request : HTTPRequest = $HTTPRequest
@onready var timer : Timer = $Timer
@onready var sprite : Sprite2D = $Sprite

const BASE_URL : String = "https://images.lynnwilsonart.com/banners/"
const CACHE_DIR : String = "user://banner_cache/"

# Default fallback values if config loading fails
var NUM_IMAGES : int = 5
const REFRESH_INTERVAL : float = 86400.0 # 24 hours in seconds
const IMAGE_DISPLAY_TIME : float = 10.0   # Seconds each image stays on screen

var image_urls : Array[String] = []
var textures : Array[Texture2D] = []
var current_index : int = 0
var downloaded_count : int = 0

var request_queue : Array[String] = []
var is_requesting : bool = false
var current_request_index : int = -1
var config_data: ConfigLoader = ConfigLoader.new()

# ------------------------------------------------------------------
# 1️⃣ Setup on ready
# ------------------------------------------------------------------
func _ready() -> void:
	print("Banner -> _ready()")

	# Modern Godot 4 signal connections
	http_request.request_completed.connect(_on_request_completed)
	timer.timeout.connect(_on_timer_timeout)
	
	# Connect config loader signals
	config_data.config_loaded.connect(_on_config_loaded)
	config_data.config_failed.connect(_on_config_failed)
	
	# Safely add ConfigLoader to the tree on the next frame
	add_child.call_deferred(config_data)

	# Ensure cache directory exists
	_ensure_cache_directory()

	# Build initial URLs based on default count before config overrides
	_rebuild_urls()
	textures.resize(NUM_IMAGES)
	_queue_all_images()
	_try_start_next()

# ------------------------------------------------------------------
# Helper: Rebuild URL array based on NUM_IMAGES
# ------------------------------------------------------------------
func _rebuild_urls() -> void:
	image_urls.clear()
	for i in range(NUM_IMAGES):
		image_urls.append(BASE_URL + str(i + 1) + ".png")

# ------------------------------------------------------------------
# Helper: Ensure cache directory exists
# ------------------------------------------------------------------
func _ensure_cache_directory() -> void:
	var err = DirAccess.make_dir_absolute(CACHE_DIR)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("Failed to create cache directory: %s" % err)

# ------------------------------------------------------------------
# Helper: Clear the cache directory safely
# ------------------------------------------------------------------
func _clear_cache_directory() -> void:
	var err: int = OK
	
	if DirAccess.dir_exists_absolute(CACHE_DIR):
		for file in DirAccess.get_files_at(CACHE_DIR):
			var full_path = CACHE_DIR + file
			err = DirAccess.remove_absolute(full_path)
			if err != OK:
				push_error("Failed to delete old cache file: %s" % full_path)
		print("Cache directory successfully cleared.")
	
	_ensure_cache_directory()

# ------------------------------------------------------------------
# 2️⃣ Queue every URL for download / cache check
# ------------------------------------------------------------------
func _queue_all_images() -> void:
	print("Banner -> _queue_all_images()")
	request_queue.clear()
	for url in image_urls:
		request_queue.append(url)

# ------------------------------------------------------------------
# 3️⃣ Start the next queued request (System-Time Cache Validation)
# ------------------------------------------------------------------
func _try_start_next() -> void:
	if is_requesting or request_queue.is_empty():
		return

	var url = request_queue.pop_front()
	current_request_index = image_urls.find(url)

	var cache_path = CACHE_DIR + str(current_request_index + 1) + ".png"
	
	if FileAccess.file_exists(cache_path):
		var mod_time = FileAccess.get_modified_time(cache_path)
		var current_time = Time.get_unix_time_from_system()
		
		# Check system time to see if refresh interval has passed since file was cached
		if current_time < (mod_time + REFRESH_INTERVAL):
			# Cache is still valid! Use cached image.
			var tex = _load_local_image(cache_path)
			if tex != null:
				if current_request_index >= textures.size():
					textures.resize(current_request_index + 1)
				
				textures[current_request_index] = tex
				downloaded_count += 1
				if downloaded_count >= NUM_IMAGES:
					_start_animation()
				
				_try_start_next()
				return
		else:
			print("Cache expired for image %d based on system time. Re-downloading..." % (current_request_index + 1))

	# Cache missing or expired – download from network
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
	print("Banner -> _on_request_completed()")
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

	# Safeguard against out-of-bounds array assignments during async callbacks
	if current_request_index >= textures.size():
		textures.resize(current_request_index + 1)

	textures[current_request_index] = tex
	downloaded_count += 1

	if downloaded_count >= NUM_IMAGES:
		_start_animation()

	_try_start_next()

# ------------------------------------------------------------------
# 5️⃣ Load a local image
# ------------------------------------------------------------------
func _load_local_image(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
		
	var img = Image.load_from_file(path)
	if img != null:
		return ImageTexture.create_from_image(img)
		
	push_error("Failed to load image from file '%s'" % path)
	return null

# ------------------------------------------------------------------
# 6️⃣ Start the banner animation & system-time expiration checker
# ------------------------------------------------------------------
func _start_animation() -> void:
	print("Banner -> _start_animation()")
	if textures.is_empty():
		push_error("No textures to animate")
		return

	sprite.texture = textures[0]
	current_index = 0

	# Show each image for IMAGE_DISPLAY_TIME seconds
	timer.wait_time = IMAGE_DISPLAY_TIME
	timer.start()

	# Background timer to periodically check if system time has crossed expiration threshold
	if not has_node("CacheCheckTimer"):
		var cache_check_timer = Timer.new()
		cache_check_timer.name = "CacheCheckTimer"
		cache_check_timer.wait_time = 1800.0 # Check every 30 minutes
		cache_check_timer.autostart = true
		cache_check_timer.timeout.connect(_check_cache_expiration_system_time)
		add_child(cache_check_timer)

func _check_cache_expiration_system_time() -> void:
	var first_cache = CACHE_DIR + "1.png"
	if not FileAccess.file_exists(first_cache):
		return
		
	var mod_time = FileAccess.get_modified_time(first_cache)
	var current_time = Time.get_unix_time_from_system()
	
	if current_time >= (mod_time + REFRESH_INTERVAL):
		print("System time check: Cache expired! Clearing and refreshing...")
		_clear_cache_directory()
		_refresh_cache()

# ------------------------------------------------------------------
# 7️⃣ Timer callback – switch to next image
# ------------------------------------------------------------------
func _on_timer_timeout() -> void:
	if textures.is_empty():
		return

	current_index = (current_index + 1) % textures.size()
	sprite.texture = textures[current_index]

# ------------------------------------------------------------------
# 8️⃣ Re‑download all images
# ------------------------------------------------------------------
func _refresh_cache() -> void:
	print("Banner -> _refresh_cache()")
	downloaded_count = 0
	textures.resize(NUM_IMAGES)
	_queue_all_images()
	_try_start_next()

# ------------------------------------------------------------------
# Config Data Loaded Successfully
# ------------------------------------------------------------------
func _on_config_loaded(data: Dictionary) -> void:
	print("Config Loaded Successfully: ", data)
	
	var new_num_banners = int(data.get("number_banners", NUM_IMAGES))
	
	# If banner count dropped, clean up obsolete cached files
	if new_num_banners < NUM_IMAGES:
		for i in range(new_num_banners + 1, NUM_IMAGES + 1):
			var old_cache_path = CACHE_DIR + str(i) + ".png"
			if FileAccess.file_exists(old_cache_path):
				DirAccess.remove_absolute(old_cache_path)
				print("Removed obsolete cache file: ", old_cache_path)

	NUM_IMAGES = new_num_banners
	_rebuild_urls()
	textures.resize(NUM_IMAGES)
	downloaded_count = 0
	
	_queue_all_images()
	_try_start_next()

# ------------------------------------------------------------------
# Config Data Failed to Load
# ------------------------------------------------------------------
func _on_config_failed(error_message: String) -> void:
	push_warning("Config load failed (%s). Continuing with existing banner count: %d" % [error_message, NUM_IMAGES])
