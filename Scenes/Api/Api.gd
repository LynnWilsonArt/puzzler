# res://Singletons/Api.gd
extends Node

signal request_started
signal progress_updated(percent: float)
signal image_ready(texture: ImageTexture, photographer: String)
signal request_failed(error_message: String)

const BASE_URL = "https://images.lynnwilsonart.com/fetch_pixabay.php"
const PASSCODE = "Topp3r@19511969!"

var http_meta_request : HTTPRequest
var http_image_request : HTTPRequest

var current_photographer : String = ""

func _ready() -> void:
	http_meta_request = HTTPRequest.new()
	add_child(http_meta_request)
	http_meta_request.max_redirects = 8
	http_meta_request.request_completed.connect(_on_meta_request_completed)

	http_image_request = HTTPRequest.new()
	add_child(http_image_request)
	http_image_request.max_redirects = 8
	http_image_request.request_completed.connect(_on_image_request_completed)

func fetch_puzzle_image(category_name: String) -> void:
	request_started.emit()
	progress_updated.emit(10.0)
	print("Api -> Requesting image metadata for category: ", category_name)
	http_meta_request.cancel_request()

	# 1. Pack sensitive data into the POST body securely using proper String.join() syntax
	var body = "&".join([
		"passcode=" + PASSCODE,
		"category=" + category_name
	])

	# 2. Set headers including your requested Accept format and form-urlencoded type
	var headers = PackedStringArray([
		"Content-Type: application/x-www-form-urlencoded",
		"Accept: application/json, text/plain, */*",
        "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) GodotEngine/4.7"
	])

	# 3. Send using METHOD_POST
	var err = http_meta_request.request(BASE_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("Api -> Failed to send HTTP request: " + str(err))
		call_deferred("_emit_failed", "HTTP Request initialization failed (Code: " + str(err) + ")")

func _emit_failed(msg: String) -> void:
	request_failed.emit(msg)

func _on_meta_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Api -> Meta Request Completed. Result: ", result, " | HTTP Status: ", response_code)

	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Api -> Meta Request network error result code: " + str(result))
		request_failed.emit("Network error occurred (Result: " + str(result) + ").")
		return

	if response_code != 200 or body.size() == 0:
		push_error("Api -> Meta request failed with response code: " + str(response_code))
		request_failed.emit("Server returned response code " + str(response_code))
		return

	progress_updated.emit(30.0)
	var json_str = body.get_string_from_utf8()
	var json = JSON.new()
	if json.parse(json_str) != OK:
		push_error("Api -> Failed to parse JSON response: " + json_str)
		request_failed.emit("Invalid server response.")
		return

	var data = json.get_data()
	if data.get("status", "") != "success":
		var msg = data.get("message", "Unknown error from server.")
		push_error("Api -> Server returned error: " + msg)
		request_failed.emit(msg)
		return

	var image_url = data.get("image_url", "")
	current_photographer = data.get("photographer", "Lynn Wilson Art")

	if image_url == "":
		request_failed.emit("No image URL provided by server.")
		return

	print("Api -> Metadata received. Fetching raw image from: ", image_url)
	progress_updated.emit(50.0)

	http_image_request.cancel_request()
	var img_headers = PackedStringArray([
        "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) GodotEngine/4.7"
	])
	var err = http_image_request.request(image_url, img_headers)
	if err != OK:
		push_error("Api -> Failed to send HTTP image request. Godot Error Code: " + str(err))
		call_deferred("_emit_failed", "Failed to start image download (Code: " + str(err) + ")")

func _on_image_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Api -> Image Download Completed. Result: ", result, " | HTTP Status: ", response_code, " | Payload Bytes: ", body.size())

	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Api -> Image request network error result: " + str(result))
		request_failed.emit("Failed to download image payload.")
		return

	if response_code != 200 or body.size() == 0:
		push_error("Api -> Image payload request failed with HTTP status: " + str(response_code))
		request_failed.emit("Failed to download image payload (HTTP " + str(response_code) + ").")
		return

	progress_updated.emit(90.0)
	var img := Image.new()
	var err = OK

	if img.has_method("load_from_buffer"):
		err = img.load_from_buffer(body)
	else:
		err = img.load_jpg_from_buffer(body)
		if err != OK:
			err = img.load_png_from_buffer(body)
		if err != OK:
			err = img.load_webp_from_buffer(body)

	if err != OK:
		push_error("Api -> Failed to decode image buffer. Error code: " + str(err))
		request_failed.emit("Corrupted image format received.")
		return

	progress_updated.emit(100.0)
	var tex = ImageTexture.create_from_image(img)
	image_ready.emit(tex, current_photographer)
