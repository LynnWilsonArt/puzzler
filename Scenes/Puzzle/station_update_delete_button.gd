# res://Scenes/Puzzle/station_update_delete_button.gd
extends Button

@onready var stations_popup_menu: PopupMenu = $"../../../PanelContainer/PuzzleOpenMenuButton/PuzzlePopupMenu/StationsPopupMenu"
@onready var station_update_station_id: Label = $"../StationUpdateStationID"


func _on_pressed() -> void:
	print("Station id label:  ",station_update_station_id.text)
	var id: int = station_update_station_id.text.to_int()
	print("Station ID to delete:  ",id)
	stations_popup_menu.delete_station_at(id)
