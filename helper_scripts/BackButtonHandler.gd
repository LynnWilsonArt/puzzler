extends Node

func _ready() -> void:
	# Turn off Godot's default "back = quit" behavior
	get_tree().set_quit_on_go_back(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_pressed()

func _on_back_pressed() -> void:
	if is_on_main_menu():
		_move_app_to_background()
	else:
		_go_back_one_screen()

func _move_app_to_background() -> void:
	if OS.get_name() != "Android":
		return # no-op on desktop/editor

	var android_runtime = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		push_warning("AndroidRuntime singleton not available")
		return

	var activity = android_runtime.getActivity()
	activity.moveTaskToBack(true)

func _go_back_one_screen() -> void:
	# your existing menu/scene navigation logic
	pass

func is_on_main_menu() -> bool:
	# your existing check, e.g. get_tree().current_scene.name == "MainMenu"
	return true
	
func background_app() -> void:
	if OS.get_name() != "Android":
		get_tree().quit()   # Not Android just quit 
		#return # only applies on Android

	var android_runtime = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		push_warning("AndroidRuntime singleton not available")
		return

	var activity = android_runtime.getActivity()
	activity.moveTaskToBack(true)
	BackButtonHandler.background_app()
