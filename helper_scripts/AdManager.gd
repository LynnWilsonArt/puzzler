extends Node

# -------------------------------------------------------------------
# AD UNIT CONFIGURATION
# -------------------------------------------------------------------
# Official Google Test Ad Unit IDs (Android)
const BANNER_ID: String = "ca-app-pub-3940256099942544/6300978111"
const INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"
const REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"

const SAVE_PATH: String = "user://ad_settings.cfg"

var ad_view: AdView
var interstitial_ad: InterstitialAd
var rewarded_ad: RewardedAd
var is_sdk_initialized: bool = false

# Flag updated after checking local config or IAP receipts
var hides_interstitials: bool = false


func _ready() -> void:
	# Check local purchase state first
	_check_purchase_status()
	
	# Initialize SDK on supported platforms
	if OS.get_name() in ["Android", "iOS"]:
		_initialize_admob()
	else:
		_initialize_admob()

# -------------------------------------------------------------------
# INITIALIZATION
# -------------------------------------------------------------------
func _initialize_admob() -> void:
	print("[AdManager] Initializing MobileAds SDK...")
	
	var init_listener := OnInitializationCompleteListener.new()
	init_listener.on_initialization_complete = func(_status: InitializationStatus):
		print("[AdManager] MobileAds SDK initialized successfully!")
		is_sdk_initialized = true
		
		# Preload banner ad
		load_banner()
		hide_banner()
		
		# Only preload interstitial ads if the user HAS NOT purchased ad removal
		if not hides_interstitials:
			load_interstitial()

	MobileAds.initialize(init_listener)

# -------------------------------------------------------------------
# IAP / AD REMOVAL SAVE LOGIC
# -------------------------------------------------------------------
func _check_purchase_status() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		hides_interstitials = config.get_value("purchases", "remove_interstitials", false)
	else:
		hides_interstitials = false
		
	print("[AdManager] Hides Interstitials status: ", hides_interstitials)

# Call this function when your Google/Apple IAP purchase completes successfully!
func unlock_remove_interstitials() -> void:
	hides_interstitials = true
	
	# If an interstitial ad was already loaded in memory, destroy it
	if interstitial_ad != null:
		interstitial_ad.destroy()
		interstitial_ad = null

	# Save purchase state locally
	var config := ConfigFile.new()
	config.load(SAVE_PATH) # Load existing settings if any
	config.set_value("purchases", "remove_interstitials", true)
	config.save(SAVE_PATH)
	
	print("[AdManager] Interstitial ads successfully disabled and saved!")

# -------------------------------------------------------------------
# 1. BANNER AD (AdView + AdListener)
# -------------------------------------------------------------------
func load_banner() -> void:
	print("[AdManager] Loading Banner Ad...")
	if not is_sdk_initialized:
		print("[AdManager] Cannot load banner: SDK not initialized.")
		return

	destroy_banner()

	# Create AdView instance
	ad_view = AdView.new(BANNER_ID, AdSize.BANNER, AdPosition.TOP)

	# Banners require an AdListener object to register event callbacks
	var ad_listener := AdListener.new()
	
	ad_listener.on_ad_loaded = func():
		print("[AdManager] Banner loaded successfully!")

	ad_listener.on_ad_failed_to_load = func(load_ad_error: LoadAdError):
		print("[AdManager] Banner failed to load. Message: ", load_ad_error.get_message())

	# Assign listener to ad_view before loading
	ad_view.ad_listener = ad_listener
	ad_view.load_ad(AdRequest.new())

func show_banner() -> void:
	print("[AdManager] Show/Resume Banner!")
	if ad_view != null:
		ad_view.show()

func hide_banner() -> void:
	print("[AdManager] Pause/Hide Banner!")
	if ad_view != null:
		ad_view.hide()

func destroy_banner() -> void:
	if ad_view != null:
		ad_view.destroy()
		ad_view = null

# -------------------------------------------------------------------
# 2. INTERSTITIAL AD
# -------------------------------------------------------------------
func load_interstitial() -> void:
	if not is_sdk_initialized or hides_interstitials:
		return

	print("[AdManager] Loading Interstitial Ad...")
	var ad_request := AdRequest.new()
	var load_callback := InterstitialAdLoadCallback.new()

	load_callback.on_ad_loaded = func(ad: InterstitialAd):
		interstitial_ad = ad
		print("[AdManager] Interstitial loaded successfully.")

	load_callback.on_ad_failed_to_load = func(error: LoadAdError):
		interstitial_ad = null
		print("[AdManager] Interstitial failed to load. Message: ", error.get_message())

	InterstitialAdLoader.new().load(INTERSTITIAL_ID, ad_request, load_callback)

func show_interstitil_ad(scene: String) -> void:
	print("[AdManager] Showing interstitial ad then loading next scene: ", scene)
	play_interstitial_and_continue(func():
		get_tree().change_scene_to_file(scene)
	)

# --- Call this from your Game Manager ---
func play_interstitial_and_continue(on_completed: Callable) -> void:
	# 0. Check if user purchased removing interstitials
	if hides_interstitials:
		print("[AdManager] Skipping interstitial ad (Purchased by user).")
		on_completed.call()
		return

	# 1. Fallback: If ad object is null (not loaded/failed/capped), skip immediately
	if interstitial_ad == null:
		print("[AdManager] Ad not loaded or capped. Proceeding with game.")
		on_completed.call()
		_preload_interstitial() # Try fetching for next time
		return

	# 2. Attach full-screen callbacks
	var callback := FullScreenContentCallback.new()

	# Triggers when user finishes or closes the ad
	callback.on_ad_dismissed_full_screen_content = func() -> void:
		_cleanup_and_continue(on_completed)

	# Triggers if frequency capping or runtime error prevents display at show-time
	callback.on_ad_failed_to_show_full_screen_content = func(ad_error: AdError) -> void:
		print("[AdManager] Ad failed to show: ", ad_error.get_message())
		_cleanup_and_continue(on_completed)

	interstitial_ad.full_screen_content_callback = callback
	
	# Show the ad
	interstitial_ad.show()

func _cleanup_and_continue(on_completed: Callable) -> void:
	if interstitial_ad:
		interstitial_ad.destroy()
		interstitial_ad = null # Reset to null so we know it's no longer ready
	
	on_completed.call()      # Resume game/change scene
	_preload_interstitial() # Preload for next cycle

func _preload_interstitial() -> void:
	# Don't preload if user purchased ad removal or if ad is already loaded
	if hides_interstitials or interstitial_ad != null or not is_sdk_initialized:
		return

	var load_callback := InterstitialAdLoadCallback.new()
	
	load_callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		interstitial_ad = ad
		
	load_callback.on_ad_failed_to_load = func(ad_error: LoadAdError) -> void:
		print("[AdManager] Ad load blocked/failed: ", ad_error.get_message())
		interstitial_ad = null

	InterstitialAdLoader.new().load(INTERSTITIAL_ID, AdRequest.new(), load_callback)
