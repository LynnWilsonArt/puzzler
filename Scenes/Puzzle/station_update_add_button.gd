# res://Scenes/Puzzle/station_update_add_button.gd
extends Button

@onready var stations_popup_menu: PopupMenu = $"../../../PanelContainer/PuzzleOpenMenuButton/PuzzlePopupMenu/StationsPopupMenu"
@onready var station_url_line_edit: LineEdit = $"../StationUrlLabel/StationUrlLineEdit"
@onready var station_name_line_edit: LineEdit = $"../StationNameLabel/StationNameLineEdit"
@onready var settings_ui: Control = $"../../../PanelContainer/PuzzleOpenMenuButton/SettingsUI"


signal radio_on

func _ready() -> void:
	radio_on.connect(settings_ui._on_music_on_pressed)

func _on_pressed() -> void:
	# remove unwanter characters like /n
	var url = station_url_line_edit.text
	var station_name = station_name_line_edit.text	
	stations_popup_menu.add_station(url,station_name)
	radio_on.emit()
	Radio.change_station(url)
