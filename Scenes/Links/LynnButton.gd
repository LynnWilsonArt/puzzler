extends Button
# res://Scenes/Links/LynnButton.gd
func _ready() -> void:
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed() -> void:
	print("LynnButton Pressed.")
	OS.shell_open("https://lynnwilsonart.com")
