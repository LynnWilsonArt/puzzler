# res://Scenes/Puzzle/station_update_clear_button.gd
extends Button

@onready var station_name_line_edit: LineEdit = $"../StationNameLabel/StationNameLineEdit"
@onready var station_url_line_edit: LineEdit = $"../StationUrlLabel/StationUrlLineEdit"
@onready var station_update_station_id: Label = $"../StationUpdateStationID"




func _on_pressed() -> void:
	print("[Puzzle] -> station_update_clear_button -> _on_pressed()]")
	station_name_line_edit.text = ""
	station_url_line_edit.text = ""
	station_update_station_id.text = ""
