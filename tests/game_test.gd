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
	check(game.buttons.size() == 2, "nine menu shortcuts replaced by one player control and one owner-only control")
	check(not game.owner_gm_button.visible and not game.gm_authorized, "guest never sees GM")
	game._show_panel("GM")
	check(not game.panel.visible and game.active_panel != "GM", "direct GM panel opening rejected for guest")
	game._toggle_player_dropdown()
	check(game.player_dropdown.visible and game.dropdown_backdrop.visible, "yellow main-menu dropdown opens")
	check(game.dropdown_entries.size() == 10, "all ten player menus are in dropdown")
	game._open_player_menu("Bag")
	check(not game.player_dropdown.visible and game.active_panel == "Bag", "dropdown item opens original bag and closes overlay")
	game._close_panel()
	game._toggle_player_dropdown()
	game._toggle_player_dropdown()
	check(not game.player_dropdown.visible and not game.dropdown_backdrop.visible, "yellow menu toggles closed")
	game._show_panel("Bag")
	await process_frame
	check(game.panel.position.x <= 16 and game.panel.position.y <= 16, "dual-pane menu docked at top-left")
	check(game.panel.size.x <= 620 and game.panel.size.x > 500, "compact two-pane bag leaves center of scene visible")
	var viewport_height: float = scene.get_viewport().get_visible_rect().size.y
	check(game.panel.size.y >= viewport_height - 30.0, "compact bag stretches almost to the bottom")
	check(game.panel.position.y + game.panel.size.y <= viewport_height - 8.0, "bag fits within viewport bottom")
	var actor_screen: Vector2 = scene.camera.unproject_position(scene.player.position)
	check(game.panel.position.x + game.panel.size.x < actor_screen.x - 20, "world character remains visible beside bag")
	check(game.panel.z_index >= 50 and game.panel.get_index() == game.panel.get_parent().get_child_count() - 1, "bag stays above other HUD elements")
	check(game.bag_character_panel != null and game.bag_inventory_panel != null, "character and bag panes created")
	check(game.bag_slot_grid != null and game.bag_slot_grid.columns == 5, "compact bag grid has five columns")
	check(game.bag_slot_grid.get_child_count() == 100, "current bag page has 100 item slots")
	check(game.bag_equipment_frame != null and game.bag_equipment_buttons.size() == 19, "all 19 named equipment slots are created")
	check(game.bag_slot_regions.size() == 19, "all equipment slots have a recorded region")
	for armor_id in ["hat", "shirt", "gloves", "pants", "shoes"]:
		check(game.bag_slot_regions.get(armor_id, "") == "armor", "right-hand armor slot " + armor_id)
	for weapon_id in ["weapon", "weapon_left"]:
		check(game.bag_slot_regions.get(weapon_id, "") == "weapon", "left-hand weapon slot " + weapon_id)
	check(game.bag_slot_regions.get("mount", "") == "mount" and game.bag_slot_regions.get("loot_pet", "") == "pet", "mount and auto-loot pet have independent slots")
	for jewel_id in ["ring", "bracelet_left", "accessory", "bracelet_right", "ring_right"]:
		check(game.bag_slot_regions.get(jewel_id, "") == "jewelry", "silver jewelry slot " + jewel_id)
	for fashion_id in ["fashion_hat", "fashion_shirt", "fashion_gloves", "fashion_pants", "fashion_shoes"]:
		check(game.bag_slot_regions.get(fashion_id, "") == "fashion", "separate fashion slot " + fashion_id)
	check(game.bag_character_preview != null and game.bag_preview_stage != null, "left character pane includes an isolated 3D avatar viewport")
	check(is_instance_valid(game.bag_preview_model) and game.bag_preview_model.get_child_count() >= 6, "preview reuses the actual game player mesh")
	var original_preview: Node3D = game.bag_preview_model
	state.gender = "Female"
	state.appearance_changed.emit()
	check(is_instance_valid(game.bag_preview_model) and game.bag_preview_model != original_preview, "character preview refreshes when appearance changes")
	state.gender = "Male"
	state.appearance_changed.emit()
	check("คลาส" in game.bag_status_label.text, "left character pane shows Thai stats")
	var left_rect: Rect2 = game.bag_character_panel.get_global_rect()
	var right_rect: Rect2 = game.bag_inventory_panel.get_global_rect()
	check(left_rect.position.x < right_rect.position.x and left_rect.end.x <= right_rect.position.x + 1, "stats on left and inventory on right")
	check(right_rect.end.x <= game.panel.get_global_rect().end.x + 1, "inventory remains within panel bounds")
	game._close_panel()
	# New equipment categories can be equipped without altering combat stats.
	var unmodified_defense: int = state.defense()
	check(state.add_item("fashion_hat"), "fashion item can be obtained")
	var fashion_index := -1
	for i in range(state.inventory.size()):
		if state.inventory[i].id == "fashion_hat":
			fashion_index = i
	check(fashion_index >= 0, "fashion item entered bag")
	if fashion_index >= 0:
		state.use_item(fashion_index)
		check("fashion_hat" in state.equipped, "fashion item occupies its cosmetic slot")
		check(state.defense() == unmodified_defense, "fashion is visual-only and does not boost defense")
		check(state.unequip("fashion_hat"), "fashion can be removed")
		for i in range(state.inventory.size()):
			if state.inventory[i].id == "fashion_hat":
				state.remove_item(i)
				break
	check(state.add_item("offhand_blade"), "left-hand weapon can be obtained")
	var offhand_index := -1
	for i in range(state.inventory.size()):
		if state.inventory[i].id == "offhand_blade":
			offhand_index = i
	if offhand_index >= 0:
		state.use_item(offhand_index)
		check("weapon_left" in state.equipped, "left-hand weapon fits its own slot")
		check(state.unequip("weapon_left"), "left-hand weapon can be unequipped")
		for i in range(state.inventory.size()):
			if state.inventory[i].id == "offhand_blade":
				state.remove_item(i)
				break
	for name in ["Bag","Shop","Cash","Status","Quest","World","Pet","Auto","Skills","Settings","OwnerLogin","GM"]:
		game._close_panel()
		if name == "GM":
			game._set_gm_authorized(true)
			check(game.owner_gm_button.visible, "owner authorization enables red GM button")
		game._show_panel(name)
		check(game.panel.visible, "open " + name)
	game._close_panel()
	game._set_gm_authorized(false)
	check(not game.owner_gm_button.visible, "logout hides red GM button again")
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
