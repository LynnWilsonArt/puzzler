# res://Scenes/Select_Category/category_menu_button.gd
extends Button

# The PopupMenu is a sibling of this Button:
@onready var popup_menu : PopupMenu = $"../CategoryPopupMenu"

func _ready() -> void:
	print("[Select_Category] -> category_menu_button.gd-> _ready()")
	
		
	# Hide on startup
	popup_menu.hide()


func _on_pressed() -> void:
	print("[Select_Category] -> category_menu_button.gd-> _on_pressed()")
	
	# Display the popup menu
	print("[Select_Category] -> category_menu_button.gd-> Open Menu Button Clicked")
	popup_menu.position = Vector2i(50,150)
	popup_menu.popup()
