# res://Scenes/Main/api_data.gd
extends Node

var http_request: HTTPRequest
var app_state: bool = false # app not running
var data # app ddate to log
####################
var app_number_to_send 
var rng =  RandomNumberGenerator.new()
var app_id_file_path = "user://app_id.txt"



func _ready() -> void:
	# sets the initial app state to running state = true
	if !app_state:
		app_state = true # app is open
		
		print(" ready() app_state: ",app_state)
		app_number_to_send = _get_app_number()
		print("Ready() app_number_to_send: ",app_number_to_send)
		_send_api_data(app_state)
	
	
	
func _send_api_data(state) -> void:
# App data for logs on https://puzzler.lynnwilsonart.com/api_19511969/game_events.log
# NOTE: These are now functions (not static vars) so that app_id and timestamp
# are always current at the moment the data is requested, instead of being
# frozen at script-load time (before app_number is even assigned in _ready()).

	
	print("app_state: ",state)
	# 1. Create and add the HTTPRequest node dynamically
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 2. Connect the completion signal
	http_request.request_completed.connect(_on_request_completed)
	
	print("state Android: ",state)
	# Handle everything but web app
	if state:
		data = get_app_open_data()
		print("App Number: ",app_number_to_send)
		print("Data: ",data)
	else:
		data = get_app_closed_data() 
		print("Data: ",data)
	
		
	# 4. Convert to JSON string
	var json_body := JSON.stringify(data)
	
	# 5. Set mandatory JSON headers
	var headers := ["Content-Type: application/json"]
	
	# 6. Change this URL to point directly to your PHP script location
	var url := "https://puzzler.lynnwilsonart.com/api_19511969/get_app_data.php" 
	
	# 7. Execute the POST request
	var error := http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		push_error("An error occurred while attempting the network request.")
	
	
func get_app_open_data() -> Dictionary:
		return {
			"type": "app_open",                                  # Can be "app_open" or "app_closed"
			"timestamp": int(Time.get_unix_time_from_system()),  # Current Unix timestamp
			"app_id": str(app_number_to_send)
		}

func get_app_closed_data() -> Dictionary:
		return {
			"type": "app_closed",                                # Can be "app_open" or "app_closed"
			"timestamp": int(Time.get_unix_time_from_system()),  # Current Unix timestamp
			"app_id": str(app_number_to_send)
		}

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Check if the network request actually went through
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Network connection error occurred.")
		return
		
	print("HTTP Response Code: ", response_code)
	
	# Parse the incoming JSON response from your PHP script
	var json = JSON.new()
	var parse_err = json.parse(body.get_string_from_utf8())
	
	if parse_err == OK:
		var response_data = json.get_data()
		print("Server Response Data: ", response_data)
	else:
		print("Failed to parse the server's response. Raw string: ", body.get_string_from_utf8())
		
func _get_app_number():
		
	if FileAccess.file_exists(app_id_file_path):
		var file = FileAccess.open(app_id_file_path, FileAccess.READ)
		if file:
			var app_id = file.get_as_text()
			file.close()
			print("Existing App ID: ", app_id)
			# Proceed to main program
			app_number_to_send = app_id.strip_edges() # strips the /n off the end
			print("App Number to send: ",app_number_to_send)
			return(app_number_to_send)
	else:
		rng.randomize()
		var app_id = rng.randi()
		print("Generated App ID: ", app_id)

		var file = FileAccess.open(app_id_file_path, FileAccess.WRITE)
		if file:
			if OS.has_feature("web"):
				app_id = "WEBSITE"
				file.store_line(str(app_id)) # convert to string before saving
				file.close()
			else:
				file.store_line(str(app_id)) # convert to string before saving
				file.close()

		# Proceed to main program
		app_number_to_send = app_id
		print("App Number to send: ",app_number_to_send)
		return(app_number_to_send)
