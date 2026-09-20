extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	await get_tree().create_timer(Globals.banner_ad_time, true, true).timeout
	#AdMobBanner._destroy_banner_view()
	print(" Credits -> Destroyed banner ad")
