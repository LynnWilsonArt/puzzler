extends Button
# res://Scenes/Select_level/select_level_menu.gd

# The PopupMenu is a sibling of this Button:
@onready var popup_menu : PopupMenu = $"../MainScene/TextureRect/SelectLevelMenu"

func _ready() -> void:
	# DEBUG
	print("Select_level -> open_menu_button.gd -> _ready()")
		
	# Hide on startup
	popup_menu.hide()


func _on_pressed() -> void:
	# DEBUG
	print("Select_level -> open_menu_button.gd -> _on_pressed()")
	
	# Display the popup menu
	print("Select_level -> open_menu_button.gd -> Open Menu Button Clicked")
	popup_menu.position = Vector2i(get_global_mouse_position())
	popup_menu.popup()
