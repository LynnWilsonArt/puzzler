extends Node
# res://scene/puzzle/toggle_puzzle_display.gd

# Indicates whether the puzzle (Puzzle reference image) is currently shown.
var toggle_puzzle = false

# Used to keep track of the most recent timer.  Each time a new timer starts
# this value is incremented.  The timer will check this value when it
# finishes to make sure it hasn't become stale (i.e. a newer timer was
# started in the meantime).  This prevents overlapping timers from
# interfering with each other.
var timer_token = 0   # ADD THIS: invalidates stale timers when a new one starts

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _ready()")
	# The first image load will trigger the preview via
	# _on_change_puzzle_image_requested() (see that function).

# Called when the user performs a right‑click (the UI action is wired in
# the editor to call this method).
func _on_right_click_triggered() -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _on_right_click_triggered()")
	# Toggle the state of the puzzle flag.
	toggle_puzzle = !toggle_puzzle
	print("Puzzle Toggled via Right-Click ", toggle_puzzle)
	# Show or hide the Puzzle node according to the new state.
	$Puzzle.visible = toggle_puzzle

# Handles input events.  If the "toggle_puzzle" action is pressed,
# it simply forwards the call to the right‑click handler.
func _input(event):
	if event.is_action_pressed("toggle_puzzle"):
		_on_right_click_triggered()

# Starts a 5‑second timer that will automatically hide the puzzle
# after the preview period expires.  The timer is identified by
# `my_token` to avoid acting on a stale timer if another one
# has already started.
func _start_puzzle_timer() -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _start_puzzle_timer()")
	timer_token += 1
	var my_token = timer_token   # snapshot this timer's identity
	print("Puzzle Display Timer started!")
	# Wait for 5 seconds.  This `await` yields until the timer times out.
	await get_tree().create_timer(5.0).timeout
	# If a newer timer started in the meantime (e.g. Skip fired),
	# ignore this stale one.
	if my_token != timer_token:
		return
	# When the timer expires, trigger the timeout handler.
	_on_timer_timeout()

# Called when the 5‑second timer from `_start_puzzle_timer()` finishes.
func _on_timer_timeout() -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _on_timer_timeout()")
	if toggle_puzzle:
		print("Puzzle preview time's up! -> hiding reference image")
		# Hide the puzzle after the preview period.
		toggle_puzzle = false
		$Puzzle.visible = false

# External callers can request the puzzle to be shown or hidden directly
# by providing the desired state (`true` or `false`).
func _on_puzzle_toggle_requested(state: bool) -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _on_puzzle_toggle_requested()")
	toggle_puzzle = state
	$Puzzle.visible = toggle_puzzle

# When a new puzzle image is requested (either on first load or when the
# user presses "Skip"), this function updates the texture and shows
# the preview.  It also starts the auto‑hide timer.
func _on_change_puzzle_image_requested(img: Texture2D) -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _on_change_puzzle_image_requested()")
	if img == null:
		push_error("Received null texture!")
		return
	# Update the Puzzle node's texture with the new image.
	$Puzzle/puzzle_image.texture = img
	# Every new image (first load AND every Skip): show reference, then auto‑hide after 5s
	toggle_puzzle = true
	$Puzzle.visible = true
	_start_puzzle_timer()
	print("Changed puzzle_image")

# Handler for a button that toggles the display of the original image.
func _on_show_original_image_pressed() -> void:
	if Globals.debug:
		print("DEBUG -> toggle_puzzle_display.gd -> _on_show_original_image_pressed()")
	# Toggle the puzzle flag and update visibility accordingly.
	toggle_puzzle = !toggle_puzzle
	print("Show original image for reference: ", toggle_puzzle)
	$Puzzle.visible = toggle_puzzle
