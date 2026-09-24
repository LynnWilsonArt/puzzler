extends Button


func _on_pressed() -> void:
	print("Calling -> IAPManager.restore_purchase()")
	IAPManager.restore_purchases()
