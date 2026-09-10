# res://ui/Settings.gd
extends Control

@onready var volume_slider: HSlider = %VolumeSlider
@onready var close_button: Button = %CloseButton
@onready var sound_checkBox: CheckBox = %SoundMode




func _ready() -> void:
	_update_ui_state()
	volume_slider.value_changed.connect(_on_volume_changed)
	close_button.pressed.connect(_on_close_pressed)
	Settings.settings_changed.connect(_on_settings_changed)
	sound_checkBox.button_pressed = Settings.bg_audio_mode # Sets the checkbox 
		
	
func _on_volume_changed(val: float) -> void:
	Settings.audio_volume = val / 100.0
	Settings._apply_settings()
	
func _on_close_pressed() -> void:
	#Settings.save_settings()
	Settings._save_settings()
	Settings._apply_settings()
	hide()

func _on_settings_changed() -> void:
	_update_ui_state()

func _update_ui_state() -> void:
	# Update volume slider smoothly without firing unwanted signals
	volume_slider.set_block_signals(true)
	volume_slider.value = Settings.audio_volume * 100.0
	volume_slider.set_block_signals(false)
	
	# Fix: Use button_pressed instead of pressed, and block signals
	sound_checkBox.set_block_signals(true)
	sound_checkBox.button_pressed = Settings.bg_audio_mode
	sound_checkBox.set_block_signals(false)
	
func _on_sound_mode_toggled(toggled_on: bool) -> void:
	Settings.bg_audio_mode = toggled_on
	Settings._set_bg_music_mode()
