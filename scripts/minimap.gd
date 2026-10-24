extends Control
var game: Node
func _draw() -> void:
	draw_circle(Vector2(77,77),75,Color("162b3de8"))
	draw_arc(Vector2(77,77),75,0,TAU,64,Color("bba77b"),2,true)
	if not is_instance_valid(game): return
	for mob in game.mobs:
		if int(mob.hp) > 0:
			var offset: Vector3 = mob.node.position - game.world.player.position
			var point := Vector2(offset.x,offset.z) * 2
			if point.length() < 70: draw_circle(Vector2(77,77)+point,3,Color("e08b79"))
	var npc_offset: Vector3 = game.npc.position - game.world.player.position
	if Vector2(npc_offset.x,npc_offset.z).length() < 35:
		draw_circle(Vector2(77,77)+Vector2(npc_offset.x,npc_offset.z)*2,4,Color("f4d784"))
	draw_circle(Vector2(77,77),4,Color("91d8f4"))
	draw_line(Vector2(77,77),Vector2(77,77)+Vector2(0,-14).rotated(-game.world.yaw),Color.WHITE,2)
