class_name ConfigLoader
extends Node

signal config_loaded(data: Dictionary)
signal config_failed(error_message: String)

const CONFIG_URL: String = "https://images.lynnwilsonart.com/banners/config.json"

# Fallback values if network or parsing fails
const DEFAULT_CONFIG: Dictionary = {
	"number_banners": 5,
	"cache_refresh_time": 86400,
	"banner_display_time": 300
}

@export var number_banners: int = 0
@export var cache_refresh_time: int = 0
@export var banner_display_time: int = 0

var http_request: HTTPRequest = HTTPRequest.new()

func _ready() -> void:
	print("[ConfigLoader] -> _ready")
	_ensure_http_node()
	fetch_config()

func _ensure_http_node() -> void:
	if http_request.get_parent() == null:
		var current_scene = Engine.get_main_loop().current_scene if Engine.get_main_loop() else null
		if current_scene and current_scene != self:
			current_scene.add_child(http_request)
		else:
			add_child(http_request)

func fetch_config() -> Dictionary:
	_ensure_http_node()

	if not is_inside_tree():
		push_error("ConfigLoader is not inside the scene tree yet.")
		config_failed.emit("Not inside scene tree")
		return DEFAULT_CONFIG

	var err: int = http_request.request(CONFIG_URL)
	if err != OK:
		var err_msg = "HTTP request failed to start: %s" % err
		push_error(err_msg)
		config_failed.emit(err_msg)
		return DEFAULT_CONFIG

	# Wait for the signal and unpack its 4 default arguments
	var response_data: Array = await http_request.request_completed
	var result: int = response_data[0]
	var response_code: int = response_data[1] # Fixed double assignment
	var _response_headers: PackedStringArray = response_data[2]
	var response_body: PackedByteArray = response_data[3]

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or response_body.is_empty():
		var err_msg = "Failed to fetch remote config (Result: %d, Code: %d). Using defaults." % [result, response_code]
		push_error(err_msg)
		config_failed.emit(err_msg)
		return DEFAULT_CONFIG

	var json_text: String = response_body.get_string_from_utf8()
	var raw_data = JSON.parse_string(json_text)
	if raw_data == null:
		var err_msg = "JSON parse error for text: %s. Using defaults." % json_text
		push_error(err_msg)
		config_failed.emit(err_msg)
		return DEFAULT_CONFIG

	var data: Dictionary
	if raw_data is Array and not raw_data.is_empty() and raw_data[0] is Dictionary:
		data = raw_data[0]
	elif raw_data is Dictionary:
		data = raw_data
	else:
		config_failed.emit("Unexpected JSON structure")
		return DEFAULT_CONFIG

	number_banners = int(data.get("number_banners", DEFAULT_CONFIG["number_banners"]))
	cache_refresh_time = int(data.get("cache_refresh_time", DEFAULT_CONFIG["cache_refresh_time"]))
	banner_display_time = int(data.get("banner_display_time", DEFAULT_CONFIG["banner_display_time"]))

	var result_dict := {
		"number_banners": number_banners,
		"cache_refresh_time": cache_refresh_time,
		"banner_display_time": banner_display_time
	}

	config_loaded.emit(result_dict)
	return result_dict
