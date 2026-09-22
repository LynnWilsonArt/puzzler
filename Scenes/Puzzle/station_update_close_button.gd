# res://Scenes/Puzzle/station_update_close_button.gd
extends Button

@onready var station_update_panel: PanelContainer = $"../.."

func _on_pressed() -> void:
	print("[Puzzle] -> Station Update Panel -> station_update_cancel_button.gd -> Hide popup")
	station_update_panel.hide()
