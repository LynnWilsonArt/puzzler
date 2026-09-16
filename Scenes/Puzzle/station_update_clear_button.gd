extends Button

@onready var station_name_line_edit: LineEdit = $"../StationNameLabel/StationNameLineEdit"
@onready var station_url_line_edit: LineEdit = $"../StationUrlLabel/StationUrlLineEdit"
@onready var station_update_station_id: Label = $"../StationUpdateStationID"




func _on_pressed() -> void:
	station_name_line_edit.text = ""
	station_url_line_edit.text = ""
	station_update_station_id.text = ""
