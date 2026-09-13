extends Button
# res://Scenes/Select_level/select_level_menu.gd

@onready var select_level_popup_menu: PopupMenu = $SelectLevelPopupMenu



func _ready() -> void:
	print("Select_level -> open_menu_button.gd -> _ready()")
		
	# Hide on startup
	select_level_popup_menu.hide()


func _on_pressed() -> void:
	print("Select_level -> open_menu_button.gd -> _on_pressed()")
	
	# Display the popup menu
	print("Select_level -> open_menu_button.gd -> Open Menu Button Clicked")
	select_level_popup_menu.position = Vector2i(get_global_mouse_position())
	select_level_popup_menu.popup()
