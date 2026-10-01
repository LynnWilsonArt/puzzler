extends Button
# res://Scenes/Links/PuzzlerButton.gd
func _ready() -> void:
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed() -> void:
	print("PuzzlerButton Pressed.")
	OS.shell_open("https://puzzler.lynnwilsonart.com")
