# res://Scenes/Puzzle/update_stations.gd
extends PopupMenu

const SAVE_PATH: String = "user://stations.json"
@onready var station_update_edit_button: Button = $"../../../../StationUpdatePanel/StationsColorRect/StationUpdateEditButton"
@onready var station_update_station_id: Label = $"../../../../StationUpdatePanel/StationsColorRect/StationUpdateStationID"
@onready var station_name_line_edit: LineEdit = $"../../../../StationUpdatePanel/StationsColorRect/StationNameLabel/StationNameLineEdit"
@onready var station_url_line_edit: LineEdit = $"../../../../StationUpdatePanel/StationsColorRect/StationUrlLabel/StationUrlLineEdit"
@onready var error_label: Label = $"../../../../StationUpdatePanel/StationsColorRect/ErrorLabel"
@onready var settings_ui: Control = $"../../../../SettingsUI"

signal turn_on_radio

func _ready() -> void:
	turn_on_radio.connect(settings_ui._on_music_on_pressed)
	print("[Puzzle] -> stations_popup_menu.gd -> _ready()")
	if not id_pressed.is_connected(_on_id_pressed):
		id_pressed.connect(_on_id_pressed)
	
	_load_stations_from_json()
	_rebuild_popup_menu()

func _rebuild_popup_menu() -> void:
	clear()
	for station in Globals.stations_array:
		var display_name: String = station.get("station_name", "Unknown Station")
		add_item(display_name)

# --- ADD & VALIDATE FUNCTIONS ---

## Validates the stream URL against Icecast standards, then adds it if valid.
func add_station(url: String, description: String = "") -> bool:
	var trimmed_url: String = url.strip_edges()
	var trimmed_desc: String = description.strip_edges()
	
	if trimmed_url.is_empty():
		printerr("Puzzle -> stations_popup_menu.gd -> Cannot add empty URL.")
		error_label.text = " ERROR! Cannot add a empty url!"
		await get_tree().create_timer(4.0, true, true).timeout
		error_label.text = ""
		
		return false
		
	if has_station_url(trimmed_url):
		print("[Puzzle] -> stations_popup_menu.gd -> Station URL already exists: ", trimmed_url)
		error_label.text = "ERROR! Station URL already exists! "
		await get_tree().create_timer(4.0, true, true).timeout
		error_label.text = ""
		return false

	# Validate stream URL asynchronously using low-level HTTPClient
	print("[Puzzle] -> stations_popup_menu.gd -> Validating Icecast stream: ", trimmed_url)
	error_label.text = " Validating Icecast stream."
	await get_tree().create_timer(2.0, true, true).timeout
	error_label.text = ""
		
	var is_valid: bool = await is_valid_icecast_stream(trimmed_url)
	
	if not is_valid:
		printerr("Puzzle -> stations_popup_menu.gd -> Invalid Icecast URL or stream offline: ", trimmed_url)
		error_label.text = "ERROR! Invalid Icecast URL or stream offline."
		await get_tree().create_timer(4.0, true, true).timeout
		error_label.text = ""
		return false

	var display_title: String = trimmed_desc if not trimmed_desc.is_empty() else trimmed_url

	Globals.stations_array.append({
		"station_name": display_title,
		"url": trimmed_url
	})
	
	_rebuild_popup_menu()
	_save_stations_to_json()
	print("[Puzzle] -> stations_popup_menu.gd -> Successfully validated and added station: ", display_title)
	error_label.text = "SUCCESS! Successfully validated and added station."
	await get_tree().create_timer(4.0, true, true).timeout
	error_label.text = ""
	
	return true

# --- EDIT FUNCTIONS ---

## Edits an existing station at a given array index.
func edit_station_at(index: int, new_name: String, new_url: String, validate_new_url: bool = true) -> bool:
	if index < 0 or index >= Globals.stations_array.size():
		printerr("Puzzle -> stations_popup_menu.gd -> Edit failed: Index %d out of bounds." % index)
		error_label.text = "ERROR! Edit failed: Index %d out of bounds."
		await get_tree().create_timer(4.0, true, true).timeout
		error_label.text = ""
		return false

	var trimmed_name: String = new_name.strip_edges()
	var trimmed_url: String = new_url.strip_edges()

	if trimmed_url.is_empty():
		printerr("Puzzle -> stations_popup_menu.gd -> Cannot save station with an empty URL.")
		error_label.text = "ERROR! Cannot save station with an empty URL."
		await get_tree().create_timer(4.0, true, true).timeout
		error_label.text = ""
		return false
		

	var current_station: Dictionary = Globals.stations_array[index]
	var old_url: String = current_station.get("url", "")
	var url_changed: bool = (trimmed_url != old_url)

	# If the URL was modified, verify it isn't used by another entry
	if url_changed:
		for i in range(Globals.stations_array.size()):
			if i != index and Globals.stations_array[i].get("url", "").strip_edges() == trimmed_url:
				printerr("Puzzle -> stations_popup_menu.gd -> URL already exists in list: ", trimmed_url)
				error_label.text = "ERROR! URL already exists in list."
				await get_tree().create_timer(4.0, true, true).timeout
				error_label.text = ""
				
				return false

		# Validate stream only when the URL changes
		if validate_new_url:
			print("[Puzzle] -> stations_popup_menu.gd -> Validating updated stream: ", trimmed_url)
			error_label.text = "Validating updated stream."
			await get_tree().create_timer(4.0, true, true).timeout
			error_label.text = ""
			var is_valid: bool = await is_valid_icecast_stream(trimmed_url)
			if not is_valid:
				printerr("Puzzle -> stations_popup_menu.gd -> Updated URL is invalid or offline: ", trimmed_url)
				error_label.text = "ERROR! Updated URL is invalid or offline."
				await get_tree().create_timer(4.0, true, true).timeout
				error_label.text = ""
				return false

	var display_title: String = trimmed_name if not trimmed_name.is_empty() else trimmed_url

	Globals.stations_array[index] = {
		"station_name": display_title,
		"url": trimmed_url
	}

	_rebuild_popup_menu()
	_save_stations_to_json()
	print("[Puzzle] -> stations_popup_menu.gd -> Successfully edited station at index %d: %s" % [index, display_title])
	error_label.text = "SUCCESS!   Edit saved.."
	await get_tree().create_timer(4.0, true, true).timeout
	error_label.text = ""
	return true

## Edits a station matching an existing target URL.
func edit_station_by_url(target_url: String, new_name: String, new_url: String, validate_new_url: bool = true) -> bool:
	for i in range(Globals.stations_array.size()):
		if Globals.stations_array[i].get("url", "").strip_edges() == target_url.strip_edges():
			return await edit_station_at(i, new_name, new_url, validate_new_url)
			
	printerr("Puzzle -> stations_popup_menu.gd -> Edit failed: Target URL not found: ", target_url)
	error_label.text = "ERROR! Edit failed: Target URL not found."
	await get_tree().create_timer(4.0, true, true).timeout
	error_label.text = ""
	return false

# --- NETWORK VALIDATION HELPERS ---

## Inspects HTTP headers without downloading the continuous stream payload
func is_valid_icecast_stream(url: String, timeout_seconds: float = 6.0, redirect_limit: int = 5) -> bool:
	if redirect_limit <= 0:
		return false

	var parsed: Dictionary = _parse_url(url)
	if parsed.is_empty():
		return false

	var client := HTTPClient.new()
	var tls_options: TLSOptions = TLSOptions.client() if parsed.is_ssl else null
	
	var err := client.connect_to_host(parsed.host, parsed.port, tls_options)
	if err != OK:
		return false

	var start_time: int = Time.get_ticks_msec()

	# Wait for connection
	while client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING:
		client.poll()
		await get_tree().process_frame
		if (Time.get_ticks_msec() - start_time) / 1000.0 > timeout_seconds:
			client.close()
			return false

	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		client.close()
		return false

	# Request headers only (Icy-MetaData prompts Icecast/Shoutcast header metadata)
	var request_headers := PackedStringArray([
		"User-Agent: GodotRadio/1.0",
		"Icy-MetaData: 1"
	])

	err = client.request(HTTPClient.METHOD_GET, parsed.path, request_headers)
	if err != OK:
		client.close()
		return false

	# Poll until response headers arrive (STATUS_BODY)
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		await get_tree().process_frame
		if (Time.get_ticks_msec() - start_time) / 1000.0 > timeout_seconds:
			client.close()
			return false

	if not client.has_response():
		client.close()
		return false

	var response_code: int = client.get_response_code()
	var response_headers: PackedStringArray = client.get_response_headers()
	client.close() # Close immediately to prevent streaming endless audio data into RAM

	# Handle HTTP Redirects (301, 302, 303, 307, 308)
	if response_code in [301, 302, 303, 307, 308]:
		var redirect_url: String = _get_header_value(response_headers, "location")
		if not redirect_url.is_empty():
			if not redirect_url.begins_with("http"):
				redirect_url = ("https://" if parsed.is_ssl else "http://") + parsed.host + redirect_url
			return await is_valid_icecast_stream(redirect_url, timeout_seconds, redirect_limit - 1)

	if response_code != 200:
		return false

	return _contains_icecast_headers(response_headers)

func _contains_icecast_headers(headers: PackedStringArray) -> bool:
	for header in headers:
		var h_lower: String = header.to_lower()
		if h_lower.begins_with("server: icecast") \
		or h_lower.begins_with("server: shoutcast") \
		or h_lower.begins_with("icy-") \
		or h_lower.begins_with("x-audiocast-") \
		or "content-type: audio/" in h_lower \
		or "content-type: application/ogg" in h_lower \
		or "content-type: video/ogg" in h_lower:
			return true
	return false

func _get_header_value(headers: PackedStringArray, key: String) -> String:
	var prefix: String = key.to_lower() + ":"
	for h in headers:
		if h.to_lower().begins_with(prefix):
			return h.substr(prefix.length()).strip_edges()
	return ""

func _parse_url(url: String) -> Dictionary:
	var is_ssl: bool = url.begins_with("https://")
	var scheme: String = "https://" if is_ssl else "http://"
	
	if not url.begins_with("http://") and not url.begins_with("https://"):
		return {}
		
	var without_scheme: String = url.trim_prefix(scheme)
	var path_split: PackedStringArray = without_scheme.split("/", true, 1)
	var host_and_port: String = path_split[0]
	var path: String = "/" + (path_split[1] if path_split.size() > 1 else "")
	
	var host: String = host_and_port
	var port: int = 443 if is_ssl else 80
	
	if ":" in host_and_port:
		var parts: PackedStringArray = host_and_port.split(":")
		host = parts[0]
		port = parts[1].to_int()
		
	return {
		"host": host,
		"port": port,
		"path": path,
		"is_ssl": is_ssl
	}

func has_station_url(url: String) -> bool:
	for station in Globals.stations_array:
		if station.get("url", "").strip_edges() == url.strip_edges():
			return true
	return false

# --- DELETE FUNCTIONS ---

func delete_station_at(index: int) -> void:
	if index >= 0 and index < Globals.stations_array.size():
		var removed: Dictionary = Globals.stations_array[index]
		Globals.stations_array.remove_at(index)
		print("[Puzzle] -> stations_popup_menu.gd -> Deleted: ", removed.get("station_name"))
		error_label.text = " SUCCESS! Deleted: " + removed.get("station_name")
		await get_tree().create_timer(2.0, true, true).timeout
		error_label.text = ""
		station_name_line_edit.text = ""
		station_url_line_edit.text = ""
		_rebuild_popup_menu()
		_save_stations_to_json()

func delete_station_by_url(url: String) -> void:
	for i in range(Globals.stations_array.size() - 1, -1, -1):
		if Globals.stations_array[i].get("url") == url:
			Globals.stations_array.remove_at(i)
			print("[Puzzle] -> stations_popup_menu.gd -> Deleted URL: ", url)
			error_label.text = " SUCCESS! Deleted URL: " + url
			await get_tree().create_timer(2.0, true, true).timeout
			error_label.text = ""
			station_name_line_edit.text = ""
			station_url_line_edit.text = ""
			
			_rebuild_popup_menu()
			_save_stations_to_json()
			break

# --- SAVE / LOAD FUNCTIONS ---

func _save_stations_to_json() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string: String = JSON.stringify(Globals.stations_array, "\t")
		file.store_string(json_string)
		file.close()

func _load_stations_from_json() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
		
	var json_string: String = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result == OK and json.data is Array:
		for item in json.data:
			if item == null:
				continue
				
			var station_name: String = ""
			var url: String = ""
			
			if item is Dictionary:
				station_name = str(item.get("station_name", item.get("name", "")))
				url = str(item.get("url", ""))
			elif item is String:
				url = item
				station_name = item
			
			if not url.is_empty() and not has_station_url(url):
				Globals.stations_array.append({"station_name": station_name, "url": url})

func _on_id_pressed(id: int) -> void:
	print("[Puzzle] -> stations_popup_menu.gd -> _on_id_pressed()")
	
	
	if id >= 0 and id < Globals.stations_array.size():
		var selected_station: Dictionary = Globals.stations_array[id]
		print("[Puzzle] -> stations_popup_menu.gd -> Selection: ", selected_station.get("station_name"))
		Radio.change_station(selected_station.get("url"))
		
		# Set StationUpdatePanel station vars
		station_url_line_edit.text = selected_station.get("url")
		station_name_line_edit.text = selected_station.get("station_name")
		station_update_station_id.text = str(id)
		# Station was selected. Turn radio on.
		# Station was selected. Turn radio on.
		turn_on_radio.emit()
		
		
	
	else:
		printerr("Puzzle -> stations_popup_menu.gd -> Selected ID %d is out of bounds." % id)
		
		
		#--------------------------------------------------------------
	
# ------------------------------------------------------------------
#  Validate that a URL is a valid Icecast/Shoutcast MP3 stream.
# ------------------------------------------------------------------
func is_valid_icecast_stream(url: String, timeout_seconds: float = 6.0, redirect_limit: int = 5) -> bool:
	# Stop recursion if we hit the redirect limit
	if redirect_limit <= 0:
		return false

	var parsed: Dictionary = _parse_url(url)
	if parsed.is_empty():
		return false

	var client := HTTPClient.new()
	var tls_options: TLSOptions = TLSOptions.client() if parsed.is_ssl else null

	var err := client.connect_to_host(parsed.host, parsed.port, tls_options)
	if err != OK:
		return false

	var start_time: int = Time.get_ticks_msec()

	# Wait for the connection to be established
	while client.get_status() == HTTPClient.STATUS_CONNECTING or client.get_status() == HTTPClient.STATUS_RESOLVING:
		client.poll()
		await get_tree().process_frame
		if (Time.get_ticks_msec() - start_time) / 1000.0 > timeout_seconds:
			client.close()
			return false

	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		client.close()
		return false

	# Request headers – Icy-Metadata triggers Icecast/Shoutcast metadata headers
	var request_headers := PackedStringArray([
		"User-Agent: GodotRadio/1.0",
		"Icy-MetaData: 1"
	])
	err = client.request(HTTPClient.METHOD_GET, parsed.path, request_headers)
	if err != OK:
		client.close()
		return false

	# Wait for the response headers
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		await get_tree().process_frame
		if (Time.get_ticks_msec() - start_time) / 1000.0 > timeout_seconds:
			client.close()
			return false

	if not client.has_response():
		client.close()
		return false

	var response_code: int = client.get_response_code()
	var response_headers: PackedStringArray = client.get_response_headers()

	# Handle HTTP redirects (301, 302, 303, 307, 308)
	if response_code in [301, 302, 303, 307, 308]:
		var redirect_url: String = _get_header_value(response_headers, "location")
		if not redirect_url.is_empty():
			if not redirect_url.begins_with("http"):
				redirect_url = ("https://" if parsed.is_ssl else "http://") + parsed.host + redirect_url
			client.close()
			return await is_valid_icecast_stream(redirect_url, timeout_seconds, redirect_limit - 1)

	# Only a 200 OK is acceptable
	if response_code != 200:
		client.close()
		return false

	# The headers must identify an audio stream
	if not _contains_icecast_headers(response_headers):
		client.close()
		return false

	# Pull a tiny chunk of the body to confirm it is MP3 data.
	var content_type: String = _get_header_value(response_headers, "content-type").to_lower()
	if not content_type.begins_with("audio/mpeg") and not content_type.begins_with("audio/mp3"):
		client.close()
		return false

	var body_data: PackedByteArray = PackedByteArray()
	var read_start_time: int = Time.get_ticks_msec()

	while client.get_status() == HTTPClient.STATUS_BODY and (Time.get_ticks_msec() - read_start_time) / 1000.0 < timeout_seconds:
		client.poll()
		await get_tree().process_frame
		var chunk: PackedByteArray = client.read_response_body_chunk()
		if chunk.size() > 0:
			body_data.append_array(chunk)
			if body_data.size() >= 1024:  # 1 kB is enough to see an MP3 frame header
				break

	client.close()

	if body_data.size() == 0:
		return false

	# Verify the first bytes look like a valid MP3 frame header
	return _is_mp3_frame_header(body_data)

# ------------------------------------------------------------------
# Helper: Check that headers identify an audio stream
# ------------------------------------------------------------------
func _contains_icecast_headers(headers: PackedStringArray) -> bool:
	for header in headers:
		var h_lower: String = header.to_lower()
		if h_lower.begins_with("content-type: audio/mpeg") or h_lower.begins_with("content-type: audio/mp3"):
			return true
	return false

# ------------------------------------------------------------------
# Helper: Return the value of a header (case-insensitive).
# ------------------------------------------------------------------
func _get_header_value(headers: PackedStringArray, key: String) -> String:
	var prefix: String = key.to_lower() + ":"
	for h in headers:
		var h_lower: String = h.to_lower()
		if h_lower.begins_with(prefix):
			return h.substr(prefix.length()).strip_edges()
	return ""

# ------------------------------------------------------------------
# Helper: MP3 frame header check (sync word 0xFFE).
# ------------------------------------------------------------------
func _is_mp3_frame_header(data: PackedByteArray) -> bool:
	if data.size() < 2:
		return false
	var b0: int = data[0]
	var b1: int = data[1]
	return b0 == 0xFF and (b1 & 0xE0) == 0xE0

# ------------------------------------------------------------------
# Helper: Parse URL into host, port, path, and SSL flag.
# ------------------------------------------------------------------
# ------------------------------------------------------------------
#  Helper: Parse URL into host, port, path, and SSL flag.
# ------------------------------------------------------------------
func _parse_url(url: String) -> Dictionary:
	var is_ssl: bool = url.begins_with("https://")
	var scheme: String = "https://" if is_ssl else "http://"

	if not url.begins_with(scheme):
		return {}

	var without_scheme: String = url.trim_prefix(scheme)
	var parts: PackedStringArray = without_scheme.split("/", true, 1)

	var host_and_port: String = parts[0]
	var path: String = "/" + (parts[1] if parts.size() > 1 else "")

	var host: String = host_and_port
	var port: int = 443 if is_ssl else 80  # FIXED: GDScript 4 ternary syntax

	if ":" in host_and_port:
		var hp_parts: PackedStringArray = host_and_port.split(":")
		host = hp_parts[0]
		port = hp_parts[1].to_int()

	return {
		"host": host,
		"port": port,
		"path": path,
		"is_ssl": is_ssl
	}
	
# Add this function to handle the menu item selection
func _on_id_pressed(id: int) -> void:
	# Example: Check which menu item ID was pressed
	match id:
		0:
			print("Station 1 selected")
		1:
			print("Station 2 selected")
		_:
			print("Unknown station ID: ", id)
			
