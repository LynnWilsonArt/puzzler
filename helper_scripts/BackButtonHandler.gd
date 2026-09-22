#res://helper_scripts/BackButtonHandler.gd
extends Node

func _ready() -> void:
	# Turn off Godot's default "back = quit" behavior
	get_tree().set_quit_on_go_back(false)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_on_back_pressed()
		NOTIFICATION_APPLICATION_PAUSED:
			_on_app_backgrounded()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_app_returned_from_background()

func _on_back_pressed() -> void:
	print("[BackButtonHandler.gd] -> Back button pressed")

	if is_on_main_menu():
		_move_app_to_background()
	else:
		_go_back_one_screen()

func _move_app_to_background() -> void:
	print("[BackButtonHandler.gd] -> Move App to background")
	if OS.get_name() != "Android":
		return # no-op on desktop/editor
	var android_runtime = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		push_warning("[BackButtonHandler.gd] -> AndroidRuntime singleton not available")
		return
	var activity = android_runtime.getActivity()
	activity.moveTaskToBack(true)

func _go_back_one_screen() -> void:
	# your existing menu/scene navigation logic
	print("[BackButtonHandler.gd] -> Back up one scene")
	pass

func is_on_main_menu() -> bool:
	# your existing check, e.g. get_tree().current_scene.name == "MainMenu"
	print("[BackButtonHandler.gd] -> Is on Main scene")
	return true

func _on_app_backgrounded() -> void:
	# Called when app goes to background (Home, back-to-background, task switch, etc.)
	# e.g. pause game, save state, mute audio, pause timers
	print("[BackButtonHandler.gd] -> Sent to background!")
	
	
func _on_app_returned_from_background() -> void:
	# Called when app comes back to foreground
	# e.g. resume game, refresh data, unmute audio, resync timers
	print("[BackButtonHandler.gd] -> Returned to foreground!")

	
