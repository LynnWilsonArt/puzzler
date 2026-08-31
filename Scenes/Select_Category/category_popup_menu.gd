# res://Scenes/Select_Category/category_popup_menu.gd
extends PopupMenu


func _on_id_pressed(id: int) -> void:
	print("Select_Category -> category_popup_menu.gd -> _on_id_pressed(id: int)")
	# reset the url back to base url
	Globals.REMOTE_IMAGE_PATH = Globals.image_url
	match id:
		0: 
			
			Globals.REMOTE_IMAGE_PATH +="stilllife"
			print(" 1 Category Stilllife",Globals.REMOTE_IMAGE_PATH)
		1: 
			print(" 2 Category Cars")
			Globals.REMOTE_IMAGE_PATH +="cars"
			print(" 1 Category Cars",Globals.REMOTE_IMAGE_PATH)
			
		2:
			print(" 3 Category Mountains")
			Globals.REMOTE_IMAGE_PATH +="mountains"
			print(" 1 Category mountains",Globals.REMOTE_IMAGE_PATH)
			
		3: 
			print(" 4 Category Architecture")
			Globals.REMOTE_IMAGE_PATH +="architecture"
			print(" 1 Category architecture",Globals.REMOTE_IMAGE_PATH)
			
		4:
			print(" 5 Category Art")
			Globals.REMOTE_IMAGE_PATH +="art"
			print(" 1 Category Art",Globals.REMOTE_IMAGE_PATH)
			
		5:
			print(" 6 Category Flowers")
			Globals.REMOTE_IMAGE_PATH +="flowers"
			print(" 1 Category flowers",Globals.REMOTE_IMAGE_PATH)
			
		6:
			print(" 7 Category Birds")
			Globals.REMOTE_IMAGE_PATH +="birds"
			print(" 1 Category birds",Globals.REMOTE_IMAGE_PATH)
			
		7:
			print(" 8 Category Cats")
			Globals.REMOTE_IMAGE_PATH +="cats"
			print(" 1 Category cats",Globals.REMOTE_IMAGE_PATH)
			
		8:
			print(" 9 Category Dog")
			Globals.REMOTE_IMAGE_PATH +="dog"
			print(" 1 Category dog",Globals.REMOTE_IMAGE_PATH)
			
		9:
			print(" 10 Category africa")
			Globals.REMOTE_IMAGE_PATH +="africa"
			print(" 1 Category africa",Globals.REMOTE_IMAGE_PATH)
			
		10:
			print(" 11 Category alaska")
			Globals.REMOTE_IMAGE_PATH +="alaska"
			print(" 1 Category alaska",Globals.REMOTE_IMAGE_PATH)
		
		11:
			print(" 12 Category australia")
			Globals.REMOTE_IMAGE_PATH +="australia"
			print(" 1 Category australia",Globals.REMOTE_IMAGE_PATH)
			
		12:
			print("Category russia")
			Globals.REMOTE_IMAGE_PATH +="russia"
			print(" 1 Category russia",Globals.REMOTE_IMAGE_PATH)
			
		13:
			print("Category southamerica")
			Globals.REMOTE_IMAGE_PATH +="southamerica"
			print(" 1 Category southamerica",Globals.REMOTE_IMAGE_PATH)
			
		14:
			print("Category unitedstates")
			Globals.REMOTE_IMAGE_PATH +="unitedstates"
			print(" 1 Category unitedstates",Globals.REMOTE_IMAGE_PATH)
			
		
		
