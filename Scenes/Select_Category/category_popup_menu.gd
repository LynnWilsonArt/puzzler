# res://Scenes/Select_Category/category_popup_menu.gd
extends PopupMenu


func _on_id_pressed(id: int) -> void:
	print("Select_Category -> category_popup_menu.gd -> _on_id_pressed(id: int)")
	
	# Reset for category selection
	Globals.image_url = Globals.PUZZLER_BASE_URL
	
	match id:
		0: 
			
			Globals.image_url +="stilllife"
			print(" 1 Category Stilllife",Globals.image_url)
		1: 
			print(" 2 Category Cars")
			Globals.image_url +="cars"
			print(" 1 Category Cars",Globals.image_url)
			
		2:
			print(" 3 Category Mountains")
			Globals.image_url +="mountains"
			print(" 1 Category mountains",Globals.image_url)
			
		3: 
			print(" 4 Category Architecture")
			Globals.image_url +="architecture"
			print(" 1 Category architecture",Globals.image_url)
			
		4:
			print(" 5 Category Art")
			Globals.image_url +="art"
			print(" 1 Category Art",Globals.image_url)
			
		5:
			print(" 6 Category Flowers")
			Globals.image_url +="flowers"
			print(" 1 Category flowers",Globals.image_url)
			
		6:
			print(" 7 Category Birds")
			Globals.image_url +="birds"
			print(" 1 Category birds",Globals.image_url)
			
		7:
			print(" 8 Category Cats")
			Globals.image_url +="cats"
			print(" 1 Category cats",Globals.image_url)
			
		8:
			print(" 9 Category Dog")
			Globals.image_url +="dog"
			print(" 1 Category dog",Globals.image_url)
			
		9:
			print(" 10 Category africa")
			Globals.image_url +="africa"
			print(" 1 Category africa",Globals.image_url)
			
		10:
			print(" 11 Category alaska")
			Globals.image_url +="alaska"
			print(" 1 Category alaska",Globals.REMOTE_IMAGE_PATH)
		
		11:
			print(" 12 Category australia")
			Globals.image_url +="australia"
			print(" 1 Category australia",Globals.image_url)
			
		12:
			print("Category russia")
			Globals.image_url +="russia"
			print(" 1 Category russia",Globals.image_url)
			
		13:
			print("Category southamerica")
			Globals.image_url +="southamerica"
			print(" 1 Category southamerica",Globals.image_url)
			
		14:
			print("Category unitedstates")
			Globals.image_url +="unitedstates"
			print(" 1 Category unitedstates",Globals.image_url)
			
		
		
