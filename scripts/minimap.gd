extends Control
## Celestial Steel circular minimap. All markers are rendered as native canvas
## primitives and remain legible without downloaded textures.
var game: Node

func _draw() -> void:
	var center := Vector2(77.0, 77.0)
	draw_circle(center, 76.0, Color("#071321E9"))
	draw_circle(center, 68.0, Color("#15334DDA"))
	draw_arc(center, 74.0, 0.0, TAU, 96, Color("#C5D5E8"), 3.0, true)
	draw_arc(center, 70.0, deg_to_rad(-146.0), deg_to_rad(-17.0), 32, Color("#E7CF97"), 3.0, true)
	draw_arc(center, 70.0, deg_to_rad(35.0), deg_to_rad(151.0), 32, Color("#85C5F3"), 2.0, true)
	for distance in [22.0, 46.0]:
		draw_arc(center, distance, 0.0, TAU, 64, Color("#81A8C64D"), 1.0, true)
	for degree in range(0, 360, 45):
		var dir := Vector2.UP.rotated(deg_to_rad(float(degree)))
		draw_line(center + dir * 63.0, center + dir * (69.0 if degree % 90 == 0 else 66.0), Color("#C5D6E5C9"), 2.0, true)
	draw_line(center + Vector2(-64, 0), center + Vector2(64, 0), Color("#9BB8D12B"), 1.0, true)
	draw_line(center + Vector2(0, -64), center + Vector2(0, 64), Color("#9BB8D12B"), 1.0, true)
	if not is_instance_valid(game):
		return
	for mob in game.mobs:
		if int(mob.hp) > 0:
			var offset: Vector3 = mob.node.position - game.world.player.position
			var point := Vector2(offset.x, offset.z) * 2.0
			if point.length() < 62.0:
				draw_circle(center + point, 5.0, Color("#622C43C8"))
				draw_circle(center + point, 2.8, Color("#FF9E8C"))
	if is_instance_valid(game.npc):
		var npc_offset: Vector3 = game.npc.position - game.world.player.position
		var npc_pos := Vector2(npc_offset.x, npc_offset.z) * 2.0
		if npc_pos.length() < 62.0:
			draw_circle(center + npc_pos, 6.0, Color("#61462CCD"))
			draw_colored_polygon(PackedVector2Array([
				center + npc_pos + Vector2(0, -4.2),
				center + npc_pos + Vector2(4.2, 0),
				center + npc_pos + Vector2(0, 4.2),
				center + npc_pos + Vector2(-4.2, 0)
			]), Color("#F4D792"))
	draw_circle(center, 7.5, Color("#0B273B"))
	draw_arc(center, 7.5, 0.0, TAU, 32, Color("#BEDDF7"), 1.5, true)
	var heading := Vector2.UP.rotated(-game.world.yaw)
	draw_colored_polygon(PackedVector2Array([
		center + heading * 8.0,
		center + heading.rotated(2.4) * 5.5,
		center + heading.rotated(-2.4) * 5.5
	]), Color("#91E3F4"))
