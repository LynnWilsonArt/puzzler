# res://Scenes/Puzzle/StationsPopupMenuCloseButtonbutton.gd
extends Button

@onready var stations_popup_menu: PopupMenu = $".."

func _on_pressed() -> void:
	print("[Puzzle] -> StationsPopupMenuCloseButtonbutton.gd -> _on_pressed()")
	stations_popup_menu.hide()
