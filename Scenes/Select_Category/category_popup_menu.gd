# res://Scenes/Select_Category/category_popup_menu.gd
extends PopupMenu


func _on_id_pressed(id: int) -> void:
	print("Select_Category -> category_popup_menu.gd -> _on_id_pressed(id: int)")
		
	match id:
		0: 
			print(" 0 Category Stilllife")
			Globals.category = "stilllife"
			print("Category: ",Globals.category)
			
		1: 
			print(" 1 Category Cars")
			Globals.category ="cars"
			print("Category: ",Globals.category)
						
		2:
			print(" 2 Category Mountains")
			Globals.category ="mountains"
			print("Category: ",Globals.category)
			
			
		3: 
			print(" 3 Category Architecture")
			Globals.category ="architecture"
			print("Category: ",Globals.category)
			
			
		4:
			print(" 4 Category Art")
			Globals.category ="art"
			print("Category: ",Globals.category)
			
			
		5:
			print(" 5 Category Flowers")
			Globals.category ="flowers"
			print("Category: ",Globals.category)
			
			
		6:
			print(" 6 Category Birds")
			Globals.category ="birds"
			print("Category: ",Globals.category)
			
			
		7:
			print(" 7 Category Cats")
			Globals.category ="cats"
			print("Category: ",Globals.category)
			
			
		8:
			print(" 8 Category Dog")
			Globals.category ="dogs"
			print("Category: ",Globals.category)
			
			
		9:
			print(" 9 Category africa")
			Globals.category ="africa"
			print("Category: ",Globals.category)
			
			
		10:
			print(" 10 Category alaska")
			Globals.category ="alaska"
			print("Category: ",Globals.category)
			
		
		11:
			print(" 11 Category australia")
			Globals.category ="australia"
			print("Category: ",Globals.category)
			
			
		12:
			print("12 Category russia")
			Globals.category ="russia"
			print("Category: ",Globals.category)
			
			
		13:
			print(" 13 Category southamerica")
			Globals.category ="southamerica"
			print("Category: ",Globals.category)
			
			
		14:
			print("14 Category unitedstates")
			Globals.category ="unitedstates"
			print("Category: ",Globals.category)
			
			
		
		
