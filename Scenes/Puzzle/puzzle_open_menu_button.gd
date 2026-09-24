# res://Scenes/Puzzle/puzzle_open_menu_button.gd
extends Button

@onready var puzzle_popup_menu: PopupMenu = $PuzzlePopupMenu
@onready var stations_popup_menu: PopupMenu = $PuzzlePopupMenu/StationsPopupMenu
@onready var settings_ui: Control = $"../../SettingsUI"
@onready var station_update_panel: PanelContainer = $"../../StationUpdatePanel"



func _ready() -> void:
	print("[Puzzle]-> open_menu_button.gd -> _ready()")
	# Hide on startup
	puzzle_popup_menu.hide()


func _on_pressed() -> void:
	print("[Puzzle]-> open_menu_button.gd -> _on_pressed()")
	
	puzzle_popup_menu.position = Vector2i(50,95)
	puzzle_popup_menu.popup()
	
	# Hide any other menus that are open
	settings_ui.hide()
	stations_popup_menu.hide()
	station_update_panel.hide()
	
