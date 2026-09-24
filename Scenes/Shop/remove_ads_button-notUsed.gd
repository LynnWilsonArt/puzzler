extends Node
# res://Scenes/Shop/remove_popup_ads.gd

var payment = null
const SKU_REMOVE_INTERSTITIALS = "remove_interstitials"

# Emitted when product details are fetched or when a purchase succeeds
signal item_purchased(sku_id)
signal price_loaded(sku_id, price_string)

func _ready() -> void:
	if Engine.has_singleton("GodotGooglePlayBilling"):
		payment = Engine.get_singleton("GodotGooglePlayBilling")
		
		# Connect signals from the plugin
		payment.connected.connect(_on_connected)
		payment.sku_details_query_completed.connect(_on_sku_details_completed)
		payment.purchases_updated.connect(_on_purchases_updated)
		payment.purchase_acknowledged.connect(_on_purchase_acknowledged)
		
		# Connect to Google Play
		payment.start_connection()
	else:
		print("[IAPManager] GodotGooglePlayBilling singleton not found.")

func _on_connected() -> void:
	print("[IAPManager] Connected to Google Play Billing.")
	# Query details (title, price, etc.) for your IAP product
	payment.querySkuDetails([SKU_REMOVE_INTERSTITIALS], "inapp")

func _on_sku_details_completed(products: Array) -> void:
	for product in products:
		if product.sku == SKU_REMOVE_INTERSTITIALS:
			print("[IAPManager] Price: ", product.price)
			price_loaded.emit(product.sku, product.price)

# Call this when the player presses your "Remove Ads" button in UI
func buy_remove_interstitials() -> void:
	if payment:
		var response = payment.purchase(SKU_REMOVE_INTERSTITIALS)
		if response.status != OK:
			print("[IAPManager] Purchase initialization failed.")
	else:
		print("[IAPManager] Payment singleton unavailable.")

func _on_purchases_updated(purchases: Array) -> void:
	for purchase in purchases:
		# purchase_state == 1 means successful payment
		if purchase.purchase_state == 1:
			_process_purchase(purchase)

func _process_purchase(purchase: Dictionary) -> void:
	var sku = purchase.skus[0]
	
	if sku == SKU_REMOVE_INTERSTITIALS:
		# Non-consumable products MUST be acknowledged so Google doesn't refund them
		if not purchase.is_acknowledged:
			payment.acknowledgePurchase(purchase.purchase_token)
		else:
			_grant_ad_removal()

func _on_purchase_acknowledged(purchase_token: String) -> void:
	print("[IAPManager] Purchase acknowledged: ", purchase_token)
	_grant_ad_removal()

func _grant_ad_removal() -> void:
	# 1. Disable interstitial ads permanently via your AdManager
	if AdManager:
		AdManager.unlock_remove_interstitials()
	
	item_purchased.emit(SKU_REMOVE_INTERSTITIALS)
