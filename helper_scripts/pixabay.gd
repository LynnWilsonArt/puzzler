extends Node

signal image_ready(texture: ImageTexture, photographer: String)

@onready var pixabay_request: HTTPRequest = $PixabayRequest
@onready var image_downloader: HTTPRequest = $ImageDownloader

# Using your verified working API Key
const API_KEY: String = "25066829-e19f4bd20795e793e3349ffe7"

# Holds the photographer name between the metadata request and the
# follow-up image download request (two separate async calls).
var _pending_photographer: String = ""

func _ready() -> void:
	print("Pixabay -> _ready()")
	pixabay_request.request_completed.connect(_on_pixabay_request_completed)
	image_downloader.request_completed.connect(_on_image_download_completed)

func fetch_puzzle_image(search_query: String) -> void:
	print("Pixabay -> fetch_puzzle_image()")
	# Encodes spaces (like converting "yellow flowers" into "yellow+flowers") safely for the web
	var cleaned_query = search_query.strip_edges().uri_encode()
	var url = "https://pixabay.com/api/?key=" + API_KEY + "&q=" + cleaned_query + "&image_type=photo&safesearch=true&per_page=10"
	print("Pixabay -> Sending Request: ", url)
	var error = pixabay_request.request(url)
	if error != OK:
		print("An error occurred making the API metadata request. Error code: ", error)

func _on_pixabay_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Pixabay -> _on_pixabay_request_completed()")
	if response_code != 200:
		print("Failed to reach Pixabay API. Response Code: ", response_code)
		$NoInternetPopup.show()
		return
	var raw_text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_err = json.parse(raw_text)
	if parse_err == OK:
		var response = json.get_data()
		var hits = response.get("hits", [])
		if hits.size() > 0:
			# Pick a random photo matching your search terms from the pool
			var random_hit = hits[randi() % hits.size()]
			var image_url = random_hit.get("largeImageURL")

			# Pixabay's API returns the uploader's username in the "user" field.
			_pending_photographer = random_hit.get("user", "Unknown")

			print("✅ Metadata verified! Target URL: ", image_url, " | Photographer: ", _pending_photographer)
			image_downloader.request(image_url)
		else:
			print("No images matched your query criteria.")
	else:
		print("Failed to parse incoming JSON metadata. Raw output: ", raw_text)

func _on_image_download_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Pixabay -> _on_image_download_completed()")
	if response_code != 200:
		print("Failed to download raw image file payload. Response Code: ", response_code)
		return
	var img = Image.new()
	var error = img.load_jpg_from_buffer(body)
	img.convert(Image.FORMAT_RGBA8)
	if error == OK:
		var texture: Texture2D = ImageTexture.create_from_image(img)
		print("🎉 Texture successfully compiled! Emitting 'image_ready' signal. Photographer: ", _pending_photographer)
		image_ready.emit(texture, _pending_photographer)
	else:
		print("Failed to map buffer data into a valid Engine Image. Error code: ", error)
