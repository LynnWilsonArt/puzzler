extends Node

# -------------------------------------------------------------------
# AD UNIT CONFIGURATION
# -------------------------------------------------------------------
# Official Google Test Ad Unit IDs (Android)
const BANNER_ID: String = "ca-app-pub-3940256099942544/6300978111"
const INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"
const REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"

var ad_view: AdView
var interstitial_ad: InterstitialAd
var rewarded_ad: RewardedAd
var is_sdk_initialized: bool = false

func _ready() -> void:
	# Execute only on Android/iOS devices
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
		
		# Preload ads after SDK completes initialization
		load_interstitial()
		load_rewarded()

	MobileAds.initialize(init_listener)

# -------------------------------------------------------------------
# 1. BANNER AD (AdView + AdListener)
# -------------------------------------------------------------------
func load_banner() -> void:
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
	#if ad_view != null:
	#	ad_view.show()
	load_banner() # Creates and shows the banner

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
	if not is_sdk_initialized:
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

func show_interstitial() -> void:
	if interstitial_ad != null:
		print("[AdManager] Displaying Interstitial...")
		interstitial_ad.show()
		interstitial_ad = null
		load_interstitial() # Automatically preload next ad
	else:
		print("[AdManager] Interstitial not ready yet.")

# -------------------------------------------------------------------
# 3. REWARDED AD
# -------------------------------------------------------------------
func load_rewarded() -> void:
	if not is_sdk_initialized:
		return

	print("[AdManager] Loading Rewarded Ad...")
	var ad_request := AdRequest.new()
	var load_callback := RewardedAdLoadCallback.new()

	load_callback.on_ad_loaded = func(ad: RewardedAd):
		rewarded_ad = ad
		print("[AdManager] Rewarded ad loaded successfully.")

	load_callback.on_ad_failed_to_load = func(error: LoadAdError):
		rewarded_ad = null
		print("[AdManager] Rewarded ad failed to load. Message: ", error.get_message())

	RewardedAdLoader.new().load(REWARDED_ID, ad_request, load_callback)

func show_rewarded() -> void:
	if rewarded_ad != null:
		print("[AdManager] Displaying Rewarded Ad...")
		var reward_listener := OnUserEarnedRewardListener.new()
		
		reward_listener.on_user_earned_reward = func(reward):
			# Extract reward values dynamically to avoid type-naming mismatches
			var amount = reward.get_amount() if reward.has_method("get_amount") else reward.amount
			var type = reward.get_type() if reward.has_method("get_type") else reward.type
			print("[AdManager] User earned reward: ", amount, " ", type)
			# TODO: Grant coins / items to the player here

		rewarded_ad.show(reward_listener)
		rewarded_ad = null
		load_rewarded() # Automatically preload next ad
	else:
		print("[AdManager] Rewarded ad not ready yet.")
		
