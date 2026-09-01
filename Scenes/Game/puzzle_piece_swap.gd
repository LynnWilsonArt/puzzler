# res://Scenes/Game/puzzle_piece_swap.gd
extends TextureRect
# puzzle_piece_swap script to swap the puzzle pieces
# Signal that we use to tell the parent puzzle that this piece was clicked
signal piece_clicked(clicked_node: TextureRect)

# Keep the original texture around – we'll swap it in/out after the animation
var original_texture: Texture2D

# Keep track of active tweens safely in Godot 4
var active_tween: Tween = null

# Transition time
var trans_time: float = 0.4





func _ready() -> void:

	mouse_filter = Control.MOUSE_FILTER_STOP
	original_texture = texture

# Detect mouse clicks on the whole control
func _gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		piece_clicked.emit(self)

# -------------------------------------------------------
# The **core** animation logic lives here.  Each call
# will:
#   • pick a random style
#   • run that style in a Tween
#   • call `callback` when finished
# -------------------------------------------------------
func animate_swap(_target_piece: TextureRect, callback: Callable) -> void:
	print("Game -> puzzle_piece_swap.gd -> animate_swap()")
		
	# FIXED: Check if the current tween is running using Godot 4 syntax
	if active_tween and active_tween.is_running():
		return
	
	# FIXED: Godot 4 uses create_tween() instead of Tween.new()
	active_tween = create_tween()
	
	# Choose an animation style at random
	var style: int = randi() % 4  # 0-3
	match style:
		0:
			_fade_animation(active_tween, callback)
		1:
			_scale_animation(active_tween, callback)
		2:
			_rotate_animation(active_tween, callback)
		3:
			_flip_animation(active_tween, callback)

# ------------------------------------------------------------------
# 1️⃣  Fade: old piece fades out, new piece fades in
# ------------------------------------------------------------------
func _fade_animation(tween: Tween,callback: Callable) -> void:
	print("Game -> puzzle_piece_swap.gd -> _fade_animation()")
		
	# FIXED: Make both tweens run at the same time using parallel loops
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, trans_time)
	
	# Clean up opacity reset chained when the total sequence concludes
	tween.chain().tween_property(self, "modulate:a", 1.0, 0.0)
	
	print("Game -> puzzle_piece_swap.gd -> Fade transition")
	tween.finished.connect(callback)

# ------------------------------------------------------------------
# 2️⃣  Scale: shrink to 0, then grow to normal size
# ------------------------------------------------------------------
func _scale_animation(tween: Tween, callback: Callable) -> void:
	print("Game -> puzzle_piece_swap.gd -> _sacle_animation()")
		
	# FIXED: Animate 'self' to match main manager's dual-invocation loop
	pivot_offset = size / 2
	var orig_scale = scale 
	
	tween.tween_property(self, "scale", Vector2.ZERO, trans_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", orig_scale, trans_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	print("Game -> puzzle_piece_swap.gd -> Scale transition")
	tween.finished.connect(callback) 

# ------------------------------------------------------------------
# 3️⃣  Rotate: rotate 180° around the centre
# ------------------------------------------------------------------
func _rotate_animation(tween: Tween, callback: Callable) -> void:
	print("Game -> puzzle_piece_swap.gd -> _rotate_animation()")
		
	# FIXED: Animate 'self' to match main manager's dual-invocation loop
	pivot_offset = size / 2
	var orig_rotation = rotation
	
	tween.tween_property(self, "rotation", orig_rotation + PI, trans_time).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	# Clean up rotation values back to default after layout swaps textures
	tween.chain().tween_property(self, "rotation", orig_rotation, 0.0)
	print("Game -> puzzle_piece_swap.gd -> Rotate transition")
	tween.finished.connect(callback)

# ------------------------------------------------------------------
# 4️⃣  Flip: a horizontal “mirror” flip (scale.x = -1)
# ------------------------------------------------------------------
func _flip_animation(tween: Tween, callback: Callable) -> void:
	print("Game -> puzzle_piece_swap.gd -> _flip_animation()")
		
	# FIXED: Animate 'self' to match main manager's dual-invocation loop
	pivot_offset = size / 2
	var orig_scale = scale
	
	tween.tween_property(self, "scale:x", -orig_scale.x, trans_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale:x", orig_scale.x, trans_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	print("Game -> puzzle_piece_swap.gd ->Flip transition")
	tween.finished.connect(callback)
	
	# Add this inside res://Scenes/Game/puzzle_piece_swap.gd
func initialize_piece_meta(slot_id: int, original_texture_id: int) -> void:
	
	set_meta("correct_slot_id", slot_id)
	set_meta("current_texture_id", original_texture_id)
