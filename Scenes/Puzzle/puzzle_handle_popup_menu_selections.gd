# res://Scenes/Puzzle/puzzle_handle_popup_menu_selections.gd
extends PopupMenu

@onready var game_scene: Node = $"../../../.."
@onready var puzzle_node: Control = $"../../.."
@onready var puzzle_popup_menu: PopupMenu = $"."
@onready var stations_popup_menu: PopupMenu = $StationsPopupMenu
@onready var station_update_panel: PanelContainer = $"../../../StationUpdatePanel"
@onready var settings_ui: Control = $"../../../SettingsUI"
@onready var links: Control = $"../../../Links"



func _ready() -> void:
	print("[Puzzle]-> handle_popup_menu_selections.gd -> ready()")
	
func _on_id_pressed(id: int) -> void:
	print("[Puzzle]-> handle_popup_menu_selections.gd -> _on_id_pressed()")
	
	match id:
		0: # Toggle the original image for reference
			print("[Puzzle]-> handle_popup_menu_selections.gd -> Toggle Original Selected: ", id)
			if puzzle_node and puzzle_node.has_method("_on_show_original_image_pressed"):
				puzzle_node.toggle_puzzle = !puzzle_node.toggle_puzzle  # comes in false 
				puzzle_node._on_show_original_image_pressed()
			else:
				print("[Puzzle]-> handle_popup_menu_selections.gd -> Warning: Puzzle node or _on_show_original_image_pressed function not found!")
		
		1: # Load puzzle
			print("[Puzzle]-> handle_popup_menu_selections.gd -> Load Puzzle Selected: ", id)
			if puzzle_node and puzzle_node.has_method("_load_puzzle"):
				puzzle_node._load_puzzle()
			else:
				print("[Puzzle]-> handle_popup_menu_selections.gd -> ERROR! -> Puzzle node or load_puzzle() not found!")
				
		2: # Save puzzle
			print("[Puzzle]-> handle_popup_menu_selections.gd ->  -> Saving puzzle from Puzzle -> PopupMenu -> Save button")
			if puzzle_node and puzzle_node.has_method("_save_puzzle"):
				puzzle_node._save_puzzle()
			else:
				print("[Puzzle]-> handle_popup_menu_selections.gd -> ERROR! -> Puzzle node or load_puzzle() not found!")
				
		3: # New Puzzle Goto Main scene
			
			print("[Puzzle]-> handle_popup_menu_selections.gd -> Home Selected: ", id)
			Globals._stop_autosave_timer()
			Globals._g_delete_puzzle()
			Globals._switch_scene("res://Scenes/Main/main.tscn")
					
		4: # Skip to next image
			print("[Puzzle]-> handle_popup_menu_selections.gd -> Skip Selected: ", id)
			if game_scene and game_scene.has_method("_on_get_puzzle"):
				print("[Puzzle]-> handle_popup_menu_selections.gd -> Getting new image")
				print("[Puzzle]-> handle_popup_menu_selections.gd -> Level: ", Globals.columns, " , ", Globals.rows)
				game_scene.num_columns = Globals.columns
				game_scene.num_rows = Globals.rows
				game_scene._on_get_puzzle()
				if puzzle_node and puzzle_node.has_method("_start_puzzle_timer"):
					puzzle_node._start_puzzle_timer()
				print("[Puzzle]-> handle_popup_menu_selections.gd -> Finished skip")
			else:
				print("[Puzzle]-> handle_popup_menu_selections.gd -> Warning: game_scene node or _on_get_puzzle() function not found!")
				
			
		5: # Show settings panel Panel
			print("[Puzzle]-> puzzle_handle_popup_menu_selections.gd -> show settings panel: ", id)
			settings_ui.show()
			
			
		6: #Show Station Selection Panel
			print("[Puzzle]-> puzzle_handle_popup_menu_selections.gd -> show stations popup menu: ", id)
			stations_popup_menu.show()
			
		7: # Show Station Update Panel
			print("[Puzzle]-> puzzle_handle_popup_menu_selections.gd -> station update panel: ", id)
			station_update_panel.show()
		8: # Load links scene
			links.show()
			
			
		9: # Quit Game
			print("[Puzzle]-> Quit -> Destroyed Banners!")
			if OS.has_feature("web"):  
				print("[Puzzle]-> handle_popup_menu_selections.gd -> Quit - web!")
				Globals._stop_autosave_timer()
				Globals._g_save_puzzle()
				
				var win = JavaScriptBridge.get_interface("window")
				if win:
					win.location.href = Globals.web_home_page
			else:  
				print("[Puzzle]-> handle_popup_menu_selections.gd -> Quit - android!")
				if OS.has_feature("android"):
					Globals._stop_autosave_timer()
					Globals._g_save_puzzle()					
					BackButtonHandler._move_app_to_background()
				else:
					# Standard behavior for Android, Windows, macOS, etc.
					print("[Puzzle]-> handle_popup_menu_selections.gd -> Quit - Desktop")
					Globals._stop_autosave_timer()
					Globals._g_save_puzzle()
					get_tree().quit()
			
