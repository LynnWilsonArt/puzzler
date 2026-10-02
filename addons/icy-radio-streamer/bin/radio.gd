extends Node

var icy_http: IcyHttpStream
var icy_audio_decoder: IcyAudioDecoder
var stream: AudioStreamGenerator

@export var radio_player: AudioStreamPlayer
@onready var timer := $Timer
var station_url: String = "https://listen.181fm.com/181-realcountry_128k.mp3"

func _ready() -> void:
	print("[Radio] -> _ready()")
	stream = radio_player.stream
	icy_http = IcyHttpStream.new()
	
	#region connection
	icy_http.connection_opened.connect(func():
		var response_headers_dict := icy_http.get_response_headers_as_dictionary()
		var content_mime_type := icy_http.get_content_mime_type()

		icy_audio_decoder = IcyAudioDecoder.create_for_mime_type(content_mime_type)

		if not icy_audio_decoder:
			push_error("[Radio] -> Unsupported format or invalid stream: " + content_mime_type)
			icy_http.cancel_request()
			return  # Early return prevents configuring a null decoder

		if response_headers_dict.has("icy-br") and icy_audio_decoder.has_method("set_bitrate_hint"):
			var kbps = int(response_headers_dict["icy-br"])
			icy_audio_decoder.set_bitrate_hint(kbps)
			print("[Radio] -> Bitrate: %d kbps" % kbps)

		icy_audio_decoder.stream_info_ready.connect(func():
			var rate: int = icy_audio_decoder.get_stream_sample_rate()
			print("[Radio] -> Mix rate: %d Hz" % rate)
			stream.mix_rate = rate
			icy_audio_decoder.set_playback(radio_player.get_stream_playback(), stream)
			var frames := int(stream.mix_rate / 2)
			icy_audio_decoder.set_buffer_thresholds(frames)
		)

		if not icy_audio_decoder.buffering_started.is_connected(on_buffering_started):
			icy_audio_decoder.buffering_started.connect(on_buffering_started)
		
		if not icy_audio_decoder.buffering_finished.is_connected(on_buffering_finished):
			icy_audio_decoder.buffering_finished.connect(on_buffering_finished)
		
		radio_player.play()
		radio_player.stream_paused = true
		
		icy_audio_decoder.set_playback(radio_player.get_stream_playback())
		icy_http.set_audio_decoder(icy_audio_decoder)
	)
	print("[Radio] -> End of _ready()")
	#endregion
	
	icy_http.connection_closed.connect(func(result: IcyHttpStream.Result):
		print("[Radio] -> Icy Connection closed: ", result)
		
		# Safely disconnect buffering signals only if the decoder was successfully created
		if icy_audio_decoder:
			if icy_audio_decoder.buffering_started.is_connected(on_buffering_started):
				icy_audio_decoder.buffering_started.disconnect(on_buffering_started)
				
			if icy_audio_decoder.buffering_finished.is_connected(on_buffering_finished):
				icy_audio_decoder.buffering_finished.disconnect(on_buffering_finished)
			
			# Clear reference so stale states don't linger
			icy_audio_decoder = null
	)
	
	icy_http.metadata_received.connect(func(metadata: String):
		print("[Radio] -> Metadata: ", metadata)
	)
	
	start_radio()
	
	timer.wait_time = stream.buffer_length / 4.0
	timer.ignore_time_scale = true
	timer.timeout.connect(func():
		if icy_audio_decoder:
			icy_audio_decoder.process_audio()
	)
	timer.start()

func change_station(selected_url) -> void:
	station_url = selected_url
	print("[Radio] -> change_station() -> Station URL: ", selected_url)
	stop_radio()
	start_radio()
	print("[Radio] -> Stations popupMenu -> await 3 seconds") 
	await get_tree().create_timer(3.0, true, true).timeout
	print("[Radio] -> Stations popupMenu -> Settings._apply_settings()")
	Settings._apply_settings()
		
func start_radio() -> void:
	print("[Radio] -> start_radio() -> station_url: ", station_url)
	var request_headers: PackedStringArray = ["User-Agent: Godot/4.5"]
	icy_http.request(station_url, 5.0, true, request_headers)

func stop_radio() -> void:
	print("[Radio] -> stop_radio()")
	icy_http.cancel_request()
	radio_player.stop()

func on_buffering_started() -> void:
	print("[Radio] -> on_buffering_started()")
	print("[Radio] -> Buffering started (underrun detected)")
	radio_player.stream_paused = true
	
func on_buffering_finished() -> void:
	print("[Radio] -> on_buffering_finished()")
	print("[Radio] -> SUCCESS! Buffering complete. Pausing playback.")
	radio_player.stream_paused = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if icy_http:
			if icy_http.is_requesting():
				stop_radio()
			else:
				start_radio()
