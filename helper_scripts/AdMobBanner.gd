extends Node2D

var _ad_view: AdView
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
		
	_ad_view = AdView.new(unit_id, AdSize.BANNER, AdPosition.TOP)
	

func _on_show_banner() -> void:
	if _ad_view == null:
		_create_ad_view()
		_register_ad_listeners()
		
		var ad_request := AdRequest.new()
		# Load ads for BOTH views
		_ad_view.load_ad(ad_request)
	

func _register_ad_listeners() -> void:
	var ad_listener := AdListener.new()
	ad_listener.on_ad_failed_to_load = func(load_ad_error: LoadAdError) -> void:
		print("Ad failed to load: ", load_ad_error.message)
	ad_listener.on_ad_loaded = func() -> void:
		print("Ad loaded successfully")

	# Attach listener to both banner instances
	if _ad_view != null:
		_ad_view.ad_listener = ad_listener
	
func _destroy_banner_view() -> void:
	if _ad_view:
		_ad_view.destroy()
		_ad_view = null
	
func _on_pause_banner() -> void:
	_ad_view.hide()
	
func _on_resume_banner() -> void:
	_ad_view.show()
