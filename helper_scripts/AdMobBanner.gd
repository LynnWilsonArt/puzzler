extends Node2D

var _ad_view : AdView
var unit_id : String

func _ready():
	#The initializate needs to be done only once, ideally at app launch.
	MobileAds.initialize()
	

func _create_ad_view() -> void:
	#free memory
	if _ad_view:
		_destroy_banner_view()
	
	if OS.get_name() == "Android":
		unit_id = "ca-app-pub-3940256099942544/6300978111"
	elif OS.get_name() == "iOS":
		unit_id = "ca-app-pub-3940256099942544/2934735716"

	_ad_view = AdView.new(unit_id, AdSize.FULL_BANNER, AdPosition.BOTTOM)
	# Create a banner at coordinate (x, y) on screen.
	#var custom_position := AdPosition.custom(x, y)
	#_ad_view = AdView.new(unit_id, size, custom_position)
#--------------------------------------------------------------
func _on_show_banner():
	if _ad_view == null:
		_create_ad_view()
		var ad_request := AdRequest.new()
		_ad_view.load_ad(ad_request)
	
#---------------------------------------------------------------
func _register_ad_listener() -> void:
	if _ad_view != null:
		var ad_listener := AdListener.new()

		ad_listener.on_ad_failed_to_load = func(load_ad_error : LoadAdError) -> void:
			print("_on_ad_failed_to_load: " + load_ad_error.message)
		ad_listener.on_ad_clicked = func() -> void:
			print("_on_ad_clicked")
		ad_listener.on_ad_closed = func() -> void:
			print("_on_ad_closed")
		ad_listener.on_ad_impression = func() -> void:
			print("_on_ad_impression")
		ad_listener.on_ad_loaded = func() -> void:
			print("_on_ad_loaded")
		ad_listener.on_ad_opened = func() -> void:
			print("_on_ad_opened")

		_ad_view.ad_listener = ad_listener
		
#--------------------------------------------------------------------
func _destroy_banner_view() -> void:
	if _ad_view:
		#always call this method on all AdFormats to free memory on Android/iOS
		_ad_view.destroy()
		_ad_view = null
		
#-------------------------------------------------------------------------
func _create_banner_at(size: AdSize, x, y) -> void:
	# Create a banner at coordinate (x, y) on screen.
	var custom_position := AdPosition.custom(x, y)
	_ad_view = AdView.new(unit_id, size, custom_position)
	
