# res://IAPManager.gd
# Autoload name: IAPManager
# Built for GodotGooglePlayBilling 3.x (godot-sdk-integrations/godot-google-play-billing)
# which exposes a BillingClient class you instantiate with BillingClient.new() -
# NOT a raw Engine singleton, and NOT the old product_details_query_completed(Array)
# signal shape. Responses come back as Dictionaries via *_response signals.
extends Node

signal iap_ready
signal price_loaded(sku_id: String, price: String)
signal purchase_succeeded(sku_id: String)
signal purchase_failed(sku_id: String, message: String)
signal restore_completed(found_purchases: bool)
signal product_revoked(sku_id: String)

const SKU_REMOVE_INTERSTITIALS: String = "remove_interstitials"
const ALL_SKUS: Array[String] = [SKU_REMOVE_INTERSTITIALS]

var billing_client: BillingClient = null
var google_is_connected: bool = false
var cached_products: Dictionary = {}  # product_id -> product_details Dictionary
var owned_products: Dictionary = {}  # product_id -> true, for non-consumables already owned

func _ready() -> void:
	if not OS.has_feature("android"):
		print("[IAPManager] Not running on Android. Billing disabled.")
		return

	billing_client = BillingClient.new()

	billing_client.connected.connect(_on_connected)
	billing_client.disconnected.connect(_on_disconnected)
	billing_client.connect_error.connect(_on_connect_error)
	billing_client.query_product_details_response.connect(_on_query_product_details_response)
	billing_client.query_purchases_response.connect(_on_query_purchases_response)
	billing_client.on_purchase_updated.connect(_on_purchase_updated)
	billing_client.acknowledge_purchase_response.connect(_on_acknowledge_purchase_response)

	print("[IAPManager] Connecting to Google Play Billing service...")
	billing_client.start_connection()

# -------------------------------------------------------------------
# CONNECTION
# -------------------------------------------------------------------
func _on_connected() -> void:
	print("[IAPManager] Connected to Google Play Billing.")
	google_is_connected = true
	billing_client.query_product_details(ALL_SKUS, BillingClient.ProductType.INAPP)
	billing_client.query_purchases(BillingClient.ProductType.INAPP)

func _on_disconnected() -> void:
	print("[IAPManager] Disconnected from Google Play Billing.")
	google_is_connected = false

func _on_connect_error(response_code: int, debug_message: String) -> void:
	push_error("[IAPManager] Connect error (%d): %s" % [response_code, debug_message])
	google_is_connected = false

# -------------------------------------------------------------------
# PRODUCT QUERY
# -------------------------------------------------------------------
func _on_query_product_details_response(response: Dictionary) -> void:
	print("[IAPManager] query_product_details_response: ", response)

	if response.get("response_code", -1) != BillingClient.BillingResponseCode.OK:
		push_warning("[IAPManager] Product query failed: %s" % str(response))
		return

	var products: Array = response.get("product_details", [])
	cached_products.clear()

	for product in products:
		var product_id: String = product.get("product_id", "")
		if product_id.is_empty():
			continue
		cached_products[product_id] = product
		var price: String = _extract_formatted_price(product)
		print("[IAPManager] Loaded SKU: %s | Price: %s" % [product_id, price])
		price_loaded.emit(product_id, price)

	if products.is_empty():
		push_warning("[IAPManager] Query succeeded but returned zero products - check Play Console SKU status/activation.")

	iap_ready.emit()

# -------------------------------------------------------------------
# PURCHASING
# -------------------------------------------------------------------
func _extract_formatted_price(product: Dictionary) -> String:
	var offers: Array = product.get("one_time_purchase_offer_details_list", [])
	if not offers.is_empty():
		return offers[0].get("formatted_price", "N/A")
	return "N/A"

func buy_remove_interstitials() -> void:
	buy_product(SKU_REMOVE_INTERSTITIALS)

func buy_product(product_id: String) -> void:
	if not google_is_connected or billing_client == null:
		purchase_failed.emit(product_id, "Billing service not connected.")
		return

	if not cached_products.has(product_id):
		purchase_failed.emit(product_id, "Product details not loaded from Google Play yet. Please wait a moment.")
		return

	var product: Dictionary = cached_products[product_id]
	var offers: Array = product.get("one_time_purchase_offer_details_list", [])
	if offers.is_empty():
		purchase_failed.emit(product_id, "No purchase option available for this product.")
		return

	var offer: Dictionary = offers[0]
	var purchase_option_id: String = offer.get("purchase_option_id", "")
	var offer_id_value = offer.get("offer_id", null)
	var offer_id: String = offer_id_value if offer_id_value != null else ""

	print("[IAPManager] Launching purchase flow for: %s (purchase_option_id=%s)" % [product_id, purchase_option_id])

	var launch_result: Dictionary = billing_client.purchase(product_id, purchase_option_id, offer_id)
	var response_code: int = launch_result.get("response_code", BillingClient.BillingResponseCode.OK)
	if response_code != BillingClient.BillingResponseCode.OK:
		var debug_message: String = launch_result.get("debug_message", "Failed to launch billing flow.")
		purchase_failed.emit(product_id, debug_message)

func _on_purchase_updated(response: Dictionary) -> void:
	print("[IAPManager] on_purchase_updated: ", response)

	if response.get("response_code", -1) != BillingClient.BillingResponseCode.OK:
		var debug_message: String = response.get("debug_message", "Unknown error")
		purchase_failed.emit(SKU_REMOVE_INTERSTITIALS, debug_message)
		return

	var purchases: Array = response.get("purchases", [])
	for purchase in purchases:
		_process_purchase(purchase)

func _process_purchase(purchase: Dictionary) -> void:
	var products: Array = purchase.get("product_ids", [])
	if products.is_empty():
		return

	var product_id: String = products[0]
	var token: String = purchase.get("purchase_token", "")
	var is_acknowledged: bool = purchase.get("is_acknowledged", false)

	print("[IAPManager] Processing purchase: ", product_id)
	_grant_product_reward(product_id)
	owned_products[product_id] = true

	if not is_acknowledged and not token.is_empty():
		billing_client.acknowledge_purchase(token)
	else:
		purchase_succeeded.emit(product_id)

func _on_acknowledge_purchase_response(response: Dictionary) -> void:
	print("[IAPManager] acknowledge_purchase_response: ", response)
	if response.get("response_code", -1) == BillingClient.BillingResponseCode.OK:
		purchase_succeeded.emit(SKU_REMOVE_INTERSTITIALS)

func _grant_product_reward(product_id: String) -> void:
	if product_id == SKU_REMOVE_INTERSTITIALS:
		if has_node("/root/AdManager"):
			get_node("/root/AdManager").hides_interstitials = true
		print("[IAPManager] Reward applied: Interstitial ads disabled.")

func _revoke_product_reward(product_id: String) -> void:
	if product_id == SKU_REMOVE_INTERSTITIALS:
		if has_node("/root/AdManager"):
			get_node("/root/AdManager").hides_interstitials = false
		print("[IAPManager] Reward revoked: Interstitial ads re-enabled.")
	owned_products.erase(product_id)
	product_revoked.emit(product_id)

# -------------------------------------------------------------------
# RESTORE
# -------------------------------------------------------------------
func restore_purchases() -> void:
	if google_is_connected and billing_client != null:
		print("[IAPManager] Restoring purchases...")
		billing_client.query_purchases(BillingClient.ProductType.INAPP)

func _on_query_purchases_response(response: Dictionary) -> void:
	print("[IAPManager] query_purchases_response: ", response)
	if response.get("response_code", -1) != BillingClient.BillingResponseCode.OK:
		restore_completed.emit(false)
		return

	var purchases: Array = response.get("purchases", [])
	var still_owned: Dictionary = {}
	var found_active: bool = false

	for purchase in purchases:
		if not purchase.get("is_suspended", false):
			var product_ids: Array = purchase.get("product_ids", [])
			for pid in product_ids:
				still_owned[pid] = true
			_process_purchase(purchase)
			found_active = true

	# Anything we previously believed was owned, but this fresh query no
	# longer returned, has been revoked (e.g. refund + remove entitlement
	# issued from Play Console).
	for product_id in owned_products.keys().duplicate():
		if not still_owned.has(product_id):
			print("[IAPManager] Product no longer owned, revoking: ", product_id)
			_revoke_product_reward(product_id)

	restore_completed.emit(found_active)
