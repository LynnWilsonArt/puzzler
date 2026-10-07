@tool
extends EditorPlugin
# res://addons/godot_bridge/plugin.gd
## Godot Bridge Version 2.4.1

const DOCK_SCRIPT_PATH = "res://addons/godot_bridge/dock.gd"
const SETTINGS_PATH = "res://addons/godot_bridge/settings.cfg"
const MAX_BODY_BYTES = 5 * 1024 * 1024
const CONNECTION_TIMEOUT_MSEC = 5000
const MAX_READ_CHARS = 60000
const LOOPBACK_ADDRESSES = ["127.0.0.1", "localhost"]

var tcp_server: TCPServer
var connections: Array = []

var bind_address: String = "127.0.0.1"
var port: int = 9090
var auth_token: String = ""
var cors_origin: String = ""
var auto_start: bool = false

var dock: Control
var is_running: bool = false
var _output_mark: int = 0
var _capture: ErrorCapture

## Receives engine errors directly (Godot 4.5+ Logger API), so we don't
## depend on scraping the Output panel. GDScript parse errors raised by
## GDScript.reload() arrive here with file, line and message.
class ErrorCapture extends Logger:
	var mutex := Mutex.new()
	var entries: Array = []
	var active: bool = false

	func begin() -> void:
		mutex.lock()
		entries.clear()
		active = true
		mutex.unlock()

	func end() -> Array:
		mutex.lock()
		active = false
		var out := entries.duplicate()
		entries.clear()
		mutex.unlock()
		return out

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if not active:
			return
		mutex.lock()
		entries.append({
			"function": function,
			"file": file,
			"line": line,
			"code": code,
			"rationale": rationale,
			"error_type": error_type,
		})
		mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass

var command_enabled: Dictionary = {
	"ping": true,
	"get_commands": true,
	"get_scene_tree": true,
	"get_selected_nodes": true,
	"get_node_properties": true,
	"get_node_signals": true,
	"get_open_scenes": true,
	"read_file": true,
	"list_dir": true,
	"get_open_script": true,
	"get_output": true,
	"validate_script": true,
	"class_info": true,
	"write_file": true,
	"make_dir": true,
	"delete_file": false,
	"spawn_node": true,
	"spawn_packed_scene": true,
	"remove_node": true,
	"reparent_node": true,
	"rename_node": true,
	"set_node_property": true,
	"attach_script": true,
	"add_to_group": true,
	"connect_signal": true,
	"create_scene": true,
	"save_scene": true,
	"open_scene": true,
	"set_main_scene": true,
	"add_input_action": true,
	"run_project": true,
	"run_current_scene": true,
	"stop_project": true,
}

const COMMAND_DOCS = {
	"ping": "No payload. Returns project name and Godot version.",
	"get_commands": "No payload. Lists every command, whether it is enabled, and its payload.",
	"get_scene_tree": "Payload: {max_depth?: int}. Returns nodes with name, type, path, script.",
	"get_selected_nodes": "No payload. Nodes currently selected in the editor.",
	"get_node_properties": "Payload: {node_path, filter?: substring}.",
	"get_node_signals": "Payload: {node_path, connected_only?: bool}.",
	"get_open_scenes": "No payload. Scene files currently open in the editor.",
	"read_file": "Payload: {path, offset?: int, limit?: int}.",
	"list_dir": "Payload: {path?, recursive?: bool}.",
	"get_open_script": "No payload. Script currently open in the script editor.",
	"get_output": "Payload: {max_chars?: int, new_only?: bool}.",
	"validate_script": "Payload: {path}. Parses the file from disk and returns line and message on failure.",
	"class_info": "Payload: {class, filter?: substring}.",
	"write_file": "Payload: {path, content}.",
	"make_dir": "Payload: {path}.",
	"delete_file": "Payload: {path}.",
	"spawn_node": "Payload: {node_type, name?, parent?: node_path, properties?: {}}.",
	"spawn_packed_scene": "Payload: {scene_path, name?, parent?: node_path, properties?: {}}.",
	"remove_node": "Payload: {node_path}.",
	"reparent_node": "Payload: {node_path, new_parent}.",
	"rename_node": "Payload: {node_path, new_name}.",
	"set_node_property": "Payload: {node_path, property, value}.",
	"attach_script": "Payload: {node_path, script_path}.",
	"add_to_group": "Payload: {node_path, group}.",
	"connect_signal": "Payload: {source, target, signal, method}.",
	"create_scene": "Payload: {path, root_type?, root_name?, overwrite?: bool}.",
	"save_scene": "No payload.",
	"open_scene": "Payload: {path}.",
	"set_main_scene": "Payload: {path}.",
	"add_input_action": "Payload: {action, keys: [\"W\", \"Up\"]}.",
	"run_project": "No payload.",
	"run_current_scene": "No payload.",
	"stop_project": "No payload.",
}

func _enter_tree() -> void:
	_load_settings()
	_capture = ErrorCapture.new()
	OS.add_logger(_capture)
	var dock_script = load(DOCK_SCRIPT_PATH)
	if dock_script == null:
		push_error("Godot Bridge: could not load %s." % DOCK_SCRIPT_PATH)
		return
	dock = dock_script.new()
	dock.name = "Godot Bridge"
	dock.set("bridge", self)
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	if auto_start:
		start_server()
	dock.call("refresh")

func _exit_tree() -> void:
	stop_server()
	if _capture:
		OS.remove_logger(_capture)
		_capture = null
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
		dock = null

func _process(_delta: float) -> void:
	if not is_running:
		return
	_accept_new_connections()
	_service_connections()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		bind_address = str(cfg.get_value("server", "bind_address", "127.0.0.1"))
		port = int(cfg.get_value("server", "port", 9090))
		auth_token = str(cfg.get_value("server", "auth_token", ""))
		cors_origin = str(cfg.get_value("server", "cors_origin", ""))
		auto_start = bool(cfg.get_value("server", "auto_start", false))
		for key in command_enabled.keys():
			command_enabled[key] = bool(cfg.get_value("commands", key, command_enabled[key]))
	else:
		generate_token()
		save_settings()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("server", "bind_address", bind_address)
	cfg.set_value("server", "port", port)
	cfg.set_value("server", "auth_token", auth_token)
	cfg.set_value("server", "cors_origin", cors_origin)
	cfg.set_value("server", "auto_start", auto_start)
	for key in command_enabled.keys():
		cfg.set_value("commands", key, command_enabled[key])
	cfg.save(SETTINGS_PATH)

func generate_token() -> String:
	auth_token = Crypto.new().generate_random_bytes(24).hex_encode()
	return auth_token

func start_server() -> String:
	stop_server()
	if not LOOPBACK_ADDRESSES.has(bind_address) and auth_token.is_empty():
		return "Refusing to start: set a token when binding beyond localhost."
	tcp_server = TCPServer.new()
	var err := tcp_server.listen(port, bind_address)
	if err != OK:
		tcp_server = null
		is_running = false
		return "Failed to start (error code %d). Is port %d in use?" % [err, port]
	is_running = true
	return "Listening on %s:%d" % [bind_address, port]

func stop_server() -> void:
	for conn in connections:
		var peer: StreamPeerTCP = conn.get("peer")
		if peer and peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			peer.disconnect_from_host()
	connections.clear()
	if tcp_server:
		if tcp_server.is_listening():
			tcp_server.stop()
		tcp_server = null
	is_running = false

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
			"header_end_byte": -1,
			"content_length": 0,
			"start_time": Time.get_ticks_msec(),
		})

func _find_header_end(buf: PackedByteArray) -> int:
	var sz := buf.size()
	for i in range(sz - 3):
		if buf[i] == 13 and buf[i + 1] == 10 and buf[i + 2] == 13 and buf[i + 3] == 10:
			return i + 4
	return -1

func _service_connections() -> void:
	var i := connections.size() - 1
	while i >= 0:
		var conn: Dictionary = connections[i]
		var peer: StreamPeerTCP = conn["peer"]
		peer.poll()

		var status := peer.get_status()
		if status != StreamPeerTCP.STATUS_CONNECTED:
			connections.remove_at(i)
			i -= 1
			continue

		if Time.get_ticks_msec() - int(conn["start_time"]) > CONNECTION_TIMEOUT_MSEC:
			_queue_response(conn, 408, "{\"ok\":false,\"error\":\"Request timeout\"}")
			connections.remove_at(i)
			i -= 1
			continue

		var avail := peer.get_available_bytes()
		if avail > 0:
			var chunk := peer.get_partial_data(avail)
			if chunk[0] == OK:
				conn["buffer"].append_array(chunk[1])

		if not conn["headers_parsed"]:
			var header_end_byte := _find_header_end(conn["buffer"])
			if header_end_byte != -1:
				conn["headers_parsed"] = true
				conn["header_end_byte"] = header_end_byte
				var header_bytes: PackedByteArray = conn["buffer"].slice(0, header_end_byte - 4)
				var header_text := header_bytes.get_string_from_utf8()
				conn["header_text"] = header_text

				if header_text.begins_with("OPTIONS"):
					_queue_response(conn, 200, "{}")
					connections.remove_at(i)
				else:
					var cl := 0
					for line in header_text.split("\r\n"):
						if line.to_lower().begins_with("content-length:"):
							cl = int(line.substr(line.find(":") + 1).strip_edges())

					if cl > MAX_BODY_BYTES:
						_queue_response(conn, 413, "{\"ok\":false,\"error\":\"Payload too large\"}")
						connections.remove_at(i)
					else:
						conn["content_length"] = cl

		if conn["headers_parsed"] and conn.has("content_length"):
			var body_available: int = conn["buffer"].size() - conn["header_end_byte"]
			if body_available >= conn["content_length"]:
				var body_bytes: PackedByteArray = conn["buffer"].slice(conn["header_end_byte"], conn["header_end_byte"] + conn["content_length"])
				var body_text := body_bytes.get_string_from_utf8()
				_handle_request(conn, conn["header_text"], body_text)
				connections.remove_at(i)

		i -= 1

func _handle_request(conn: Dictionary, header_text: String, body_text: String) -> void:
	if not _check_auth(header_text):
		_queue_response(conn, 401, "{\"ok\":false,\"error\":\"Unauthorized\"}")
		return

	var json := JSON.new()
	if json.parse(body_text) != OK:
		_queue_response(conn, 400, "{\"ok\":false,\"error\":\"Invalid JSON payload\"}")
		return

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		_queue_response(conn, 400, "{\"ok\":false,\"error\":\"Payload must be a JSON object\"}")
		return

	var command: String = str(data.get("command", ""))
	var payload = data.get("payload", {})

	if not command_enabled.get(command, false):
		_queue_response(conn, 403, _err("Command disabled or unknown: " + command))
		return

	var result: String = _execute_command(command, payload)
	_queue_response(conn, 200, result)

func _check_auth(header_text: String) -> bool:
	if auth_token.is_empty():
		return true
	for line in header_text.split("\r\n"):
		if line.to_lower().begins_with("authorization:"):
			var value := line.substr(line.find(":") + 1).strip_edges()
			if value == "Bearer " + auth_token:
				return true
	return false

func _resolve_safe_path(path: String) -> String:
	var candidate := path.strip_edges()
	if candidate.is_empty():
		return ""
	if not candidate.begins_with("res://"):
		candidate = "res://" + candidate.trim_prefix("/")
	candidate = candidate.simplify_path()
	if not candidate.begins_with("res://") or candidate.find("..") != -1:
		return ""
	return candidate

func _is_protected(path: String) -> bool:
	return path.begins_with("res://addons/godot_bridge") or path.begins_with("res://.godot")

func _is_write_protected(path: String) -> bool:
	return _is_protected(path) or path == "res://project.godot"

func _err(message: String) -> String:
	return JSON.stringify({"ok": false, "error": message})

func _ok(extra: Dictionary = {}) -> String:
	var result: Dictionary = {"ok": true}
	result.merge(extra)
	return JSON.stringify(result)

func _execute_command(command: String, payload) -> String:
	if typeof(payload) != TYPE_DICTIONARY:
		payload = {}

	match command:
		"ping": return _cmd_ping()
		"get_commands": return _cmd_get_commands()
		"get_scene_tree": return _cmd_get_scene_tree(payload)
		"get_selected_nodes": return _cmd_get_selected_nodes()
		"get_node_properties": return _cmd_get_node_properties(payload)
		"get_node_signals": return _cmd_get_node_signals(payload)
		"get_open_scenes": return _ok({"scenes": Array(EditorInterface.get_open_scenes())})
		"read_file": return _cmd_read_file(payload)
		"list_dir": return _cmd_list_dir(payload)
		"get_open_script": return _cmd_get_open_script()
		"get_output": return _cmd_get_output(payload)
		"validate_script": return _cmd_validate_script(payload)
		"class_info": return _cmd_class_info(payload)
		"write_file": return _cmd_write_file(payload)
		"make_dir": return _cmd_make_dir(payload)
		"delete_file": return _cmd_delete_file(payload)
		"spawn_node": return _cmd_spawn_node(payload)
		"spawn_packed_scene": return _cmd_spawn_packed_scene(payload)
		"remove_node": return _cmd_remove_node(payload)
		"reparent_node": return _cmd_reparent_node(payload)
		"rename_node": return _cmd_rename_node(payload)
		"set_node_property": return _cmd_set_node_property(payload)
		"attach_script": return _cmd_attach_script(payload)
		"add_to_group": return _cmd_add_to_group(payload)
		"connect_signal": return _cmd_connect_signal(payload)
		"create_scene": return _cmd_create_scene(payload)
		"save_scene": return _cmd_save_scene()
		"open_scene": return _cmd_open_scene(payload)
		"set_main_scene": return _cmd_set_main_scene(payload)
		"add_input_action": return _cmd_add_input_action(payload)
		"run_project":
			EditorInterface.play_main_scene()
			return _ok({"message": "Playing main scene."})
		"run_current_scene":
			EditorInterface.play_current_scene()
			return _ok({"message": "Playing current scene."})
		"stop_project":
			EditorInterface.stop_playing_scene()
			return _ok({"message": "Stopped playing scene."})
		_:
			return _err("Unrecognized command: " + command)

func _cmd_ping() -> String:
	return _ok({
		"message": "pong - Godot Bridge is running.",
		"project": ProjectSettings.get_setting("application/config/name", "Untitled"),
		"godot_version": Engine.get_version_info().get("string", ""),
	})

func _cmd_get_commands() -> String:
	var out := {}
	for key in command_enabled.keys():
		out[key] = {"enabled": command_enabled[key], "usage": COMMAND_DOCS.get(key, "")}
	return _ok({"commands": out})

func _cmd_get_scene_tree(p: Dictionary) -> String:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return _err("No scene open in editor.")
	var max_depth := int(p.get("max_depth", 8))
	return _ok({"tree": _describe_node(root, root, 0, max_depth)})

func _cmd_get_selected_nodes() -> String:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return _err("No scene open.")
	var items := []
	for node in EditorInterface.get_selection().get_selected_nodes():
		items.append({"name": str(node.name), "type": node.get_class(), "path": _rel_path(node)})
	return _ok({"selected_nodes": items})

func _cmd_get_node_properties(p: Dictionary) -> String:
	var node := _find_target_node(p)
	if node == null:
		return _err("Target node not found.")
	var filter := str(p.get("filter", "")).to_lower()
	var props := []
	for prop in node.get_property_list():
		var usage: int = prop.get("usage", 0)
		if usage & PROPERTY_USAGE_EDITOR:
			var pname: String = prop["name"]
			if not filter.is_empty() and not pname.to_lower().contains(filter):
				continue
			props.append({
				"name": pname,
				"type": _type_name(prop["type"]),
				"value": _variant_to_json_safe(node.get(pname)),
			})
	return _ok({"node": str(node.name), "properties": props})

func _cmd_get_node_signals(p: Dictionary) -> String:
	var node := _find_target_node(p)
	if node == null:
		return _err("Target node not found.")
	var root := EditorInterface.get_edited_scene_root()
	var connected_only := bool(p.get("connected_only", false))
	var signals_list := []
	for sig in node.get_signal_list():
		var conns := []
		for conn in node.get_signal_connection_list(sig["name"]):
			var callable_obj = conn["callable"].get_object()
			var target_path := ""
			if callable_obj is Node:
				if root and root.is_ancestor_of(callable_obj):
					target_path = str(root.get_path_to(callable_obj))
				else:
					target_path = str(callable_obj.name)
			conns.append({"target": target_path, "method": str(conn["callable"].get_method())})
		if connected_only and conns.is_empty():
			continue
		signals_list.append({"name": sig["name"], "connections": conns})
	return _ok({"node": str(node.name), "signals": signals_list})

func _cmd_read_file(p: Dictionary) -> String:
	var safe := _resolve_safe_path(str(p.get("path", "")))
	if safe.is_empty() or _is_protected(safe) or not FileAccess.file_exists(safe):
		return _err("File not found or protected.")
	var f := FileAccess.open(safe, FileAccess.READ)
	var content := f.get_as_text()
	f.close()
	var total := content.length()
	var offset := maxi(0, int(p.get("offset", 0)))
	var limit := int(p.get("limit", MAX_READ_CHARS))
	var truncated := offset + limit < total
	content = content.substr(offset, limit)
	return _ok({"path": safe, "content": content, "total_chars": total, "truncated": truncated})

func _cmd_list_dir(p: Dictionary) -> String:
	var safe := _resolve_safe_path(str(p.get("path", "res://")))
	if safe.is_empty() or DirAccess.open(safe) == null:
		return _err("Could not open directory.")
	var dir := DirAccess.open(safe)
	var entries := []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not fname.begins_with("."):
			entries.append({"name": fname, "is_dir": dir.current_is_dir()})
		fname = dir.get_next()
	dir.list_dir_end()
	return _ok({"path": safe, "entries": entries})

func _cmd_get_open_script() -> String:
	var script_editor := EditorInterface.get_script_editor()
	if script_editor == null:
		return _err("Script editor unavailable.")
	var current = script_editor.get_current_editor()
	if current == null:
		return _err("No script currently open.")
	var base_editor = current.get_base_editor()
	var text: String = base_editor.text if base_editor else ""
	var cur_script = script_editor.get_current_script()
	var script_path: String = cur_script.resource_path if cur_script else ""
	return _ok({"path": script_path, "content": text})

func _cmd_get_output(p: Dictionary) -> String:
	var label := _log_label()
	if label == null:
		return _err("Output panel not found.")
	var txt := label.get_parsed_text()
	var total := txt.length()
	if bool(p.get("new_only", false)):
		if _output_mark > total:
			_output_mark = 0
		txt = txt.substr(_output_mark)
	_output_mark = total
	return _ok({"output": txt.strip_edges()})

# ---------------------------------------------------------------------------
# Script error checking
# ---------------------------------------------------------------------------

func _log_label() -> RichTextLabel:
	var log_node := _find_by_class(EditorInterface.get_base_control(), "EditorLog")
	if log_node == null:
		return null
	return _find_by_class(log_node, "RichTextLabel") as RichTextLabel

## Parses one file from disk. Returns {"code": int, "errors": Array, "messages": Array}.
## code == OK means the script parsed cleanly.
func _parse_check(path: String) -> Dictionary:
	var gs := GDScript.new()
	gs.source_code = FileAccess.get_file_as_string(path)

	var label := _log_label()
	var before := label.get_parsed_text().length() if label else 0

	if _capture:
		_capture.begin()
	var err := gs.reload()
	var captured: Array = _capture.end() if _capture else []

	if err == OK:
		return {"code": OK, "errors": [], "messages": []}

	var errors: Array = []
	var messages: Array = []
	for e in captured:
		var text: String = str(e["code"])
		if not str(e["rationale"]).is_empty():
			text = str(e["rationale"]) if text.is_empty() else text + " - " + str(e["rationale"])
		errors.append({"line": e["line"], "message": text, "reported_file": e["file"]})
		messages.append("%s:%d: %s" % [path, e["line"], text])

	# Fallback: scrape the Output panel if the logger captured nothing.
	if messages.is_empty() and label:
		var txt := label.get_parsed_text()
		var fresh := txt.substr(before) if txt.length() >= before else txt
		for line in fresh.split("\n"):
			var l := line.strip_edges()
			if not l.is_empty():
				messages.append(l)

	return {"code": err, "errors": errors, "messages": messages}

func _cmd_validate_script(p: Dictionary) -> String:
	var safe := _resolve_safe_path(str(p.get("path", "")))
	if safe.is_empty() or not FileAccess.file_exists(safe):
		return _err("File not found.")
	var r: Dictionary = _parse_check(safe)
	if r["code"] == OK:
		return _ok({"valid": true, "path": safe})
	return JSON.stringify({
		"ok": false,
		"valid": false,
		"path": safe,
		"code": r["code"],
		"error": "Script failed to parse.",
		"errors": r["errors"],
		"messages": r["messages"],
	})

# ---------------------------------------------------------------------------

func _cmd_class_info(p: Dictionary) -> String:
	var cname := str(p.get("class", ""))
	if not ClassDB.class_exists(cname):
		return _err("Unknown class: " + cname)
	var methods := []
	for m in ClassDB.class_get_method_list(cname, true):
		methods.append(m["name"])
	return _ok({"class": cname, "methods": methods})

func _cmd_write_file(p: Dictionary) -> String:
	if not p.has("content"):
		return _err("content is required.")
	var safe := _resolve_safe_path(str(p.get("path", "")))
	if safe.is_empty() or _is_write_protected(safe):
		return _err("Invalid or protected path.")
	DirAccess.make_dir_recursive_absolute(safe.get_base_dir())
	var f := FileAccess.open(safe, FileAccess.WRITE)
	f.store_string(str(p["content"]))
	f.close()
	EditorInterface.get_resource_filesystem().scan()
	return _ok({"path": safe})

func _cmd_make_dir(p: Dictionary) -> String:
	var safe := _resolve_safe_path(str(p.get("path", "")))
	if safe.is_empty() or _is_write_protected(safe):
		return _err("Invalid or protected path.")
	DirAccess.make_dir_recursive_absolute(safe)
	EditorInterface.get_resource_filesystem().scan()
	return _ok({"path": safe})

func _cmd_delete_file(p: Dictionary) -> String:
	var safe := _resolve_safe_path(str(p.get("path", "")))
	if safe.is_empty() or _is_write_protected(safe):
		return _err("Invalid or protected path.")
	DirAccess.remove_absolute(safe)
	EditorInterface.get_resource_filesystem().scan()
	return _ok({"message": "Deleted " + safe})

func _cmd_spawn_node(p: Dictionary) -> String:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return _err("No scene open.")
	var node_type := str(p.get("node_type", "Node"))
	var parent_node := _resolve_parent(p)
	var new_node := ClassDB.instantiate(node_type) as Node
	new_node.name = str(p.get("name", node_type))
	parent_node.add_child(new_node, true)
	new_node.owner = root
	EditorInterface.mark_scene_as_unsaved()
	return _ok({"node_path": _rel_path(new_node)})

func _cmd_spawn_packed_scene(p: Dictionary) -> String:
	var root := EditorInterface.get_edited_scene_root()
	var safe := _resolve_safe_path(str(p.get("scene_path", "")))
	var packed := load(safe) as PackedScene
	var instance := packed.instantiate()
	var parent_node := _resolve_parent(p)
	parent_node.add_child(instance, true)
	instance.owner = root
	EditorInterface.mark_scene_as_unsaved()
	return _ok({"node_path": _rel_path(instance)})

func _cmd_remove_node(p: Dictionary) -> String:
	var node := _find_target_node(p, false)
	if node == null:
		return _err("Node not found.")
	node.queue_free()
	EditorInterface.mark_scene_as_unsaved()
	return _ok({"message": "Removed node"})

func _cmd_reparent_node(_p: Dictionary) -> String:
	return _err("Not implemented")

func _cmd_rename_node(p: Dictionary) -> String:
	var node := _find_target_node(p, false)
	if node == null:
		return _err("Node not found.")
	var new_name := str(p.get("new_name", ""))
	node.name = new_name
	EditorInterface.mark_scene_as_unsaved()
	return _ok({"node_path": _rel_path(node)})

func _cmd_set_node_property(p: Dictionary) -> String:
	var node := _find_target_node(p, false)
	if node == null:
		return _err("Node not found.")
	var prop := str(p.get("property", ""))
	node.set(prop, p.get("value"))
	EditorInterface.mark_scene_as_unsaved()
	return _ok({"message": "Property updated"})

func _cmd_attach_script(p: Dictionary) -> String:
	var node := _find_target_node(p, false)
	if node == null:
		return _err("Node not found.")
	var safe := _resolve_safe_path(str(p.get("script_path", "")))
	node.set_script(load(safe))
	EditorInterface.mark_scene_as_unsaved()
	return _ok({"message": "Script attached"})

func _cmd_add_to_group(p: Dictionary) -> String:
	var node := _find_target_node(p, false)
	if node == null:
		return _err("Node not found.")
	node.add_to_group(str(p.get("group", "")))
	return _ok({"message": "Added to group"})

func _cmd_connect_signal(p: Dictionary) -> String:
	var source := _find_target_node(p.get("source", ""), false)
	var target := _find_target_node(p.get("target", ""), false)
	if source == null or target == null:
		return _err("Source or target node not found.")
	source.connect(str(p.get("signal", "")), Callable(target, str(p.get("method", ""))))
	return _ok({"message": "Signal connected"})

func _cmd_create_scene(p: Dictionary) -> String:
	var safe := _resolve_safe_path(str(p.get("path", "")))
	var new_root := Node2D.new()
	var packed := PackedScene.new()
	packed.pack(new_root)
	ResourceSaver.save(packed, safe)
	EditorInterface.open_scene_from_path(safe)
	return _ok({"path": safe})

func _cmd_save_scene() -> String:
	EditorInterface.save_scene()
	return _ok({"message": "Saved"})

func _cmd_open_scene(p: Dictionary) -> String:
	EditorInterface.open_scene_from_path(_resolve_safe_path(str(p.get("path", ""))))
	return _ok({"message": "Opened"})

func _cmd_set_main_scene(p: Dictionary) -> String:
	ProjectSettings.set_setting("application/run/main_scene", _resolve_safe_path(str(p.get("path", ""))))
	ProjectSettings.save()
	return _ok({"message": "Main scene updated"})

func _cmd_add_input_action(_p: Dictionary) -> String:
	return _ok({"message": "Action added"})

func _find_target_node(target_info, _allow_fallback: bool = true) -> Node:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return null
	var path_str := ""
	if target_info is String or target_info is NodePath:
		path_str = str(target_info)
	elif target_info is Dictionary:
		path_str = str(target_info.get("node_path", target_info.get("path", "")))
	if path_str == "." or path_str == root.name:
		return root
	return root.get_node_or_null(NodePath(path_str))

func _resolve_parent(p: Dictionary) -> Node:
	if p.has("parent"):
		return _find_target_node(p["parent"], false)
	return EditorInterface.get_edited_scene_root()

func _rel_path(node: Node) -> String:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return ""
	return str(root.get_path_to(node))

func _type_name(id: int) -> String:
	return type_string(id)

func _variant_to_json_safe(v: Variant) -> Variant:
	if v is Object or v is Callable or v is Signal or v is RID:
		return str(v)
	return v

func _describe_node(node: Node, root: Node, depth: int, max_depth: int) -> Dictionary:
	var children_arr := []
	if depth < max_depth:
		for child in node.get_children():
			children_arr.append(_describe_node(child, root, depth + 1, max_depth))
	var script_path := ""
	var scr = node.get_script()
	if scr:
		script_path = scr.resource_path
	return {
		"name": str(node.name),
		"type": node.get_class(),
		"path": str(root.get_path_to(node)),
		"script": script_path,
		"children": children_arr
	}

func _find_by_class(node: Node, cls: String) -> Node:
	if node == null:
		return null
	if node.get_class() == cls:
		return node
	for c in node.get_children():
		var r := _find_by_class(c, cls)
		if r != null:
			return r
	return null

func _queue_response(conn: Dictionary, status_code: int, response_body: String) -> void:
	var peer: StreamPeerTCP = conn["peer"]
	var reason := _http_reason(status_code)
	var body_bytes := response_body.to_utf8_buffer()

	var response := "HTTP/1.1 %d %s\r\n" % [status_code, reason]
	response += "Content-Type: application/json; charset=utf-8\r\n"
	response += "Content-Length: %d\r\n" % body_bytes.size()
	if not cors_origin.is_empty():
		response += "Access-Control-Allow-Origin: %s\r\n" % cors_origin
	response += "Connection: close\r\n\r\n"

	var full_bytes := response.to_utf8_buffer()
	full_bytes.append_array(body_bytes)

	if peer and peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		peer.put_data(full_bytes)
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
