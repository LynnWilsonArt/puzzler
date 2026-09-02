extends Node
## Updater.gd — Godot 4.7 autoload
##
## Checks a PHP endpoint (check_version.php) for a newer app version,
## notifies the rest of the app via signals, and can download + install
## the update.
##
## Setup:
##   1. Add this script as an Autoload named "Updater"
##      (Project Settings > Autoload).
##   2. Set CURRENT_VERSION to match your app's version.
##   3. Set CHECK_URL to your hosted check_version.php.
##   4. Connect to `update_available` and `update_progress` /
##      `update_ready_to_install` / `update_failed` from your UI.

signal update_available(latest_version: String, changelog: String, force_update: bool)
signal no_update_available
signal check_failed(reason: String)
signal update_progress(bytes_downloaded: int, bytes_total: int)
signal update_ready_to_install(file_path: String)
signal update_failed(reason: String)

const CURRENT_VERSION := "1.0.0"
const CHECK_URL := "https://puzzler.lynnwilsonart.com/api_19511969/check_version.php"

var _check_request: HTTPRequest
var _download_request: HTTPRequest
var _pending_download_info := {}  # {"url":..., "sha256":...}
var _download_path := ""


func _ready() -> void:
	_check_request = HTTPRequest.new()
	add_child(_check_request)
	_check_request.request_completed.connect(_on_check_completed)

	_download_request = HTTPRequest.new()
	add_child(_download_request)
	_download_request.use_threads = true
	_download_request.request_completed.connect(_on_download_completed)


## --------------------------------------------------------------------------
## STEP 1: Check for a new version
## --------------------------------------------------------------------------

func check_for_update() -> void:
	var platform := _get_platform_key()
	var url := "%s?current_version=%s&platform=%s" % [
		CHECK_URL, CURRENT_VERSION.uri_encode(), platform
	]
	var err := _check_request.request(url)
	print("Check Version Url: ",url)
	if err != OK:
		check_failed.emit("Failed to start request (error %d)." % err)


func _on_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		check_failed.emit("Version check failed (result=%d, http=%d)." % [result, response_code])
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		check_failed.emit("Could not parse server response.")
		return

	var data: Dictionary = json.get_data()
	if not data.has("update_available"):
		check_failed.emit("Malformed server response.")
		return

	if data["update_available"]:
		_pending_download_info = {
			"url": data.get("download_url", ""),
			"sha256": data.get("sha256", ""),
		}
		update_available.emit(
			data.get("latest_version", "?"),
			data.get("changelog", ""),
			data.get("force_update", false)
		)
	else:
		no_update_available.emit()


## --------------------------------------------------------------------------
## STEP 2: Download the update
## --------------------------------------------------------------------------

func download_update() -> void:
	var url: String = _pending_download_info.get("url", "")
	if url.is_empty():
		update_failed.emit("No download URL available. Call check_for_update() first.")
		return

	var dir := "user://updates"
	DirAccess.make_dir_recursive_absolute(dir)

	var filename := url.get_file()
	if filename.is_empty():
		filename = "update_download"
	_download_path = "%s/%s" % [dir, filename]

	_download_request.download_file = _download_path
	var err := _download_request.request(url)
	if err != OK:
		update_failed.emit("Failed to start download (error %d)." % err)
		return

	# Poll progress on a timer since HTTPRequest doesn't emit progress signals.
	set_process(true)


func _process(_delta: float) -> void:
	if _download_request.get_http_client_status() == HTTPClient.STATUS_BODY:
		update_progress.emit(
			_download_request.get_downloaded_bytes(),
			_download_request.get_body_size()
		)
	else:
		set_process(false)


func _on_download_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	set_process(false)

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		update_failed.emit("Download failed (result=%d, http=%d)." % [result, response_code])
		return

	var expected_sha := String(_pending_download_info.get("sha256", ""))
	if not expected_sha.is_empty():
		var actual_sha := FileAccess.get_sha256(ProjectSettings.globalize_path(_download_path))
		if actual_sha.to_lower() != expected_sha.to_lower():
			update_failed.emit("Checksum mismatch — downloaded file may be corrupt or tampered with.")
			var f := FileAccess.open(_download_path, FileAccess.WRITE)
			# Truncate/remove the bad file.
			if f:
				f.close()
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_download_path))
			return
	print("Ready to install")
	update_ready_to_install.emit(_download_path)


## --------------------------------------------------------------------------
## STEP 3: Install the update
## --------------------------------------------------------------------------
## NOTE: How you "install" depends heavily on how you distribute your app.
## The branches below cover common cases; adjust to match your actual
## packaging (installer .exe, .AppImage, .dmg, or a plain .zip of files).

func install_update(file_path: String) -> void:
	print(" Installing update")
	var global_path := ProjectSettings.globalize_path(file_path)
	var ext := file_path.get_extension().to_lower()

	match ext:
		"exe":
			# Windows installer: launch it, then quit so it can overwrite
			# files that are currently in use.
			OS.create_process(global_path, [])
			get_tree().quit()

		"appimage":
			# Linux AppImage: mark executable, launch the new one, quit old.
			OS.execute("chmod", ["+x", global_path])
			OS.create_process(global_path, [])
			get_tree().quit()

		"dmg":
			# macOS disk image: open it so the user drags the app to
			# Applications (macOS apps generally can't silently self-replace
			# due to Gatekeeper/notarization).
			OS.shell_open(global_path)
			get_tree().quit()

		"zip":
			# Generic zip of app files: extract next to the current
			# executable, then relaunch.
			_extract_zip_and_relaunch(global_path)

		"apk":
			# Android: the OS itself installs APKs, the app can only hand
			# the file to the system package installer and ask the user
			# to approve it. See setup notes below.
			_install_android_apk(global_path)

		_:
			update_failed.emit("Don't know how to install file type: %s" % ext)


func _install_android_apk(global_path: String) -> void:
	if OS.get_name() != "Android":
		update_failed.emit("APK install requested on a non-Android platform.")
		return

	# OS.shell_open() hands the file to Android's system handler, which for
	# a .apk means the package installer UI. Godot's Android export template
	# serves the file through its FileProvider, so a plain path works here
	# without you having to build the content:// URI yourself.
	#
	# This ALWAYS shows a system confirmation dialog — Android does not
	# allow silent self-install, even with permission granted.
	print("Global path for apk")
	
	########################################
	# working here 	
		
	if Engine.has_singleton("ApkInstaller"):
		var plugin = Engine.get_singleton("ApkInstaller")
		plugin.installApk(global_path)
	else:
		push_error("ApkInstaller plugin not found — check Export > Android > Plugins")
	
	
	var err := OS.shell_open(global_path)
	if err != OK:
		update_failed.emit(
			"Could not launch installer (error %d). Check that " % err +
			"REQUEST_INSTALL_PACKAGES is enabled in your export preset " +
			"and the permission has been granted by the user."
		)
	# Do NOT call get_tree().quit() here — the installer runs in a separate
	# system UI on top of your app; quitting isn't necessary and the user
	# needs to see the confirmation dialog complete.


func _extract_zip_and_relaunch(zip_path: String) -> void:
	var reader := ZIPReader.new()
	var err := reader.open(zip_path)
	if err != OK:
		update_failed.emit("Could not open update archive (error %d)." % err)
		return

	var current_exe_path := OS.get_executable_path()
	var install_dir := current_exe_path.get_base_dir()
	var current_exe_name := current_exe_path.get_file()
	var current_exe_ext := current_exe_name.get_extension().to_lower()
	var current_base := current_exe_name.get_basename()
	var current_pck_path := "%s/%s.pck" % [install_dir, current_base]

	var files := reader.get_files()
	print("_extract_zip_and_relaunch() -> zip contains: ", files)
	print("_extract_zip_and_relaunch() -> current executable: ", current_exe_path)
	print("_extract_zip_and_relaunch() -> current pck: ", current_pck_path)

	# Identify which entries are the executable and the .pck by extension,
	# not by position — Godot exports always include a .pck alongside the
	# binary, and both need to overwrite the CURRENT filenames regardless
	# of what the new build happened to be named.
	var exe_entry := ""
	var pck_entry := ""
	for file_name in files:
		if file_name.ends_with("/"):
			continue
		var ext := file_name.get_extension().to_lower()
		if ext == "pck":
			pck_entry = file_name
		elif ext == current_exe_ext or ext in ["x86_64", "x86_32", "exe", "bin", "app"]:
			exe_entry = file_name

	if exe_entry.is_empty():
		update_failed.emit("Could not find an executable inside the update archive.")
		reader.close()
		return

	var write_map := {}
	write_map[exe_entry] = current_exe_path
	if not pck_entry.is_empty():
		write_map[pck_entry] = current_pck_path

	# Anything else in the archive (extra assets, changelog, etc.) gets
	# extracted under its own filename, alongside the app.
	for file_name in files:
		if file_name.ends_with("/") or write_map.has(file_name):
			continue
		write_map[file_name] = "%s/%s" % [install_dir, file_name]

	for file_name in write_map.keys():
		var dest_path: String = write_map[file_name]

		# Remove any existing file first. On Linux this is required for the
		# currently-running executable/pck: a running process holds the old
		# inode open, so a straight overwrite fails with "text file busy".
		# Deleting the path and writing a fresh file is safe — the running
		# process keeps using the old, now-unlinked inode until it exits.
		if FileAccess.file_exists(dest_path):
			DirAccess.remove_absolute(dest_path)

		DirAccess.make_dir_recursive_absolute(dest_path.get_base_dir())
		var out := FileAccess.open(dest_path, FileAccess.WRITE)
		if out:
			out.store_buffer(reader.read_file(file_name))
			out.close()
		else:
			update_failed.emit("Could not write file during update: %s" % dest_path)
			reader.close()
			return

	reader.close()

	# Ensure the new executable is still marked executable — writing a
	# fresh file can come out without the exec bit set.
	OS.execute("chmod", ["+x", current_exe_path])

	print("_extract_zip_and_relaunch() -> relaunching: ", current_exe_path)
	OS.create_process(current_exe_path, [])
	get_tree().quit()


## --------------------------------------------------------------------------
## Helpers
## --------------------------------------------------------------------------

func _get_platform_key() -> String:
	match OS.get_name():
		"Windows":
			return "windows"
		"macOS":
			return "mac"
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return "linux"
		"Android":
			return "android"
		_:
			return "generic"


## --------------------------------------------------------------------------
## Example usage from another script:
##
##   func _ready():
##       Updater.update_available.connect(_on_update_available)
##       Updater.update_ready_to_install.connect(_on_update_ready)
##       Updater.check_for_update()
##
##   func _on_update_available(latest_version, changelog, force_update):
##       # Show a dialog to the user; on confirm:
##       Updater.download_update()
##
##   func _on_update_ready(file_path):
##       Updater.install_update(file_path)
