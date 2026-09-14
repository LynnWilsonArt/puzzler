# res://Scenes/Select_Category/category_popup_menu.gd
extends PopupMenu


func _on_id_pressed(id: int) -> void:
	print("Select_Category -> category_popup_menu.gd -> _on_id_pressed(id: int)")
		
	match id:
		0: 
			print(" 0 Category Animals")
			Globals.category = "animals"
			print("Globals.category = ",Globals.category)
			
		1: 
			print(" 1 Category Art")
			Globals.category ="art"
			print("Globals.category = ",Globals.category)
						
		2:
			print(" 2 Category Automobile")
			Globals.category ="automobile"
			print("Globals.category = ",Globals.category)
			
		3: 
			print(" 3 Category Aircraft")
			Globals.category ="aircraft"
			print("Globals.category = ",Globals.category)
		
		4:
			print(" 4 Category City Scapes")
			Globals.category ="city"
			print("Globals.category = ",Globals.category)
			
		5:
			print(" 4 Category Flowers")
			Globals.category ="flowers"
			print("Globals.category = ",Globals.category)
			
		6:
			print(" 5 Category Landscapes")
			Globals.category ="landscapes"
			print("Globals.category = ",Globals.category)
			
		7:
			print(" 6 Category Nature")
			Globals.category ="nature"
			print("Globals.category = ",Globals.category)
