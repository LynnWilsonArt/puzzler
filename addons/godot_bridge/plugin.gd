@tool
extends EditorPlugin

## Godot Bridge
##
## A small, non-blocking local HTTP server that lets an external tool
## (e.g. an Open WebUI Tool) inspect and modify the currently open project.
##
## Security model:
## - Binds to 127.0.0.1 by default. Changing this exposes the server to
##   your network; the dock warns you if you do.
## - Every request must carry "Authorization: Bearer <token>" matching the
##   configured token, unless you deliberately clear the token field.
## - Mutating commands (write_file, spawn_node) are DISABLED by default and
##   must be turned on explicitly in the dock.
## - read_file / write_file / list_dir only ever resolve paths inside the
##   project's res:// directory; anything that would escape it is rejected.

const DOCK_SCRIPT_PATH = "res://addons/godot_bridge/dock.gd"
const SETTINGS_PATH = "res://addons/godot_bridge/settings.cfg"
const MAX_BODY_BYTES = 5 * 1024 * 1024  # 5 MB
const CONNECTION_TIMEOUT_MSEC = 5000

var tcp_server: TCPServer
var connections: Array = []

var bind_address: String = "127.0.0.1"
var port: int = 9090
var auth_token: String = ""
var command_enabled: Dictionary = {
	"ping": true,
	"get_scene_tree": true,
	"read_file": true,
	"list_dir": true,
	"get_open_script": true,
	"write_file": false,
	"spawn_node": false,
}

var dock: Control
var is_running: bool = false


func _enter_tree() -> void:
	_load_settings()
	var dock_script = load(DOCK_SCRIPT_PATH)
	if dock_script == null:
		push_error("Godot Bridge: could not load %s. Use FileSystem > Scan (or Project > Reload Current Project), confirm the file exists, then disable/re-enable this plugin." % DOCK_SCRIPT_PATH)
		return
	dock = dock_script.new()
	dock.name = "Godot Bridge"
	dock.bridge = self
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	dock.refresh()


func _exit_tree() -> void:
	stop_server()
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
		dock = null


func _process(_delta: float) -> void:
	if not is_running:
		return
	_accept_new_connections()
	_service_connections()


# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

func _load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		bind_address = cfg.get_value("server", "bind_address", "127.0.0.1")
		port = int(cfg.get_value("server", "port", 9090))
		auth_token = cfg.get_value("server", "auth_token", "")
		for key in command_enabled.keys():
			command_enabled[key] = bool(cfg.get_value("commands", key, command_enabled[key]))


func save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("server", "bind_address", bind_address)
	cfg.set_value("server", "port", port)
	cfg.set_value("server", "auth_token", auth_token)
	for key in command_enabled.keys():
		cfg.set_value("commands", key, command_enabled[key])
	cfg.save(SETTINGS_PATH)


func generate_token() -> String:
	var chars := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var s := ""
	for i in range(32):
		s += chars[rng.randi_range(0, chars.length() - 1)]
	auth_token = s
	return s


# ---------------------------------------------------------------------------
# Server lifecycle
# ---------------------------------------------------------------------------

func start_server() -> String:
	stop_server()
	tcp_server = TCPServer.new()
	var err = tcp_server.listen(port, bind_address)
	if err != OK:
		tcp_server = null
		is_running = false
		return "Failed to start (error code %d). Is port %d already in use?" % [err, port]
	is_running = true
	return "Listening on %s:%d" % [bind_address, port]


func stop_server() -> void:
	for conn in connections:
		var peer: StreamPeerTCP = conn["peer"]
		if peer and peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			peer.disconnect_from_host()
	connections.clear()
	if tcp_server:
		if tcp_server.is_listening():
			tcp_server.stop()
		tcp_server = null
	is_running = false


# ---------------------------------------------------------------------------
# Non-blocking connection handling
# ---------------------------------------------------------------------------

func _accept_new_connections() -> void:
	if tcp_server == null or not tcp_server.is_listening():
		return
	while tcp_server.is_connection_available():
		var peer := tcp_server.take_connection()
		connections.append({
			"peer": peer,
			"buffer": PackedByteArray(),
			"headers_parsed": false,
			"header_text": "",
			"header_end": -1,
			"content_length": 0,
			"start_time": Time.get_ticks_msec(),
		})


func _service_connections() -> void:
	var i := connections.size() - 1
	while i >= 0:
		var conn = connections[i]
		var peer: StreamPeerTCP = conn["peer"]
		peer.poll()

		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			connections.remove_at(i)
			i -= 1
			continue

		var avail := peer.get_available_bytes()
		if avail > 0:
			var chunk = peer.get_partial_data(avail)
			if chunk[0] == OK:
				conn["buffer"].append_array(chunk[1])

		if not conn["headers_parsed"]:
			var text: String = conn["buffer"].get_string_from_utf8()
			var idx := text.find("\r\n\r\n")
			if idx != -1:
				conn["headers_parsed"] = true
				conn["header_end"] = idx + 4
				var header_text := text.substr(0, idx)
				conn["header_text"] = header_text

				if header_text.begins_with("OPTIONS"):
					_send_response(peer, 200, "{}")
					connections.remove_at(i)
					i -= 1
					continue

				var cl := 0
				for line in header_text.split("\r\n"):
					if line.to_lower().begins_with("content-length:"):
						cl = int(line.substr(line.find(":") + 1).strip_edges())

				if cl > MAX_BODY_BYTES:
					_send_response(peer, 413, "{\"ok\":false,\"error\":\"Payload too large\"}")
					connections.remove_at(i)
					i -= 1
					continue

				conn["content_length"] = cl

		if conn["headers_parsed"]:
			var body_available: int = conn["buffer"].size() - conn["header_end"]
			if body_available >= conn["content_length"]:
				var full_text: String = conn["buffer"].get_string_from_utf8()
				var body_text := full_text.substr(conn["header_end"], conn["content_length"])
				_handle_request(peer, conn["header_text"], body_text)
				connections.remove_at(i)
				i -= 1
				continue

		if Time.get_ticks_msec() - int(conn["start_time"]) > CONNECTION_TIMEOUT_MSEC:
			_send_response(peer, 408, "{\"ok\":false,\"error\":\"Request timeout\"}")
			connections.remove_at(i)
			i -= 1
			continue

		i -= 1


# ---------------------------------------------------------------------------
# Request handling
# ---------------------------------------------------------------------------

func _handle_request(peer: StreamPeerTCP, header_text: String, body_text: String) -> void:
	if not _check_auth(header_text):
		_send_response(peer, 401, "{\"ok\":false,\"error\":\"Unauthorized\"}")
		return

	var json := JSON.new()
	if json.parse(body_text) != OK:
		_send_response(peer, 400, "{\"ok\":false,\"error\":\"Invalid JSON payload\"}")
		return

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		_send_response(peer, 400, "{\"ok\":false,\"error\":\"Payload must be a JSON object\"}")
		return

	var command: String = str(data.get("command", ""))
	var payload = data.get("payload", {})

	if not command_enabled.get(command, false):
		_send_response(peer, 403, _json_result({"ok": false, "error": "Command disabled or unknown: " + command}))
		return

	var result := _execute_command(command, payload)
	_send_response(peer, 200, result)


func _check_auth(header_text: String) -> bool:
	if auth_token.is_empty():
		return true  # No token configured: auth is disabled (still localhost-only by default).
	for line in header_text.split("\r\n"):
		if line.to_lower().begins_with("authorization:"):
			var value := line.substr(line.find(":") + 1).strip_edges()
			if value == "Bearer " + auth_token:
				return true
	return false


# ---------------------------------------------------------------------------
# Path sandboxing: only res:// paths inside this project are ever touched.
# ---------------------------------------------------------------------------

func _resolve_safe_path(path: String) -> String:
	var candidate := path.strip_edges()
	if candidate.is_empty():
		return ""
	if not candidate.begins_with("res://"):
		candidate = "res://" + candidate.trim_prefix("/")
	candidate = candidate.simplify_path()
	if not candidate.begins_with("res://"):
		return ""
	if candidate.find("..") != -1:
		return ""
	return candidate


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

func _execute_command(command: String, payload) -> String:
	if typeof(payload) != TYPE_DICTIONARY:
		payload = {}

	match command:
		"ping":
			return _json_result({
				"ok": true,
				"message": "Godot Bridge is running.",
				"project": ProjectSettings.get_setting("application/config/name", "Untitled"),
				"godot_version": Engine.get_version_info().get("string", ""),
			})

		"get_scene_tree":
			var root = EditorInterface.get_edited_scene_root()
			if root == null:
				return _json_result({"ok": false, "error": "No scene open in the editor."})
			return _json_result({"ok": true, "tree": _describe_node(root)})

		"read_file":
			var path := str(payload.get("path", ""))
			var safe := _resolve_safe_path(path)
			if safe.is_empty():
				return _json_result({"ok": false, "error": "Path is empty or outside the project."})
			if not FileAccess.file_exists(safe):
				return _json_result({"ok": false, "error": "File not found: " + safe})
			var f := FileAccess.open(safe, FileAccess.READ)
			var content := f.get_as_text()
			f.close()
			return _json_result({"ok": true, "path": safe, "content": content})

		"write_file":
			var path2 := str(payload.get("path", ""))
			var content2 := str(payload.get("content", ""))
			var safe2 := _resolve_safe_path(path2)
			if safe2.is_empty():
				return _json_result({"ok": false, "error": "Path is empty or outside the project."})
			var f2 := FileAccess.open(safe2, FileAccess.WRITE)
			if f2 == null:
				return _json_result({"ok": false, "error": "Could not open file for writing: " + safe2})
			f2.store_string(content2)
			f2.close()
			EditorInterface.get_resource_filesystem().scan()
			return _json_result({"ok": true, "path": safe2})

		"list_dir":
			var path3 := str(payload.get("path", "res://"))
			var safe3 := _resolve_safe_path(path3)
			if safe3.is_empty():
				return _json_result({"ok": false, "error": "Path is empty or outside the project."})
			var dir := DirAccess.open(safe3)
			if dir == null:
				return _json_result({"ok": false, "error": "Could not open directory: " + safe3})
			var entries := []
			dir.list_dir_begin()
			var fname := dir.get_next()
			while fname != "":
				if fname != "." and fname != "..":
					entries.append({"name": fname, "is_dir": dir.current_is_dir()})
				fname = dir.get_next()
			dir.list_dir_end()
			return _json_result({"ok": true, "path": safe3, "entries": entries})

		"get_open_script":
			var script_editor = EditorInterface.get_script_editor()
			if script_editor == null:
				return _json_result({"ok": false, "error": "Script editor unavailable."})
			var current = script_editor.get_current_editor()
			if current == null:
				return _json_result({"ok": false, "error": "No script currently open."})
			var base_editor = current.get_base_editor()
			var text := ""
			if base_editor:
				text = base_editor.text
			var script = script_editor.get_current_script()
			var script_path: String = ""
			if script:
				script_path = script.resource_path
			return _json_result({"ok": true, "path": script_path, "content": text})

		"spawn_node":
			var node_type := str(payload.get("node_type", ""))
			var node_name := str(payload.get("name", "NewNode"))
			if not ClassDB.class_exists(node_type):
				return _json_result({"ok": false, "error": "Unknown node class: " + node_type})
			if node_type != "Node" and not ClassDB.is_parent_class(node_type, "Node"):
				return _json_result({"ok": false, "error": node_type + " is not a Node subclass."})
			var root2 = EditorInterface.get_edited_scene_root()
			if root2 == null:
				return _json_result({"ok": false, "error": "No scene open in the editor."})
			var new_node = ClassDB.instantiate(node_type)
			if new_node == null:
				return _json_result({"ok": false, "error": "Could not instantiate: " + node_type})
			new_node.name = node_name
			root2.add_child(new_node)
			new_node.owner = root2
			return _json_result({"ok": true, "message": "Spawned %s named '%s' under %s" % [node_type, node_name, root2.name]})

		_:
			return _json_result({"ok": false, "error": "Unrecognized command: " + command})


func _describe_node(node: Node, depth: int = 0, max_depth: int = 4) -> Dictionary:
	var desc := {"name": node.name, "type": node.get_class()}
	if depth < max_depth and node.get_child_count() > 0:
		var children := []
		for child in node.get_children():
			children.append(_describe_node(child, depth + 1, max_depth))
		desc["children"] = children
	return desc


func _json_result(data: Dictionary) -> String:
	return JSON.stringify(data)


# ---------------------------------------------------------------------------
# Response writing
# ---------------------------------------------------------------------------

func _send_response(peer: StreamPeerTCP, status_code: int, response_body: String) -> void:
	var reason := _http_reason(status_code)
	var body_bytes := response_body.to_utf8_buffer()

	var response := "HTTP/1.1 %d %s\r\n" % [status_code, reason]
	response += "Content-Type: application/json; charset=utf-8\r\n"
	response += "Content-Length: %d\r\n" % body_bytes.size()
	response += "Access-Control-Allow-Origin: *\r\n"
	response += "Access-Control-Allow-Methods: POST, GET, OPTIONS\r\n"
	response += "Access-Control-Allow-Headers: Content-Type, Authorization\r\n"
	response += "Connection: close\r\n\r\n"

	peer.put_data(response.to_utf8_buffer())
	peer.put_data(body_bytes)
	peer.disconnect_from_host()


func _http_reason(code: int) -> String:
	match code:
		200: return "OK"
		400: return "Bad Request"
		401: return "Unauthorized"
		403: return "Forbidden"
		404: return "Not Found"
		408: return "Request Timeout"
		413: return "Payload Too Large"
		_: return "Error"
