extends Button
# File: res://scene/Puzzle/open_menu_button.gd

# The PopupMenu is a sibling of this Button:
@onready var popup_menu : PopupMenu = $"../PopupMenu"

func _ready() -> void:
	# DEBUG
	print("Puzzle -> open_menu_button.gd -> _ready()")
		
	# Hide on startup
	popup_menu.hide()


func _on_pressed() -> void:
	# DEBUG
	print(" Puzzle -> open_menu_button.gd -> _on_pressed()")
	popup_menu.position = Vector2i(get_global_mouse_position())
	popup_menu.popup()
