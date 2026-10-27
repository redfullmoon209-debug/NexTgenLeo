extends RefCounted
## Shared responsive coordinates for the gameplay HUD and inventory.
## All dimensions are Godot canvas coordinates, never hard-coded device pixels.

static func is_portrait(view_size: Vector2) -> bool:
	return view_size.y > view_size.x

static func safe_bounds(viewport: Viewport, padding: float = 12.0) -> Rect2:
	var view_size: Vector2 = viewport.get_visible_rect().size
	var left := padding
	var top := padding
	var right := padding
	var bottom := padding
	# Native safe-area values use display pixels; convert to canvas coordinates.
	# Web builds retain the conservative inset until CSS env() insets are bridged.
	if OS.has_feature("mobile") and not OS.has_feature("web"):
		var display_size: Vector2i = DisplayServer.screen_get_size()
		var native_safe: Rect2i = DisplayServer.get_display_safe_area()
		if display_size.x > 0 and display_size.y > 0 and native_safe.size.x > 0 and native_safe.size.y > 0:
			var ratio_x := view_size.x / float(display_size.x)
			var ratio_y := view_size.y / float(display_size.y)
			left = maxf(left, float(native_safe.position.x) * ratio_x + padding)
			top = maxf(top, float(native_safe.position.y) * ratio_y + padding)
			right = maxf(right, float(display_size.x - native_safe.end.x) * ratio_x + padding)
			bottom = maxf(bottom, float(display_size.y - native_safe.end.y) * ratio_y + padding)
	return Rect2(Vector2(left, top), Vector2(maxf(1.0, view_size.x - left - right), maxf(1.0, view_size.y - top - bottom)))

static func input_scale(bounds: Rect2, requested: float = 1.0) -> float:
	var user_scale := clampf(requested, 0.85, 1.20)
	if is_portrait(bounds.size):
		# The Web canvas can retain a 720/1280-wide virtual viewport on a
		# 390-pixel phone. Normalize to a 390-unit ergonomic portrait design.
		return maxf(0.90, bounds.size.x / 390.0) * user_scale
	var height_factor := bounds.size.y / 520.0
	return minf(user_scale, maxf(0.72, height_factor))

static func keep_inside(rect: Rect2, bounds: Rect2) -> Rect2:
	var adjusted_size := Vector2(minf(rect.size.x, bounds.size.x), minf(rect.size.y, bounds.size.y))
	var adjusted_position := Vector2(
		clampf(rect.position.x, bounds.position.x, bounds.end.x - adjusted_size.x),
		clampf(rect.position.y, bounds.position.y, bounds.end.y - adjusted_size.y)
	)
	return Rect2(adjusted_position, adjusted_size)

static func action_slot_rect(index: int, bounds: Rect2, requested_scale: float = 1.0) -> Rect2:
	var scale := input_scale(bounds, requested_scale)
	var result: Rect2
	if not is_portrait(bounds.size):
		# Keep the established landscape 3x3 grid and PC touch test coordinates.
		var button_size := Vector2(90, 65) * scale
		var origin := Vector2(bounds.end.x - 318.0 * scale, bounds.end.y - 228.0 * scale)
		var offset := Vector2(float(index % 3) * 102.0 * scale, float(index / 3) * 73.0 * scale)
		result = Rect2(origin + offset, button_size)
	else:
		# Two thumb-friendly columns and a larger attack control.
		var small := 52.0 * scale
		var attack := 68.0 * scale
		var gap := 6.0 * scale
		var left_x := bounds.end.x - attack - small - gap
		var right_x := bounds.end.x - small
		var coords := [
			Vector2(left_x, bounds.end.y - 246.0 * scale), # Lock
			Vector2(right_x, bounds.end.y - 246.0 * scale), # Pick up
			Vector2(bounds.end.x - attack, bounds.end.y - attack), # Basic ATK
			Vector2(left_x, bounds.end.y - small), # Skill 1
			Vector2(left_x, bounds.end.y - small * 2.0 - gap), # Skill 2
			Vector2(right_x, bounds.end.y - attack - small - gap), # Skill 3
			Vector2(left_x, bounds.end.y - small * 3.0 - gap * 2.0), # Dash
			Vector2(right_x, bounds.end.y - attack - small * 2.0 - gap * 2.0), # Auto
		]
		result = Rect2(coords[clampi(index, 0, coords.size() - 1)], Vector2.ONE * (attack if index == 2 else small))
	return keep_inside(result, bounds)

static func offsets_key(view_size: Vector2) -> String:
	return "button_offsets_portrait" if is_portrait(view_size) else "button_offsets_landscape"

static func two_column_inventory(view_size: Vector2, panel_width: float) -> bool:
	return not is_portrait(view_size) and view_size.y >= 540.0 and panel_width >= 550.0
