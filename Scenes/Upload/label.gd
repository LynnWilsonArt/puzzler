extends Label


func show_message(title: String, message: String):
	# Example using a Label
	var label = Label.new()
	label.text = title + ": " + message
	label.rect_min_size = Vector2(300, 100)
	add_child(label)
	
	# Position the label (example: center of the scene)
	label.rect_position = (get_viewport_rect().size - label.rect_min_size) / 2
