# res://helper_scripts/update_checker.gd
extends Node # or whatever your update-check UI is attached to
@onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog
@onready var panel: Panel = $Panel
@onready var progress_bar: ProgressBar = $Panel/Label/ProgressBar
@onready var progress_label: Label = $Panel/Label
func _ready() -> void:
	print("main() _> Started update checking")
	Updater.update_available.connect(_on_update_available)
	Updater.update_progress.connect(_on_update_progress)
	Updater.update_ready_to_install.connect(_on_update_ready)
	Updater.update_failed.connect(_on_update_failed)
	Updater.no_update_available.connect(_all_up_to_date)
	Updater.check_failed.connect(func(reason): print("Check failed: ", reason))
	var dialog_label = $ConfirmationDialog.get_label()
	dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	
	Updater.check_for_update()
	# Done checking - Got to game from here
	

func _all_up_to_date() -> void:
	print("Already up to date.")
	
	
func _on_update_available(latest_version: String, changelog: String, force_update: bool) -> void:
	# Show the user a dialog with the version + changelog.
	# On confirm (or immediately, if force_update is true):
		
	# Show app update availible popup
	$ConfirmationDialog.popup()
	await $ConfirmationDialog.confirmed
	print(" New version Availiable")

	Updater.download_update()


func _on_update_progress(downloaded: int, total: int) -> void:
	print("_on_update_progress()")
	
	if total > 0:
		var percent := float(downloaded) / float(total) * 100.0
		
		# Show the panel if it isn't visible yet
		if not panel.visible:
			panel.visible = true
			
		# Update the UI elements
		progress_bar.value = percent
		progress_label.text = "Downloading update: %.1f%%" % percent
		
			
		# Hide the panel automatically when the download finishes
		if downloaded >= total:
			panel.visible = false

func _on_update_ready(file_path: String) -> void:
	# This triggers Android's package installer confirmation screen.
	Updater.install_update(file_path)


func _on_update_failed(reason: String) -> void:
	print("Update failed: ", reason)
	# Show an error dialog to the user


func _on_confirmation_dialog_canceled() -> void:
	if $ConfirmationDialog.canceled:
		print(" Update Canceled")
		return
