# res://Scenes/CustomRadioUrl/custom_radio_url_submit_button.gd
extends Button

@onready var url: LineEdit = $"../Url"
@onready var custom_radio_url: Control = $"../../.."
@onready var error_label: Label = $"../ErrorLabel"  # add a Label in the scene for feedback

var _http_request: HTTPRequest

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_check_completed)

func _on_pressed() -> void:
	var station_url: String = url.text.strip_edges()
	print("CustomRadioUrl -> Custom url: ", station_url)

	if not _is_valid_url_format(station_url):
		_show_error("Please enter a valid http:// or https:// URL.")
		return

	disabled = true  # prevent double-submit while checking
	_show_error("Checking station...")
	var err = _http_request.request(station_url, [], HTTPClient.METHOD_HEAD)
	if err != OK:
		disabled = false
		_show_error("Could not reach that URL.")

func _is_valid_url_format(text: String) -> bool:
	if text.is_empty():
		return false
	var regex := RegEx.new()
	regex.compile("^https?://[\\w.-]+\\.[a-zA-Z]{2,}(:\\d+)?(/.*)?$")
	return regex.search(text) != null

func _on_check_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	disabled = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		print("CustomRadioUrl -> URL check failed. result: ", result, " code: ", response_code)
		_show_error("That station couldn't be reached. Try another URL.")
		return

	print("CustomRadioUrl -> URL verified, switching station.")
	var station_url: String = url.text.strip_edges()
	Radio.change_station(station_url)
	Settings._add_custom_station(station_url)  # only save it once it's confirmed good
	_show_error("")
	custom_radio_url.hide()

func _show_error(msg: String) -> void:
	if error_label:
		error_label.text = msg
