extends Button


@onready var stations_popup_menu: PopupMenu = $".."


func _on_pressed() -> void:
	stations_popup_menu.hide()
