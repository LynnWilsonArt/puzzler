extends Node

# --- CONFIGURATION ---
# Default live radio stream URL (remembered at startup, NOT loaded or played)
@export var default_url: String = "https://listen.181fm.com/181-kickincountry_128k.mp3"

# --- INTERNAL VARIABLES ---
var radio_player: JavaScriptObject = null
var audio_ctx: JavaScriptObject = null
var gain_node: JavaScriptObject = null
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
	_cb_playing = JavaScriptBridge.create_callback(func(_a): is_playing = true)
	_cb_stopped = JavaScriptBridge.create_callback(func(_a): is_playing = false)
	radio_player.addEventListener("playing", _cb_playing)
	radio_player.addEventListener("pause", _cb_stopped)
	radio_player.addEventListener("error", _cb_stopped)
	# NOTE: crossOrigin is intentionally NOT set. If you get silence after
	# routing through Web Audio, try: radio_player.crossOrigin = "anonymous"
	# (the stream server must then send Access-Control-Allow-Origin).
	_setup_gain()


# iOS mutes all Web Audio (Godot's sound effects included) when the phone's
# silent switch is on. Declaring a "playback" audio session (Safari 16.4+)
# makes it ignore the switch, like a music app.
func _set_ios_audio_session() -> void:
	JavaScriptBridge.eval("if (navigator.audioSession) { navigator.audioSession.type = 'playback'; }", true)


# True on iPhone/iPad (including iPadOS, which reports itself as a Mac).
func _is_ios() -> bool:
	return bool(JavaScriptBridge.eval(
		"/iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1)",
		true))


# iOS ignores HTMLMediaElement.volume, so on iOS only we route the <audio>
# element through a GainNode. Other platforms keep using .volume.
func _setup_gain() -> void:
	var ios := _is_ios()
	print("[RadioPlayer] -> _setup_gain() iOS detected: ", ios)
	if not ios:
		radio_player.volume = current_volume
		return

	var win = JavaScriptBridge.get_interface("window")
	var ctx_name := "AudioContext" if win.AudioContext != null else "webkitAudioContext"
	if win[ctx_name] == null:
		radio_player.volume = current_volume
		return

	# Required for Web Audio: otherwise a cross-origin stream is output as
	# silence. The stream server must send Access-Control-Allow-Origin.
	radio_player.crossOrigin = "anonymous"

	audio_ctx = JavaScriptBridge.create_object(ctx_name)
	gain_node = audio_ctx.createGain()
	gain_node.gain.value = current_volume

	# "connect" / "call" clash with Godot's own Object methods, so the wiring
	# is done in a small JS helper instead.
	JavaScriptBridge.eval("""
		window._radioWire = function(audio, ctx, gain) {
			var src = ctx.createMediaElementSource(audio);
			src.connect(gain);
			gain.connect(ctx.destination);
		};
	""", true)
	win._radioWire(radio_player, audio_ctx, gain_node)
	print("[RadioPlayer] -> iOS gain path active. ctx state: ", audio_ctx.state)


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
	if _is_ios():
		_set_ios_audio_session()
	_ensure_player()
	# iOS starts the context suspended; resume inside the user gesture.
	if audio_ctx and audio_ctx.state != "running":
		audio_ctx.resume()
	radio_player.src = current_url  # connects to the stream now, not before
	print("Radio Playing.", current_url)
	radio_player.play()


## Pauses the live radio stream.
## Drops the connection so pressing Play again rejoins the live stream
## instead of replaying stale buffered audio.
func pause() -> void:
	print("[RadioPLayer] -> Pause Stream")
	_release_stream()


## Stops playback and resets the stream buffer.
## The <audio> element is kept (not nulled) because a media element can only
## be attached to one MediaElementSource for its lifetime.
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
		radio_player.src = new_url  # setting src loads the new stream
		radio_player.play()


## Adjusts the volume. Value must be a float between 0.0 (mute) and 1.0 (max).
func set_volume(value: float) -> void:
	current_volume = clampf(value, 0.0, 1.0)
	if gain_node:
		gain_node.gain.value = current_volume
	elif radio_player:
		radio_player.volume = current_volume


## Returns whether the radio is currently streaming.
func is_radio_playing() -> bool:
	return is_playing
