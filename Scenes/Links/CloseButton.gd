extends Button
# res://Scenes/Links/CloseButton.gd

@onready var links: Control = $"../.."

func _ready() -> void:
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed() -> void:
	print("CloseButton Pressed.")
	hide()
