# res://ui/Settings.gd
extends Control

@onready var music_volume_slider: HSlider = %MusicSlider
@onready var close_button: Button = %CloseButton
@onready var music_sound_checkBox: CheckBox = %MusicSoundMode
@onready var effects_sound_checkBox: CheckBox = %EffectsSoundMode
@onready var effects_volume_slider: HSlider = %EffectsSlider


func _ready() -> void:
	_update_ui_state()
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	effects_volume_slider.value_changed.connect(_on_effects_volume_changed)
	close_button.pressed.connect(_on_close_pressed)
	Settings.settings_changed.connect(_on_settings_changed)
	music_sound_checkBox.button_pressed = Settings.bg_audio_mode # Sets the checkbox 
		
	
func _on_music_volume_changed(music_val: float) -> void:
	Settings.audio_volume = music_val / 100.0
	#Settings.effects_volume = effects_val /100.0
	Settings._apply_settings()

func _on_effects_volume_changed(effects_val: float) -> void:
	Settings.effects_volume = effects_val / 100.0
	Settings._apply_settings()
	
	
func _on_close_pressed() -> void:
	#Settings.save_settings()
	Settings._save_settings()
	Settings._apply_settings()
	hide()

func _on_settings_changed() -> void:
	_update_ui_state()

func _update_ui_state() -> void:
	# Update music volume slider smoothly without firing unwanted signals
	music_volume_slider.set_block_signals(true)
	music_volume_slider.value = Settings.audio_volume * 100.0
	music_volume_slider.set_block_signals(false)
	
	# Update effects volume slider smoothly without firing unwanted signals
	effects_volume_slider.set_block_signals(true)
	effects_volume_slider.value = Settings.effects_volume * 100.0
	effects_volume_slider.set_block_signals(false)
	
	# Use button_pressed , and block signals
	music_sound_checkBox.set_block_signals(true)
	music_sound_checkBox.button_pressed = Settings.bg_audio_mode
	music_sound_checkBox.set_block_signals(false)
	
	# Use button_pressed , and block signals
	effects_sound_checkBox.set_block_signals(true)
	effects_sound_checkBox.button_pressed = Settings.sound_effects_mode
	effects_sound_checkBox.set_block_signals(false)
	
func _on_music_mode_toggled(toggled_on: bool) -> void:
	Settings._set_bg_music_mode(toggled_on)

func _on_effects_sound_mode_toggled(toggled_on: bool) -> void:
	print("Setting effects mode: ",toggled_on)
	Settings._set_effects_audio_mode(toggled_on)
