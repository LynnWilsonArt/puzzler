extends Button

signal toggle_hud_display(state: bool)

# Tracks the state locally on the button
@export var toggle_hud: bool = false

func _ready() -> void:
	# Connect the button's built-in pressed signal to our custom function below
	pressed.connect(_on_button_pressed)
	
	# Fixed path: Looks up one level to game_scene, then down to HUD
	var hud_node = get_node_or_null("../../../../HUD")
	# connect to HUD function
	if hud_node:
		toggle_hud_display.connect(hud_node._on_hud_toggle_requested)
	else:
		print("Warning: Button could not find the HUD node sibling!")

func _on_button_pressed() -> void:
	# Flip the local tracking boolean
	toggle_hud = !toggle_hud
	
	# Emit the newly flipped state (true or false) to the HUD
	toggle_hud_display.emit(toggle_hud)
