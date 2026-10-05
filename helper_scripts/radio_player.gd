extends Node

# --- CONFIGURATION ---
# Default live radio stream URL (remembered at startup, NOT loaded or played)
@export var default_url: String = "https://listen.181fm.com/181-kickincountry_128k.mp3"

# --- INTERNAL VARIABLES ---
var radio_player: JavaScriptObject = null
var is_playing: bool = false
var current_volume: float = 0.5
var current_url: String = ""
var _cb_playing: JavaScriptObject
var _cb_stopped: JavaScriptObject


func _ready() -> void:
	# Setup only: no audio element, no network request, no playback.
	current_url = default_url


# Creates the browser <audio> element the first time it's needed.
func _ensure_player() -> void:
	print("_ensure_player()")
	if radio_player or not OS.has_feature("web"):
		return
	radio_player = JavaScriptBridge.create_object("Audio")
	radio_player.preload = "none"  # don't download anything until play()
	radio_player.volume = current_volume
	_cb_playing = JavaScriptBridge.create_callback(func(_a): is_playing = true)
	_cb_stopped = JavaScriptBridge.create_callback(func(_a): is_playing = false)
	radio_player.addEventListener("playing", _cb_playing)
	radio_player.addEventListener("pause", _cb_stopped)
	radio_player.addEventListener("error", _cb_stopped)
	# NOTE: crossOrigin is intentionally NOT set. "anonymous" makes the browser
	# reject any stream whose server doesn't send CORS headers. Plain playback
	# doesn't need it.


# --- PUBLIC INTERFACE ---

## Starts the live radio stream.
## IMPORTANT: This MUST be triggered directly by a player action (like a button click).
func play() -> void:
	
	print("[RadioPLayer] -> Play() Stream")
	if is_playing or current_url.is_empty():
		print("Is Playing or no url returning")
		return
	if not OS.has_feature("web"):
		return
	_ensure_player()
	radio_player.src = current_url  # connects to the stream now, not before
	print("Called from play()")
	radio_player.play()
	print("Radio Playing.",current_url)
	


## Pauses the live radio stream.
## Drops the connection so pressing Play again rejoins the live stream
## instead of replaying stale buffered audio.
func pause() -> void:
	print("[RadioPLayer] -> Pause Stream")
	_release_stream()


## Stops playback and resets the stream buffer.
func stop() -> void:
	print("[RadioPLayer] -> Stop Stream")
	_release_stream()


func _release_stream() -> void:
	if radio_player:
		radio_player.pause()
		radio_player.removeAttribute("src")
		radio_player.load()
	is_playing = false


## Changes the station. Switches immediately if already playing,
## otherwise just remembers it until Play is pressed.
func change_station(new_url: String) -> void:
	print("[RadioPLayer] -> Change Station: ", new_url)
	current_url = new_url
	if is_playing and radio_player:
		print("Called from ()")
		radio_player.src = new_url  # setting src loads the new stream
		radio_player.play()


## Adjusts the volume. Value must be a float between 0.0 (mute) and 1.0 (max).
func set_volume(value: float) -> void:
	current_volume = clampf(value, 0.0, 1.0)
	if radio_player:
		radio_player.volume = current_volume


## Returns whether the radio is currently streaming.
func is_radio_playing() -> bool:
	return is_playing
