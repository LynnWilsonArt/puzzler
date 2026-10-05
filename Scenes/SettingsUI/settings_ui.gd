# res://Scenes/SettingsUI/settings_ui.gd
extends Control

@onready var music_volume_slider: HSlider = %MusicSlider
@onready var close_button: Button = %CloseButton
@onready var effects_volume_slider: HSlider = %EffectsSlider
@onready var radio_on_button: Button = %RadioOnButton
@onready var radio_off_button: Button = %RadioOffButton
@onready var effects_on_button: Button = %EffectsOnButton
@onready var effects_off_button: Button = %EffectsOffButton



func _ready() -> void:
	print("[SettingsUI.gd] ->  ready()")
	_update_ui_state()
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	effects_volume_slider.value_changed.connect(_on_effects_volume_changed)
	Settings.settings_changed.connect(_on_settings_changed)
	print("[SettingsUI.gd] -> ready() -> radio_mode: ",Settings.radio_mode)
	
func _on_music_volume_changed(music_val: float) -> void:
	print("[SettingsUI.gd] ->    _on_music_volume_changer()")
	Settings.music_volume = music_val / 100.0
	Settings._apply_settings()
	
func _on_effects_volume_changed(effects_val: float) -> void:
	print("[SettingsUI.gd] ->  _on_effects_volume_changes()")
	Settings.effects_volume = effects_val / 100.0
	Settings._apply_settings()
	
	
func _on_close_button_pressed() -> void:
	print("[SettingsUI.gd] ->  _on_close_presses()")
	Settings._save_settings()
	hide()

func _on_settings_changed() -> void:
	print("[SettingsUI.gd] ->  _on_settings_changed()")
	_update_ui_state()
func _update_ui_state() -> void:
	print("[SettingsUI.gd] ->  _update_ui_state()")
	music_volume_slider.set_block_signals(true)
	music_volume_slider.value = Settings.music_volume * 100.0
	music_volume_slider.set_block_signals(false)
	
	effects_volume_slider.set_block_signals(true)
	effects_volume_slider.value = Settings.effects_volume * 100.0
	effects_volume_slider.set_block_signals(false)
	
	_update_button_visuals(Settings.radio_mode)
	_update_effects_button_visuals(Settings.sound_effects_mode)

		
# Radio Control Buttons
func _on_music_on_pressed() -> void:
	print("[SettingsUI.gd]  -> MusicOnButton pressed")
	Settings._set_bg_music_mode(true)
	_update_button_visuals(true)

func _on_music_off_pressed() -> void:
	print("[SettingsUI.gd]  -> MusicOffButton pressed")
	Settings._set_bg_music_mode(false)
	_update_button_visuals(false)

func _update_button_visuals(is_on: bool) -> void:
	radio_on_button.disabled = is_on   # or swap textures/highlight the active one
	radio_off_button.disabled = not is_on
	
# Effects Control Buttons
func _on_effects_on_button_pressed() -> void:
	print("[SettingsUI.gd]  -> MusicOnButton pressed")
	Settings._set_effects_audio_mode(true)
	_update_button_visuals(true)

func _on_effects_off_button_pressed() -> void:
	print("[SettingsUI.gd]  -> MusicOffButton pressed")
	Settings._set_effects_audio_mode(false)
	_update_effects_button_visuals(false)

func _update_effects_button_visuals(is_on: bool) -> void:
	print("[SettingsUI.gd] -> Effects mode: ",is_on)
	effects_on_button.disabled = is_on   # or swap textures/highlight the active one
	effects_off_button.disabled = not is_on
