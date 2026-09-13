# res://Scenes/CustomRadioUrl/custom_radio_url_submit_button.gd
extends Button


@onready var url: LineEdit = $"../Url"
@onready var custom_radio_url: Control = $"../../.."


func _on_pressed() -> void:
	var station_url: String = url.text
	print("Custom url: ", station_url)
	# Change station and save
	Radio.change_station(station_url)	
	custom_radio_url.hide()
	
