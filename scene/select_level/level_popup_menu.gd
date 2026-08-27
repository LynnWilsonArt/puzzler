# res://scene/puzzle/handle_popup_menu_selections.gd
extends PopupMenu


func _on_id_pressed(id: int) -> void:
	print("DEBUG -> handle_popup_menu_selections.gd -> _on_id_pressed()")
	match id:
		0: 
			print(" 1 level selected")
			Globals.columns = 4
			Globals.rows = 4
		1: 
			print(" 2 level selected")
			Globals.columns = 6
			Globals.rows = 4
			
		2:
			print(" 3 level selected")
			Globals.columns = 8
			Globals.rows = 4
		3: 
			print(" 4 level selected")
			Globals.columns = 8
			Globals.rows = 8
		4:
			print(" 5 level selected")
			Globals.columns = 12
			Globals.rows = 8
		5:
			print(" 6 level selected")
			Globals.columns = 12
			Globals.rows = 12
		6:
			print(" 7 level selected")
			Globals.columns = 16
			Globals.rows = 12
		7:
			print(" 8 level selected")
			Globals.columns = 24
			Globals.rows = 24
		8:
			print(" 9 level selected")
			Globals.columns = 16
			Globals.rows = 16
		9:
			print(" 10 level selected")
			Globals.columns = 24
			Globals.rows = 12
		10:
			print(" 11 level selected")
			Globals.columns = 32
			Globals.rows = 18
		11:
			print(" 12 level selected")
			Globals.columns = 36
			Globals.rows = 24

		
		
