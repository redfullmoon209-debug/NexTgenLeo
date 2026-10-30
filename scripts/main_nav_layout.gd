extends RefCounted
## Shared geometry for ALL eight independent top-level buttons.
## 0 GM, 1 Character Status, 2 Bag, 3 Menu, 4 Guild, 5 Party, 6 Friends, 7 Notice.
## Every slot is at exactly the same Y, including on portrait mobile.
const Responsive = preload("res://scripts/responsive_ui.gd")
const COUNT := 8

static func slots(viewport: Viewport) -> Array[Rect2]:
	var view: Vector2 = viewport.get_visible_rect().size
	var safe: Rect2 = Responsive.safe_bounds(viewport)
	var portrait: bool = view.y > view.x
	var scale: float = Responsive.input_scale(safe, float(GameState.settings.get("ui_scale", 1.0))) if portrait else 1.0
	var gap: float = (4.7 * scale) if portrait else 6.0
	var width: float
	var left: float
	var top: float
	if portrait:
		# One row is possible at 430px: eight ~44px targets, no wrap.
		# Scale in Godot canvas units (web virtual resolutions may be 3x larger).
		var inset: float = 8.0 * scale
		width = maxf(12.0, minf(78.0 * scale, (safe.size.x - inset * 2.0 - gap * 7.0) / 8.0))
		var row_width: float = width * float(COUNT) + gap * float(COUNT - 1)
		left = safe.position.x + maxf(0.0, (safe.size.x - row_width) / 2.0)
		# Stay below the portrait status/map region, never split into two rows.
		top = minf(262.0 * scale, maxf(safe.position.y, safe.end.y - width - 12.0 * scale))
	else:
		var wide: bool = view.x >= 1160.0
		# Large desktop: reserve status panel at left and the minimap at right.
		# Smaller landscape: use the safe single-row band below the hint panel.
		var left_band: float = 370.0 if wide else 12.0
		var right_band: float = 176.0 if wide else minf(130.0, view.x * 0.135)
		var available: float = maxf(80.0, view.x - left_band - right_band)
		width = maxf(12.0, minf(83.0, (available - gap * 7.0) / 8.0))
		var row_width: float = width * float(COUNT) + gap * float(COUNT - 1)
		left = left_band + maxf(0.0, (available - row_width) / 2.0)
		# Avoid overlapping existing notification/status panels and the minimap.
		top = 184.0 if wide else 108.0
	var out: Array[Rect2] = []
	for i in range(COUNT):
		out.append(Rect2(Vector2(left + float(i) * (width + gap), top), Vector2(width, width)))
	return out

static func slot(viewport: Viewport, index: int) -> Rect2:
	return slots(viewport)[clampi(index, 0, COUNT - 1)]
