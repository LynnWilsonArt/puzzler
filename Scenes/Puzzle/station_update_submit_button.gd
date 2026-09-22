# res://Scenes/Puzzle/station_update_submit_button.gd
extends Button

@onready var stations_popup_menu: PopupMenu = $"../../../PanelContainer/PuzzleOpenMenuButton/PuzzlePopupMenu/StationsPopupMenu"
@onready var station_description_line_edit: LineEdit = $"../StationDescription/StationDescriptionLineEdit"
@onready var url: LineEdit = $"../StationUrlDescription/StationUrlLineEdit"
@onready var station_update_panel: PanelContainer = $"../.."
@onready var error_label: Label = $"../ErrorLabel"


var _http_request: HTTPRequest
var station_url: String = ""
var station_description: String = ""


func _ready() -> void:
	
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_check_completed)

func _on_pressed() -> void:
	print("[Puzzle] -> station_update_submit_button.gd -> _on_pressed()")
	station_url = url.text.strip_edges()
	station_description = station_description_line_edit.text.strip_edges()
	print("[Puzzle] -> StationUpdatePanel -> Station url: ", station_url)

	if not _is_valid_url_format(station_url):
		_show_error("Please enter a valid http:// or https:// URL.")
		return

	disabled = true  # prevent double-submit while checking
	_show_error("Checking station...")
	var err = _http_request.request(station_url, [], HTTPClient.METHOD_HEAD)
	if err != OK:
		disabled = false
		_show_error("Could not reach that URL.")

@warning_ignore("shadowed_variable_base_class")
func _is_valid_url_format(text: String) -> bool:
	if text.is_empty():
		return false
	var regex := RegEx.new()
	regex.compile("^https?://[\\w.-]+\\.[a-zA-Z]{2,}(:\\d+)?(/.*)?$")
	return regex.search(text) != null

@warning_ignore("unused_parameter")
func _on_check_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	disabled = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		print("[Puzzle] -> StationUpdatePanel -> URL check failed. result: ", result, " code: ", response_code)
		_show_error("That station couldn't be reached. Try another URL.")
		return

	print("[Puzzle] -> StationUpdatePanel -> URL verified, adding & switching station.")
	stations_popup_menu.add_station(station_url,station_description)
	Radio.change_station(station_url)
	Settings._add_custom_station(station_url)  # only save it once it's confirmed good
	_show_error("")
	station_update_panel.hide()

func _show_error(msg: String) -> void:
	if error_label:
		error_label.text = msg
