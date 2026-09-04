# res://Scenes/Select_Category/category_popup_menu.gd
extends PopupMenu


func _on_id_pressed(id: int) -> void:
	print("Select_Category -> category_popup_menu.gd -> _on_id_pressed(id: int)")
		
	match id:
		0: 
			print(" 0 Category Stilllife")
			Globals.category = "stilllife"
			
		1: 
			print(" 1 Category Cars")
			Globals.category ="cars"
						
		2:
			print(" 2 Category Mountains")
			Globals.category ="mountains"
			
			
		3: 
			print(" 3 Category Architecture")
			Globals.category ="architecture"
			
			
		4:
			print(" 4 Category Art")
			Globals.category ="art"
			
			
		5:
			print(" 5 Category Flowers")
			Globals.category ="flowers"
			
			
		6:
			print(" 6 Category Birds")
			Globals.category ="birds"
			
			
		7:
			print(" 7 Category Cats")
			Globals.category ="cats"
			
			
		8:
			print(" 8 Category Dog")
			Globals.category ="dog"
			
			
		9:
			print(" 9 Category africa")
			Globals.category ="africa"
			
			
		10:
			print(" 10 Category alaska")
			Globals.category ="alaska"
			
		
		11:
			print(" 11 Category australia")
			Globals.category ="australia"
			
			
		12:
			print("12 Category russia")
			Globals.category ="russia"
			
			
		13:
			print(" 13 Category southamerica")
			Globals.category ="southamerica"
			
			
		14:
			print("14 Category unitedstates")
			Globals.category ="unitedstates"
			
			
		
		
