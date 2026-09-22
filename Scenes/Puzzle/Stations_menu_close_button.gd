# res://Scenes/Puzzle/Stations_menu_close_button.gd
extends Button


@onready var stations_popup_menu: PopupMenu = $".."


func _on_pressed() -> void:
	print("[Puzzle] -> stations_menu_close_button")
	#stations_popup_menu.hide()
