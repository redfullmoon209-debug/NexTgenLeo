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
	state.gender = "Male"
	state.selected_job = ""
	state.selected_element = ""
	state.equipped.clear()
	state.buffs.clear()
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
	state.equipped.weapon.enhancement = 3
	var inventory_before: int = state.inventory.size()
	check(state.select_job("wind_assassin") and state.equipped.weapon.enhancement == 3, "repeat profession preserves equipment")
	check(state.inventory.size() == inventory_before, "repeat profession never duplicates equipment")
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

	var wheel_start: float = scene.camera.position.z
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = Vector2(700,400)
	root.push_input(wheel, true)
	check(scene.camera.position.z < wheel_start, "wheel zoom after closing a menu")
	game._show_panel("Bag")
	var blocked_zoom: float = scene.camera.position.z
	root.push_input(wheel.duplicate(),true)
	check(is_equal_approx(scene.camera.position.z,blocked_zoom), "bag scroll does not zoom camera")
	game._close_panel()
	# Real input dispatch: joystick and a second action finger must coexist.
	var origin: Vector2 = scene.joystick_origin
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = origin
	touch.pressed = true
	root.push_input(touch, true)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = origin + Vector2(35,0)
	drag.relative = Vector2(35,0)
	root.push_input(drag, true)
	await process_frame
	check(scene.joystick_vector.length() > .4, "touch joystick moves")
	game.target = 1
	var action := InputEventScreenTouch.new()
	action.index = 1
	action.position = game.skill_buttons[2].global_position + Vector2(20,20)
	action.pressed = true
	root.push_input(action, true)
	check(game.auto_attack and scene.joystick_finger == 0, "second action finger does not steal joystick")
	action.pressed = false
	root.push_input(action, true)
	touch.pressed = false
	touch.position = game.skill_buttons[2].global_position + Vector2(20,20)
	root.push_input(touch, true)
	check(scene.joystick_vector == Vector2.ZERO and scene.joystick_finger == -1, "joystick release over GUI resets")
	game.auto_attack = false
	var zoom_before: float = scene.camera.position.z
	for finger in [2,3]:
		var start := InputEventScreenTouch.new()
		start.index = finger
		start.position = Vector2(700+(finger-2)*180,230)
		start.pressed = true
		root.push_input(start, true)
	for x in [900,980]:
		var pinch := InputEventScreenDrag.new()
		pinch.index = 3
		pinch.position = Vector2(x,230)
		pinch.relative = Vector2(20,0)
		root.push_input(pinch, true)
	check(scene.camera.position.z < zoom_before, "two camera fingers pinch zoom")
	for finger in [2,3]:
		var finish := InputEventScreenTouch.new()
		finish.index = finger
		finish.pressed = false
		root.push_input(finish, true)
	# Verify actual serialized save round-trip without changing any prior local save.
	var save_path: String = state.SAVE_PATH
	var existed := FileAccess.file_exists(save_path)
	var previous := FileAccess.get_file_as_bytes(save_path) if existed else PackedByteArray()
	state.gold = 123
	check(state.save_game(), "save write")
	state.gold = 0
	check(state.load_game() and state.gold == 123, "save load round trip")
	if existed:
		var restore := FileAccess.open(save_path,FileAccess.WRITE)
		restore.store_buffer(previous)
		restore.close()
	else: DirAccess.remove_absolute(save_path)
	# Avoid save writes during tests; call warp directly only in manual acceptance.
	scene.queue_free()
	await process_frame
	print("GAME TESTS: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
