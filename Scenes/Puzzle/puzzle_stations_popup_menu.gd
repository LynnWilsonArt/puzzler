extends PopupMenu

var stations_array: Array[String] = [
	"https://listen.181fm.com/181-awesome80s_128k.mp3",
	"https://listen.181fm.com/181-realcountry_128k.mp3",
	"https://listen.181fm.com/181-rock_128k.mp3",
	"https://listen.181fm.com/181-soul_128k.mp3", 
	"https://listen.181fm.com/181-beat_128k.mp3",
	"https://listen.181fm.com/181-blues_128k.mp3",
	"https://listen.181fm.com/181-classical_128k.mp3",
	"https://listen.181fm.com/181-classicalguitar_128k.mp3",
	"https://listen.181fm.com/181-classicaljazz_128k.mp3",
]

func _ready() -> void:
	print("Puzzle -> stations_popup_menu.gd -> _ready()")
	if not id_pressed.is_connected(_on_id_pressed):
		id_pressed.connect(_on_id_pressed)
	_load_custom_stations()

func _load_custom_stations() -> void:
	print("Puzzle -> stations_popup_menu.gd -> _load_custom_stations()")
	for url in Settings.custom_stations:
		if not stations_array.has(url):
			stations_array.append(url)
			add_item(url)  # adds a menu row; its id = index in this popup's item list

func add_custom_url(url: String) -> void:
	print("Puzzle -> stations_popup_menu.gd -> add_custom_url(): ", url)
	if url.is_empty() or stations_array.has(url):
		return
	stations_array.append(url)
	add_item(url)
	Settings._add_custom_station(url)

func _on_id_pressed(id: int) -> void:
	print("Puzzle -> stations_popup_menu.gd -> _on_id_pressed()")
	if id >= 0 and id < stations_array.size():
		print("Puzzle -> stations_popup_menu.gd -> Selection: ", id)
		var selected_url: String = stations_array[id]
		Radio.change_station(selected_url)
	else:
		printerr("Puzzle -> stations_popup_menu.gd -> Selected ID %d is out of bounds for stations_array." % id)
