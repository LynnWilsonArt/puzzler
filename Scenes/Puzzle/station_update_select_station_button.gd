# res://Scenes/Puzzle/station_update_select_station_button.gd
extends Button

@onready var stations_popup_menu: PopupMenu = $"../../../PanelContainer/PuzzleOpenMenuButton/PuzzlePopupMenu/StationsPopupMenu"

func _on_pressed() -> void:
	stations_popup_menu.show()
