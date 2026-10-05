extends Node

# --- CONFIGURATION ---
# Paste your default live radio stream URL here
@export var default_url: String = "https://listen.181fm.com/181-kickincountry_128k.mp3"

# --- INTERNAL VARIABLES ---
var radio_player = null
var is_playing: bool = false
var current_volume: float = 0.5

func _ready() -> void:
	# Only initialize if running inside a web browser export
	if OS.has_feature("web"):
		setup_web_radio(default_url)

func setup_web_radio(url: String) -> void:
	# Creates a native browser HTML5 'Audio' object via the Godot JavaScript Bridge
	radio_player = JavaScriptBridge.create_object("Audio", url)
	radio_player.crossOrigin = "anonymous"
	set_volume(current_volume)

# --- PUBLIC INTERFACE ---

## Starts or resumes the live radio stream. 
## IMPORTANT: This MUST be triggered directly by a player action (like a button click)
func play() -> void:
	print("RadioPlayer -> _ready")
	if radio_player and not is_playing:
		radio_player.play()
		is_playing = true

## Pauses the live radio stream.
func pause() -> void:
	print("RadioPlayer -> Pause Stream")
	if radio_player and is_playing:
		radio_player.pause()
		is_playing = false

## Stops playback and resets the stream buffer.
func stop() -> void:
	print("RadioPlayer -> Stop Stream")
	if radio_player:
		radio_player.pause()
		radio_player.load()
		is_playing = false

## Changes to a new stream on the fly. Resumes automatically if already playing.
func change_station(new_url: String) -> void:
	print("RadioPlayer -> Change Statuin: ",new_url)
	if not radio_player:
		# Fallback if initialized outside of _ready
		setup_web_radio(new_url)
		return
		
	radio_player.pause()
	radio_player.src = new_url
	radio_player.load()
	
	if is_playing:
		radio_player.play()

## Adjusts the volume. Value must be a float between 0.0 (mute) and 1.0 (max).
func set_volume(value: float) -> void:
	print("RadioPlayer -> Set Volume")
	current_volume = clamp(value, 0.0, 1.0)
	if radio_player:
		radio_player.volume = current_volume

## Returns whether the radio is currently streaming.
func is_radio_playing() -> bool:
	print("RadioPlayer -> Is Playing: ",is_playing)
	return is_playing
