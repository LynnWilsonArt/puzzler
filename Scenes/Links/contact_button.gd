extends Button

# res://Scenes/Links/contact_button.gd
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("pressed", Callable(self, "_on_pressed"))

func _on_pressed() -> void:
	print("ContactButton Pressed.")
	OS.shell_open("https://lynnwilsonart.com/contact/")
