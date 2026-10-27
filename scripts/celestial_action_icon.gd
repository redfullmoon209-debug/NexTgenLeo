extends Control
## Device-independent line artwork rendered directly on each combat button.
var action_id := 0

func _stroke(a: Vector2, b: Vector2, tint: Color, width: float) -> void:
	draw_line(a, b, tint, width, true)

func _draw() -> void:
	if size.x < 15.0 or size.y < 15.0:
		return
	var style = load("res://scripts/celestial_steel.gd")
	var ink: Color = style.accent(action_id)
	var white := Color("#EDF6FF")
	var center := Vector2(size.x * 0.5, size.y * 0.37)
	var r := minf(size.x, size.y) * 0.19
	var w := maxf(1.8, r * 0.24)
	# Small halo gives every action a coherent silver-rune silhouette.
	draw_arc(center, r * 1.44, deg_to_rad(211), deg_to_rad(338), 18, Color(ink, 0.58), maxf(1.0, w * 0.48), true)
	match action_id:
		0: # target sight
			draw_arc(center, r, 0.0, TAU, 32, white, w * 0.65, true)
			_stroke(center + Vector2(-r * 1.6, 0), center + Vector2(-r * 0.55, 0), ink, w)
			_stroke(center + Vector2(r * 0.55, 0), center + Vector2(r * 1.6, 0), ink, w)
			_stroke(center + Vector2(0, -r * 1.6), center + Vector2(0, -r * 0.55), ink, w)
			_stroke(center + Vector2(0, r * 0.55), center + Vector2(0, r * 1.6), ink, w)
			draw_circle(center, r * 0.14, ink)
		1: # treasure diamond
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, -r * 0.15), center + Vector2(0, r), center + Vector2(-r, -r * 0.15)]), ink)
			_stroke(center + Vector2(-r * 0.7, -r * 0.16), center + Vector2(r * 0.7, -r * 0.16), white, w * 0.42)
			_stroke(center + Vector2(0, -r * 0.8), center + Vector2(0, r * 0.75), white, w * 0.35)
		2: # crossed swords
			_stroke(center + Vector2(-r, -r), center + Vector2(r, r), white, w * 1.15)
			_stroke(center + Vector2(r, -r), center + Vector2(-r, r), ink, w * 1.15)
			_stroke(center + Vector2(-r * 1.15, r * 0.45), center + Vector2(-r * 0.45, r * 1.15), white, w * 0.65)
			_stroke(center + Vector2(r * 1.15, r * 0.45), center + Vector2(r * 0.45, r * 1.15), ink, w * 0.65)
		3: # cleaving crescent
			draw_arc(center, r * 1.05, deg_to_rad(-105), deg_to_rad(145), 26, ink, w * 1.5, true)
			_stroke(center + Vector2(-r * 0.45, r * 0.7), center + Vector2(r * 0.95, -r * 0.82), white, w)
		4: # arcane burst
			for n in range(6):
				var direction := Vector2.UP.rotated(float(n) * TAU / 6.0)
				_stroke(center + direction * r * 0.38, center + direction * r * 1.30, ink, w * 0.82)
			draw_circle(center, r * 0.40, white)
		5: # focused magic projectile
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -r * 1.25), center + Vector2(r * 0.78, r * 0.42), center + Vector2(0, r * 0.80), center + Vector2(-r * 0.78, r * 0.42)]), ink)
			_stroke(center + Vector2(0, -r * 0.88), center + Vector2(0, r * 0.55), white, w * 0.75)
		6: # speed streaks
			for n in range(3):
				var dy := float(n - 1) * r * 0.65
				_stroke(center + Vector2(-r * 1.15, dy), center + Vector2(r * (0.45 if n == 1 else 0.90), dy - r * 0.2), ink if n != 1 else white, w * 0.8)
		7: # auto cycle
			draw_arc(center, r, deg_to_rad(-50), deg_to_rad(195), 28, ink, w * 0.85, true)
			draw_arc(center, r, deg_to_rad(125), deg_to_rad(370), 28, white, w * 0.60, true)
			_stroke(center + Vector2(-r * 0.98, -r * 0.22), center + Vector2(-r * 0.36, r * 0.1), ink, w)
