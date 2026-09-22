# res://Scenes/Puzzle/station_update_edit_button.gd
extends Button
@onready var station_name_line_edit: LineEdit = $"../StationNameLabel/StationNameLineEdit"
@onready var station_url_line_edit: LineEdit = $"../StationUrlLabel/StationUrlLineEdit"
@onready var stations_popup_menu: PopupMenu = $"../../../PanelContainer/PuzzleOpenMenuButton/PuzzlePopupMenu/StationsPopupMenu"
@onready var station_update_station_id: Label = $"../StationUpdateStationID"
@onready var settings_ui: Control = $"../../../SettingsUI"

signal radio_on

func _ready() -> void:
	radio_on.connect(settings_ui._on_music_on_pressed)
	
func _on_pressed() -> void:
	print("[Puzzle] -> station_update_edit_button -> _n_pressed()")
	print("[Puzzle] -> station_update_edit_button -> Station ID:  ",station_update_station_id.text.to_int())
	print("[Puzzle] ->station_update_edit_button -> Station Name: ",station_name_line_edit.text)
	stations_popup_menu.edit_station_at(station_update_station_id.text.to_int(),station_name_line_edit.text,station_url_line_edit.text)
	
	# turn on radio if its off
	radio_on.emit()
	
