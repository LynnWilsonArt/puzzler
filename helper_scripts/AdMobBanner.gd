extends Node2D

var _ad_view0: AdView
var _ad_view1: AdView
var unit_id: String

func _ready() -> void:
	MobileAds.initialize()

func _create_ad_view() -> void:
	# Clean up existing instances before re-creating
	_destroy_banner_view()
	
	if OS.get_name() == "Android":
		unit_id = "ca-app-pub-3940256099942544/6300978111"
	elif OS.get_name() == "iOS":
		unit_id = "ca-app-pub-3940256099942544/2934735716"
		
	_ad_view0 = AdView.new(unit_id, AdSize.BANNER, AdPosition.BOTTOM_LEFT)
	_ad_view1 = AdView.new(unit_id, AdSize.BANNER, AdPosition.BOTTOM_RIGHT)

func _on_show_banner() -> void:
	if _ad_view0 == null or _ad_view1 == null:
		_create_ad_view()
		_register_ad_listeners()
		
		var ad_request := AdRequest.new()
		# Load ads for BOTH views
		_ad_view0.load_ad(ad_request)
		_ad_view1.load_ad(ad_request)

func _register_ad_listeners() -> void:
	var ad_listener := AdListener.new()
	ad_listener.on_ad_failed_to_load = func(load_ad_error: LoadAdError) -> void:
		print("Ad failed to load: ", load_ad_error.message)
	ad_listener.on_ad_loaded = func() -> void:
		print("Ad loaded successfully")

	# Attach listener to both banner instances
	if _ad_view0 != null:
		_ad_view0.ad_listener = ad_listener
	if _ad_view1 != null:
		_ad_view1.ad_listener = ad_listener

func _destroy_banner_view() -> void:
	if _ad_view0:
		_ad_view0.destroy()
		_ad_view0 = null
	if _ad_view1:
		_ad_view1.destroy()
		_ad_view1 = null
