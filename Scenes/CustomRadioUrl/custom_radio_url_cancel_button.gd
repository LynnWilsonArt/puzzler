# res://Scenes/CustomRadioUrl/custom_radio_url_cancel_button.gd
extends Button

@onready var color_rect: ColorRect = $"../.."

func _on_pressed() -> void:
	print("CustomRadioUrl -> custom_radio_url_cancel_button.gd -> Hide popup")
	color_rect.hide()
