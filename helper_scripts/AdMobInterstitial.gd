extends Node2D

var _interstitial_ad : InterstitialAd


func _ready() -> void:
	#The initializate needs to be done only once, ideally at app launch.
	MobileAds.initialize()
	_on_create_interstitial()
	
#---------------------------------------------------------------------------
func _on_create_interstitial():
	#free memory
	if _interstitial_ad:
		#always call this method on all AdFormats to free memory on Android/iOS
		_interstitial_ad.destroy()
		_interstitial_ad = null

	var unit_id : String
	if OS.get_name() == "Android":
		unit_id = "ca-app-pub-3940256099942544/1033173712"
	elif OS.get_name() == "iOS":
		unit_id = "ca-app-pub-3940256099942544/4411468910"

	var interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
	interstitial_ad_load_callback.on_ad_failed_to_load = func(adError : LoadAdError) -> void:
		print(adError.message)

	interstitial_ad_load_callback.on_ad_loaded = func(interstitial_ad : InterstitialAd) -> void:
		print("interstitial ad loaded ID: " + str(interstitial_ad._uid))
		_interstitial_ad = interstitial_ad

	InterstitialAdLoader.new().load(unit_id, AdRequest.new(), interstitial_ad_load_callback)
	
	
#------------------------------------------------------------------
func _on_show_interstitial():
	if _interstitial_ad:
		_interstitial_ad.show()
		
#-------------------------------------------------------------------
func interstitial_ad_destroy():
	if _interstitial_ad:
		_interstitial_ad.destroy()
		_interstitial_ad = null
	
		
