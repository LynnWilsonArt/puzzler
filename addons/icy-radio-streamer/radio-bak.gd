# res://assets/addons/icy-radio-streamer/[Radio]
extends Node

var icy_http: IcyHttpStream
var icy_audio_decoder: IcyAudioDecoder
var stream: AudioStreamGenerator

@export var radio_player: AudioStreamPlayer
@onready var timer := $Timer
var station_url: String = "https://listen.181fm.com/181-realcountry_128k.mp3"

func _ready() -> void:
	print("[Radio] -> _ready()")
	# stream assigned to radio_player must be an AudioStreamGenerator
	stream = radio_player.stream
	icy_http = IcyHttpStream.new()
	
	#region connection
	icy_http.connection_opened.connect(func():
		var response_headers_dict := icy_http.get_response_headers_as_dictionary()
		var content_mime_type := icy_http.get_content_mime_type()

		# ask the addon's decoder registry for a decoder matching the stream's content type.
		# built-in decoders (currently just MP3) register themselves for their MIME type at
		# extension init time, so a future native decoder module can add its own MIME type
		# mapping without this script needing to change.
		icy_audio_decoder = IcyAudioDecoder.create_for_mime_type(content_mime_type)

		if icy_audio_decoder:
			# (optional) check for bitrate information.
			# if it is unavailable the decoder assumes a standard 128 kbps MP3 stream
			if response_headers_dict.has("icy-br") and icy_audio_decoder.has_method("set_bitrate_hint"):
				var kbps = int(response_headers_dict["icy-br"])
				icy_audio_decoder.set_bitrate_hint(kbps)
				print("[Radio] -> Bitrate: %d kbps" % kbps)

			# wait for the decoder to detect the stream format information
			icy_audio_decoder.stream_info_ready.connect(func():
				# calculate the appropriate sample rate for the generator,
				# and buffer thresholds for the decoder.
				# the sample rate could also be read from the response headers,
				# but information obtained directly from the codec is more reliable
				var rate: int = icy_audio_decoder.get_stream_sample_rate()
				print("[Radio] -> Mix rate: %d Hz" % rate)
				stream.mix_rate = rate

				# re-attach the playback now that the generator's final mix_rate is known,
				# so the decoder derives max buffer capacity from the generator itself
				icy_audio_decoder.set_playback(radio_player.get_stream_playback(), stream)

				var frames := int(stream.mix_rate / 2)
				icy_audio_decoder.set_buffer_thresholds(frames)
			)
		else:
			push_error("[Radio] -> Unsupported format: " + content_mime_type)
			icy_http.cancel_request()

		if icy_audio_decoder:
			# connect buffering signals to pause playback when no audio data is available
			if not icy_audio_decoder.buffering_started.is_connected(on_buffering_started):
				icy_audio_decoder.buffering_started.connect(on_buffering_started)
			
			if not icy_audio_decoder.buffering_finished.is_connected(on_buffering_finished):
				icy_audio_decoder.buffering_finished.connect(on_buffering_finished)
			
			# start playback and immediately pause it so we can obtain the playback object
			# buffering signals will resume playback once enough data has been buffered
			radio_player.play()
			radio_player.stream_paused = true
			
			icy_audio_decoder.set_playback(radio_player.get_stream_playback())
			# decoder is ready, attach it to the IcyHttpStream so audio playback can begin
			icy_http.set_audio_decoder(icy_audio_decoder)
	)
	print("[Radio] -> End of _ready()")
	#endregion
	
	icy_http.connection_closed.connect(func(result: IcyHttpStream.Result):
		print("[Radio] -> Icy Connection closed: ", result)
		
		# disconnect the buffering signals when connections closes so they won't report false buffering
		if icy_audio_decoder.buffering_started.is_connected(on_buffering_started):
			icy_audio_decoder.buffering_started.disconnect(on_buffering_started)
			
		if icy_audio_decoder.buffering_finished.is_connected(on_buffering_finished):
			icy_audio_decoder.buffering_finished.disconnect(on_buffering_finished)
	)
	
	icy_http.metadata_received.connect(func(metadata: String):
		print("[Radio] -> Metadata: ", metadata)
	)
	
	start_radio()
	
	# the decoder's process_audio() method must be called
	# to play accumulated audio data through the AudioStreamGenerator
	
	# this method can also be called from _process() or _physics_process()
	# the decoder will automatically adjust the size of read operations
	# to fill the available space in the AudioStreamGenerator buffer
	
	# though, it's better to grab larger chunks of data less often if possible,
	# so we're using timer set to quarter the generator buffer length (0.5s in this case)
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
	Radio.stop_radio()
	Radio.start_radio()
	# Wait till initilized then Unpause the stream
	print("[Radio] -> Stations popupMenu -> await 3 seconds") 
	await get_tree().create_timer(3.0, true, true).timeout
	print("[Radio] -> Stations popupMenu -> Settings._apply_settings()")
	Settings._apply_settings() # apply and save settings
		
func start_radio() -> void:
	print("[Radio] -> start_radio() -> station_url: ",station_url)
	var request_headers: PackedStringArray = ["User-Agent: Godot/4.5"];
	icy_http.request(station_url, 5.0, true, request_headers)

func stop_radio() -> void:
	print("[Radio] -> stop_radio()")
	icy_http.cancel_request()
	# the last audio bytes will still play because the generator buffer 
	# have to be drained completely, so we stop audio manually
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
