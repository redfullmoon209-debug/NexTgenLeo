extends SceneTree
var failures := 0
var checks := 0
func check(value: bool, name: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + name)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var state = root.get_node("GameState")
	state.inventory.clear()
	check(state.add_item("herb", 199), "grant multiple stacks")
	check(state.inventory.size() == 3 and state.inventory[0].count == 99, "99 stack cap")
	state.inventory.clear()
	for i in range(200): state.add_item("sword")
	check(not state.add_item("herb") and state.inventory.size() == 200, "full inventory rejects transaction")
	state.inventory.clear()
	state.add_item("herb",98)
	for i in range(199): state.add_item("sword")
	check(not state.add_item("herb",2) and state.inventory[0].count == 98, "failure never partially grants")
	state.inventory.clear()
	state.gold = 10
	check(not state.buy("potion") and state.gold == 10, "insufficient funds")
	state.gold = 100
	check(state.buy("potion",2) and state.gold == 70, "buy charges server catalog price")
	check(state.sell(0,1) and state.gold == 75, "sell exact quantity")
	state.class_rank = 0
	state.level = 1
	state.exp = 0
	state.add_exp(100)
	check(state.level == 2 and state.exp == 0, "level transition")
	state.level = 100
	state.advancement_ready = false
	check(not state.advance_class(), "quest gate")
	state.advancement_ready = true
	check(state.advance_class() and state.level == 1 and state.class_rank == 1, "class reset")
	state.class_rank = 3
	check(state.select_element("Wind"), "Class 3 element")
	check(state.set_skill_slot(0,2), "Class 3 free loadout")
	check(not state.select_job("wind_assassin"), "profession locked before Class 5")
	state.class_rank = 5
	check(not state.select_job("water_mage"), "profession must match element")
	check(state.select_job("wind_assassin"), "Class 5 profession")
	check(not state.set_skill_slot(0,1), "Class 5 fixed loadout")
	check(not state.select_element("Water"), "element locked to profession")
	check(not state.select_faction("Light"), "faction locked before Class 7")
	state.class_rank = 7
	check(state.select_faction("Light"), "Class 7 faction")
	check(state.balance.professions.size() == 12, "twelve confirmed professions")
	check(state.balance.skill_tiers.sovereign.unlock_class == null, "no invented sovereign unlock")
	state.class_rank = 10
	state.level = 100
	check(not state.advance_class(), "Class 10 cap")
	check(is_equal_approx(state.height_meters(),1.75), "male height cap")
	state.gender = "Female"
	check(is_equal_approx(state.height_meters(),1.70), "female height cap")
	state.quest_state = "available"
	state.quest_kills = 0
	state.record_kill()
	check(state.quest_kills == 0, "quest requires acceptance")
	state.interact_quest()
	for i in range(5): state.record_kill()
	state.interact_quest()
	check(state.quest_state == "complete", "accept kill turn-in quest")
	# Exercise actual scene and UI, combat, teleport, equipment and death branches.
	state.class_rank = 0
	state.level = 1
	state.gender = "Male"
	state.hp = 100
	state.map_index = 0
	state.location = [0.0,1.0,0.0]
	state.inventory.clear()
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var game = scene.gameplay
	check(game.mobs.size() == 14, "scene spawns monsters")
	for name in ["Bag","Shop","Cash","Status","Quest","World","Pet","Auto","Skills","Settings","GM"]:
		game._close_panel()
		game._show_panel(name)
		check(game.panel.visible, "open " + name)
	game._close_panel()
	game.target = 0
	game.mobs[0].node.position = scene.player.position + Vector3(0,0,-1)
	var before: int = game.mobs[0].hp
	game._attack(0)
	check(int(game.mobs[0].hp) < before, "attack applies damage")
	game.mobs[0].hp = 0
	game._killed(0)
	check(game.drops.size() == 1, "kill drops loot")
	game._pickup()
	check(game.drops.is_empty(), "pickup grants loot")
	state.add_item("hat")
	state.use_item(state.inventory.size()-1)
	check("hat" in state.equipped, "equipment changes appearance")
	state.hp = 0
	game._revive()
	check(state.hp > 0, "revive")
	# Avoid save writes during tests; call warp directly only in manual acceptance.
	scene.queue_free()
	await process_frame
	print("GAME TESTS: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
