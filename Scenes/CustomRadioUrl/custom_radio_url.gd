# res://Scenes/CustomRadioUrl/custom_radio_url.gd
extends Control
@onready var url: LineEdit = $CustomUrlContainer/ColorRect/Url

func _on_submit_button_pressed() -> void:
	print("CustomRadioUrl -> custom_radio_url.gd -> _on_submit_button_pressed()")
	print("CustomRadioUrl -> Custom Url: ",url.text)
	print("CustomRadioUrl -> To-Do")
