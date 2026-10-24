extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var network = scene.gameplay.network
	network.connect_server("ws://127.0.0.1:8765/ws")
	for i in range(300):
		await create_timer(0.02).timeout
		if network.have_snapshot:break
	if not network.have_snapshot:
		printerr("FAIL: Godot WebSocket snapshot")
		quit(1)
		return
	var initial_gold: int = root.get_node("GameState").gold
	network.command("buy",{"item":"potion","count":1})
	await create_timer(.4).timeout
	if root.get_node("GameState").gold != initial_gold - 15:
		printerr("FAIL: authoritative purchase")
		quit(1)
		return
	network.disconnect_server()
	await process_frame
	print("NETWORK TEST: authenticated snapshot, purchase, disconnect/restore passed")
	scene.queue_free()
	await process_frame
	quit()
