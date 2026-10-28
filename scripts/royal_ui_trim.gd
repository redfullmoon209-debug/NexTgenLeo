extends Control
## Resolution-independent filigree trim for the premium fantasy inventory.
## Geometry is drawn in Godot so the UI stays sharp on high-DPI monitors.
## Mouse events always pass through to the real interactive controls below.

const GOLD := Color("#FFE5A0")
const AMBER := Color("#C99545")
const SAPPHIRE := Color("#55BDFF")
const DEEP_BLUE := Color("#0C4B96")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _diamond(center: Vector2, radius: float, ink: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius * 0.8, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius * 0.8, 0)
	]), ink)

func _draw() -> void:
	var width_px: float = size.x
	var height_px: float = size.y
	if width_px < 70.0 or height_px < 70.0:
		return
	# Three fine layers achieve a metallic edge without image scaling.
	draw_rect(Rect2(2, 2, width_px - 4, height_px - 4), Color("#F5C775", 0.90), false, 1.4, true)
	draw_rect(Rect2(5, 5, width_px - 10, height_px - 10), Color("#B67B3C", 0.76), false, 1.0, true)
	draw_rect(Rect2(8, 8, width_px - 16, height_px - 16), Color("#287BCA", 0.55), false, 1.0, true)
	# Sapphire gleam in the upper rail. Line length scales with the panel.
	var rail_length: float = minf(68.0, width_px * 0.19)
	draw_line(Vector2(width_px * 0.5 - rail_length, 5), Vector2(width_px * 0.5 - 6, 5), Color("#339FEA", 0.85), 1.5, true)
	draw_line(Vector2(width_px * 0.5 + 6, 5), Vector2(width_px * 0.5 + rail_length, 5), Color("#339FEA", 0.85), 1.5, true)
	_diamond(Vector2(width_px * 0.5, 5), 5.2, GOLD)
	_diamond(Vector2(width_px * 0.5, 5), 2.6, SAPPHIRE)
	var reach: float = minf(19.0, minf(width_px, height_px) * 0.12)
	for corner in range(4):
		var xs: float = 1.0 if corner % 2 == 0 else -1.0
		var ys: float = 1.0 if corner < 2 else -1.0
		var base := Vector2(4.0 if xs > 0 else width_px - 4.0, 4.0 if ys > 0 else height_px - 4.0)
		# Gold filigree returns inside the frame in an L-shaped flourish.
		draw_line(base + Vector2(xs * 2, ys * reach), base + Vector2(xs * reach * 0.50, ys * reach * 0.55), AMBER, 1.5, true)
		draw_line(base + Vector2(xs * reach * 0.50, ys * reach * 0.55), base + Vector2(xs * reach, ys * 2), GOLD, 1.6, true)
		draw_arc(base + Vector2(xs * 12, ys * 12), 5.5, 0, TAU, 24, Color("#58AFFF", 0.72), 1.0, true)
		_diamond(base + Vector2(xs * 10.0, ys * 10.0), 3.2, GOLD)
		_diamond(base + Vector2(xs * 10.0, ys * 10.0), 1.6, SAPPHIRE)
	# Bottom center keystone for large inventory windows.
	if width_px > 220:
		_diamond(Vector2(width_px * 0.5, height_px - 5), 4.2, Color("#E8C67F", 0.90))
