# res://Scenes/Select_Category/category_popup_menu.gd
extends PopupMenu


func _on_id_pressed(id: int) -> void:
	print("[Select_Category] -> category_popup_menu.gd -> _on_id_pressed(id: int)")
		
	match id:
		0: 
			print("Selection: 0 Category Aircraft")
			Globals.category = "aircraft"
			print("Globals.category = ",Globals.category)
			
		1: 
			print("Selection: 1 Category Animals")
			Globals.category ="animals"
			print("Globals.category = ",Globals.category)
						
		2:
			print("Selection: 2 Category Art")
			Globals.category ="art"
			print("Globals.category = ",Globals.category)
		
		3:
			print("Selection: 3 Category Cars")
			Globals.category ="cars"
			print("Globals.category = ",Globals.category)
			
		4: 
			print("Selection: 4 Category City Scapes")
			Globals.category ="city"
			print("Globals.category = ",Globals.category)
		
		5:
			print("Selection: 5 Category Flowers")
			Globals.category ="flowers"
			print("Globals.category = ",Globals.category)
			
		6:
			print("Selection: 6 Category Insects")
			Globals.category ="insects"
			print("Globals.category = ",Globals.category)
			
		7:
			print("Selection: 7 Category Landscapes")
			Globals.category ="landscapes"
			print("Globals.category = ",Globals.category)
			
		
