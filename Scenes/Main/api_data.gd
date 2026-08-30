# res://Scenes/Main/api_data.gd
extends Node

var http_request: HTTPRequest
var app_state: bool = false # app not running
var data # app ddate to log

func _ready() -> void:
	# sets the initial app state to running state = true
	if !app_state:
		app_state = true # app is open
		
		print(" ready() app_state: ",app_state)
		_send_api_data(app_state)
	
	
	
func _send_api_data(state) -> void:
	
	print("app_state: ",state)
	# 1. Create and add the HTTPRequest node dynamically
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 2. Connect the completion signal
	http_request.request_completed.connect(_on_request_completed)
	

	
	print("state Android: ",state)
	# Handle everything but web app
	if state:
		data = Globals.app_open_data 
	else:
		data = Globals.app_closed_data  
	
		
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
