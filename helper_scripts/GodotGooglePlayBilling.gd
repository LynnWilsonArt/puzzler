# res://helper_scripts/GodotGooglePlayBilling.gd
extends Node

var payment = null

func _ready() -> void:
	if Engine.has_singleton("GodotGooglePlayBilling"):
		payment = Engine.get_singleton("GodotGooglePlayBilling")
		
		# Connect plugin signals
		payment.connected.connect(_on_connected)
		payment.disconnected.connect(_on_disconnected)
		payment.connect_error.connect(_on_connect_error)
		payment.sku_details_query_completed.connect(_on_sku_details_completed)
		payment.purchases_updated.connect(_on_purchases_updated)
		payment.purchase_acknowledged.connect(_on_purchase_acknowledged)
		payment.purchase_consumed.connect(_on_purchase_consumed)
		
		# Initialize connection to Google Play
		payment.start_connection()
	else:
		print("Google Play Billing singleton not found (running on desktop or missing plugin).")

func _on_connected() -> void:
	# Query SKUs from Play Console ("inapp" for items, "subs" for subscriptions)
	payment.querySkuDetails(["remove_interstitials", "gem_pack_100"], "inapp")

func _on_sku_details_completed(products: Array) -> void:
	for product in products:
		print("Item: ", product.sku, " | Price: ", product.price)

func buy_product(sku_id: String) -> void:
	if payment:
		var response = payment.purchase(sku_id)
		if response.status != OK:
			print("Error initiating purchase for SKU: ", sku_id)

func _on_purchases_updated(purchases: Array) -> void:
	for purchase in purchases:
		# purchase_state == 1 indicates a successful purchase
		if purchase.purchase_state == 1:
			_process_purchase(purchase)

func _process_purchase(purchase: Dictionary) -> void:
	var sku = purchase.skus[0]
	
	if sku == "gem_pack_100":
		# Consumable item: consume so the player can buy it again
		payment.consumePurchase(purchase.purchase_token)
		# Grant 100 gems to player
	elif sku == "remove_interstitials":
		# Non-consumable: must acknowledge purchase to keep it active
		if not purchase.is_acknowledged:
			payment.acknowledgePurchase(purchase.purchase_token)
		# Grant ad removal benefit

func _on_purchase_consumed(purchase_token: String) -> void:
	print("Consumable purchase finalized: ", purchase_token)

func _on_purchase_acknowledged(purchase_token: String) -> void:
	print("Non-consumable purchase acknowledged: ", purchase_token)

func _on_disconnected() -> void:
	print("Billing service disconnected.")

func _on_connect_error(code: int, message: String) -> void:
	print("Connection error: ", code, " - ", message)
