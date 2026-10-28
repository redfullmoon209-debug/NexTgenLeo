extends Control
## Vector silhouette in the inventory while no pet is equipped.
## Does not replace an imported pet: equipped pets use a live 3D SubViewport.

func _draw() -> void:
	var scale_value: float = minf(size.x / 180.0, size.y / 130.0)
	var center := Vector2(size.x * 0.50, size.y * 0.57)
	draw_set_transform(center, 0.0, Vector2.ONE * scale_value)
	var shadow := Color("162a49")
	var rim := Color("5f82b2", 0.70)
	var sheen := Color("79a5e2", 0.23)
	# Soft moonlit oval below the silhouette.
	draw_arc(Vector2(0, 40), 56, 0, TAU, 42, sheen, 2.0)
	draw_arc(Vector2(0, 40), 43, 0, TAU, 42, Color("abc6f1", 0.12), 1.0)
	# Curled tail, torso and pointed ears, all deliberately shadow colored.
	draw_arc(Vector2(38, 15), 23, -1.3, 2.55, 22, shadow, 19.0, true)
	draw_circle(Vector2(0, 21), 31.0, shadow)
	draw_circle(Vector2(0, -19), 27.0, shadow)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24, -22), Vector2(-29, -57), Vector2(-4, -38)
	]), shadow)
	draw_colored_polygon(PackedVector2Array([
		Vector2(4, -38), Vector2(29, -57), Vector2(25, -22)
	]), shadow)
	# Clear contour for players to recognize an unequipped feline silhouette.
	draw_arc(Vector2(0, -19), 27.0, 0.0, TAU, 48, rim, 1.7)
	draw_arc(Vector2(0, 21), 31.0, 0.0, PI, 32, rim, 1.8)
	draw_line(Vector2(-24, -22), Vector2(-29, -57), rim, 1.8)
	draw_line(Vector2(-29, -57), Vector2(-4, -44), rim, 1.8)
	draw_line(Vector2(24, -22), Vector2(29, -57), rim, 1.8)
	draw_line(Vector2(29, -57), Vector2(4, -44), rim, 1.8)
	draw_line(Vector2(-18, 43), Vector2(-18, 56), rim, 2.0)
	draw_line(Vector2(18, 43), Vector2(18, 56), rim, 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
