extends Node

@export var upload_url: String = "https://images.lynnwilsonart.com/upload.php"

func _ready() -> void:
	print("File: ", Globals.SAVE_PATH)


# Send puzzle image to server
func _on_send_puzzle() -> void:
	var file_path = Globals.SAVE_PATH
	
	if not FileAccess.file_exists(file_path):
		print("Save file does not exist: ", file_path)
		return
	
	# 1. Load the save file data dictionary
	var file = FileAccess.open(file_path, FileAccess.READ)
	var state = file.get_var()
	file.close()
	
	if typeof(state) != TYPE_DICTIONARY or not state.has("image_bytes"):
		print("Save file format is invalid or missing image data.")
		return
		
	var image_bytes: PackedByteArray = state.get("image_bytes")
	if image_bytes.is_empty():
		print("The image bytes inside the save file are empty.")
		return
	
	# Extract the photographer name saved in the state dictionary
	var photographer_name = state.get("photographer", "")
	var credit_text = "Photo by: " + photographer_name + " - Find them on pixabay.com" if photographer_name != "" else "Image Provided By Pixabay.com"
	
	var img = Image.new()
	if img.load_png_from_buffer(image_bytes) != OK:
		print("Failed to load image from save buffer.")
		return
		
	# --- 2. OVERLAY PHOTOGRAPHER TEXT USING A SUBVIEWPORT ---
	var img_size = img.get_size()
	
	var viewport = SubViewport.new()
	viewport.size = img_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	
	var tex_rect = TextureRect.new()
	tex_rect.texture = ImageTexture.create_from_image(img)
	tex_rect.size = img_size
	viewport.add_child(tex_rect)
	
	var label = Label.new()
	label.text = credit_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Position it near the bottom center with a subtle box height
	label.size = Vector2(img_size.x, 60)
	label.position = Vector2(0, img_size.y - 70)
	
	# Clean styling for visibility on images (White text with dark shadow/outline look)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 16)
	viewport.add_child(label)
	
	# Wait a frame for the viewport to render the composite layout
	await RenderingServer.frame_post_draw
	
	# Capture the rendered result back into an Image
	var final_img = viewport.get_texture().get_image()
	viewport.queue_free() # Clean up temporary viewport node
	
	var final_jpg_bytes = final_img.save_jpg_to_buffer(0.9)
	
	# --- 3. BUILD AND SEND HTTP REQUEST ---
	var timestamp = Time.get_unix_time_from_system()
	var filename = "puzzle_image_%d.jpg" % timestamp
	var mime_type = "image/jpeg"
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_HTTPRequest_request_completed)
	
	var boundary: String = "GodotFileUploadBoundary" + str(Time.get_ticks_msec())
	var headers: PackedStringArray = [
		"Content-Type: multipart/form-data; boundary=" + boundary
	]
	
	var body := PackedByteArray()
	var crlf := "\r\n".to_utf8_buffer()
	
	# Add passcode
	var passcode = $LineEdit.text if has_node("LineEdit") else "Topp3r@19511969!"
	body.append_array(("--" + boundary + "\r\n").to_utf8_buffer())
	body.append_array(("Content-Disposition: form-data; name=\"passcode\"\r\n\r\n").to_utf8_buffer())
	body.append_array((passcode + "\r\n").to_utf8_buffer())
	
	# Add the text-stamped JPG image file
	body.append_array(("--" + boundary + "\r\n").to_utf8_buffer())
	body.append_array(("Content-Disposition: form-data; name=\"fileToUpload\"; filename=\"" + filename + "\"\r\n").to_utf8_buffer())
	body.append_array(("Content-Type: " + mime_type + "\r\n\r\n").to_utf8_buffer())
	body.append_array(final_jpg_bytes)
	body.append_array(crlf)
	
	body.append_array(("--" + boundary + "--\r\n").to_utf8_buffer())
	
	var error = http_request.request_raw(upload_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("Error starting request: ", error)
		
func _on_HTTPRequest_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS:
		if _response_code != 200:
			print("Background Upload Error: Server returned HTTP ", _response_code)
			return
			
		var response_text = body.get_string_from_utf8()
		var response = JSON.parse_string(response_text)
		
		if response != null and typeof(response) == TYPE_DICTIONARY:
			if response.get("status") == "success":
				print("Background Upload Success: ", response.get("message", "No message"))
			else:
				print("Background Upload Error: ", response.get("message", "Unknown error"))
		else:
			print("Background Upload Failed to parse JSON: ", response_text)
	else:
		print("Background Upload Request failed with result: ", result)
		
		
