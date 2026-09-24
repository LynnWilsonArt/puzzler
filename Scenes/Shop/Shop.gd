# res://Shop.gd
# Attach to your Shop Control Node
extends Control


@onready var restore_purchase_button: Button = $ColorRect/RestorePurchaseButton
@onready var remove_ads_button: Button = $ColorRect/RemoveAdsButton
@onready var status_label: Label = $ColorRect/StatusLabel

func _ready() -> void:
	print("[Shop] Initilizing shop.gd")
	# Connect to global IAPManager signals
	IAPManager.iap_ready.connect(_on_iap_ready)
	IAPManager.purchase_succeeded.connect(_on_purchase_succeeded)
	IAPManager.purchase_failed.connect(_on_purchase_failed)
	IAPManager.restore_completed.connect(_on_restore_completed)
	IAPManager.product_revoked.connect(_on_product_revoked)

	# Connect UI buttons
	remove_ads_button.pressed.connect(_on_remove_ads_pressed)
	restore_purchase_button.pressed.connect(_on_restore_purchase_pressed)

	# Initial UI check if product prices or ownership are already loaded
	_update_ui()

# ------------------------------------------------------------------------------
# UI BUTTON HANDLERS
# ------------------------------------------------------------------------------
func _on_remove_ads_pressed() -> void:
	print("[Shop]  _on_remove_ads_pressed()")
	if status_label:
		status_label.text = "Connecting to Google Play..."
	IAPManager.buy_remove_interstitials()

func _on_restore_purchase_pressed() -> void:
	print("[Shop] _on_restore_purchase_pressed()")
	if status_label:
		status_label.text = "Restoring purchases..."
	restore_purchase_button.disabled = true
	IAPManager.restore_purchases()

# ------------------------------------------------------------------------------
# IAP MANAGER SIGNAL CALLBACKS
# ------------------------------------------------------------------------------
func _on_iap_ready() -> void:
	print("[Shop] _on_iap_ready()")
	_update_ui()

func _update_ui() -> void:
	print("[Shop] _update_ui() - owned_products: ", IAPManager.owned_products)

	if IAPManager.owned_products.has("remove_interstitials"):
		print("[Shop] _update_ui() - taking OWNED branch")
		remove_ads_button.disabled = true
		remove_ads_button.text = "Ads Removed"
		return

	print("[Shop] _update_ui() - taking NOT-OWNED branch")
	# Check if price details are available
	if "remove_interstitials" in IAPManager.cached_products:
		var product = IAPManager.cached_products["remove_interstitials"]
		var offers: Array = product.get("one_time_purchase_offer_details_list", [])
		var price: String = offers[0].get("formatted_price", "") if not offers.is_empty() else ""
		remove_ads_button.text = "Remove Ads (" + price + ")" if price != "" else "Remove Ads"

func _on_purchase_succeeded(product_id: String) -> void:
	print("[Shop] _on_purchase_secceeded()")
	if product_id == "remove_interstitials":
		remove_ads_button.disabled = true
		remove_ads_button.text = "Ads Removed"

		if status_label:
			status_label.text = "Purchase successful! Ads removed."

func _on_restore_completed(found_purchases: bool) -> void:
	print("[Shop] _on_restore_completed()")
	restore_purchase_button.disabled = false

	if status_label:
		if found_purchases:
			status_label.text = "Purchases successfully restored!"
		else:
			status_label.text = "No previous purchases found."

func _on_purchase_failed(_product_id: String, error_message: String) -> void:
	print("[Shop] _on_purchase_failed()")
	restore_purchase_button.disabled = false
	if status_label:
		status_label.text = "Transaction failed: " + error_message

func _on_product_revoked(product_id: String) -> void:
	print("[Shop] _on_product_revoked()")
	if product_id == "remove_interstitials":
		remove_ads_button.disabled = false
		if status_label:
			status_label.text = "Your purchase was refunded/revoked."
		_update_ui()
