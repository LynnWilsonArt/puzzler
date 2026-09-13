# res://assets/addons/icy-radio-streamer/stations_popup_menu.gd
extends PopupMenu

# Use a typed Array for better autocompletion and safety
var stations_array: Array[String] = [
	"https://listen.181fm.com/181-awesome80s_128k.mp3",
	"https://listen.181fm.com/181-realcountry_128k.mp3",
	"https://listen.181fm.com/181-rock_128k.mp3",
	"https://listen.181fm.com/181-soul_128k.mp3", 
	"https://listen.181fm.com/181-beat_128k.mp3",
	"https://listen.181fm.com/181-blues_128k.mp3",
	"https://listen.181fm.com/181-classical_128k.mp3",
	"https://listen.181fm.com/181-classicalguitar_128k.mp3",
	"https://listen.181fm.com/181-classicaljazz_128k.mp3"
]

func _ready() -> void:
	print("stations_popup_menu.gd -> _ready()")
	# Ensure the signal is connected (if not connected in the Inspector)
	if not id_pressed.is_connected(_on_id_pressed):
		id_pressed.connect(_on_id_pressed)

func _on_id_pressed(id: int) -> void:
	print("stations_popup_menu.gd -> _on_id_pressed()")
	
	# Use the ID directly to lookup the station instead of duplicating code in a match block
	if id >= 0 and id < stations_array.size():
		print("stations_popup_menu.gd -> Selection: ", id)
		var selected_url: String = stations_array[id]
		Radio.change_station(selected_url)
	else:
		printerr("Selected ID %d is out of bounds for stations_array." % id)
