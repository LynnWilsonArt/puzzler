# res://Scenes/Puzzle/puzzle_open_menu_button.gd
extends Button

@onready var puzzle_popup_menu: PopupMenu = $PuzzlePopupMenu


func _ready() -> void:
	print(" Puzzle -> SelectLevelMenuButton -> _ready()")
	# Hide on startup
	puzzle_popup_menu.hide()


func _on_pressed() -> void:
	print(" Puzzle -> open_menu_button.gd -> _on_pressed()")
	puzzle_popup_menu.position = Vector2i(get_global_mouse_position())
	puzzle_popup_menu.popup()
