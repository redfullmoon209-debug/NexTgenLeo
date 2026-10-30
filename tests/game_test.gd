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
	check(state.add_item("herb",3), "add separate stack for multi-sale")
	var early_inventory: Array[Dictionary] = state.inventory.duplicate(true)
	var early_gold: int = state.gold
	check(state.sell_many({0:2,1:1}) == -1, "invalid multi-sale rejects quantity larger than available")
	check(state.inventory == early_inventory and state.gold == early_gold, "rejected multi-sale changes neither gold nor inventory")
	check(state.sell_many({0:1,1:2}) == 13, "multi-sale pays exact combined gold")
	check(state.gold == early_gold + 13 and state.inventory.size() == 1 and int(state.inventory[0].count) == 1, "multi-sale removes descending indices without loss")
	check(state.sell_many({}) == -1, "empty bulk sale is rejected")
	# Pet gear occupies its own six slots; character equipment stays unchanged.
	state.pet_equipped.clear()
	check(state.add_item("pet_necklace_silver"), "pet necklace can be added to bag")
	var pet_damage_before: int = state.attack_power()
	var pet_index: int = state.inventory.size() - 1
	check("Used" in state.use_item(pet_index), "necklace can be equipped from inventory")
	check(state.pet_equipped.has("pet_necklace") and not state.equipped.has("pet_necklace"), "pet necklace uses distinct pet-only equipment")
	check(int(state.pet_bonus().power) == 6 and state.attack_power() == pet_damage_before, "pet power bonus never changes player attack")
	check(state.unequip_pet_item("pet_necklace"), "pet necklace can be unequipped")
	check(state.pet_equipped.is_empty(), "pet equipment slots return to empty")
	check(state.add_item("pet_wings_wind"), "pet loot wings available from item catalog")
	check(state.equip_pet_item(state.inventory.size() - 1), "pet wings equip")
	check(is_equal_approx(float(state.pet_bonus().loot_radius), 1.0), "pet wings add only pet loot range")
	state.equipped["loot_pet"] = {"id":"loot_companion","count":1,"enhancement":0}
	check(state.pet_pickup_radius() > 4.0, "worn pet receives equipped pickup-range benefit")
	state.equipped.erase("loot_pet")
	check(is_equal_approx(state.pet_pickup_radius(), 4.0), "pet bonuses do not apply without pet")
	state.pet_equipped.clear()
	state.inventory.clear()
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
	state.skill_points = 3
	state.gold = 1000
	var skill_gold_before: int = state.gold
	check(state.upgrade_skill(2), "skill upgrade spends gold and points")
	check(state.skill_points == 2 and state.gold < skill_gold_before and state.skill_level(2) == 2, "skill upgrade persists correct resources and level")
	check(state.skill_definition(1).power > 1.8, "loadout skill upgrades increase combat power")
	check(not state.upgrade_skill(-1), "invalid skill index rejected")
	check(not state.select_job("wind_assassin"), "profession locked before Class 5")
	state.class_rank = 5
	check(not state.select_job("water_mage"), "profession must match element")
	check(state.select_job("wind_assassin"), "Class 5 profession")
	check(state.skill_catalog().size() == 14, "profession has 14 skill definitions")
	check(state.set_skill_slot(0, 4), "class 5 can equip a profession active skill")
	check(state.skill_definition(1).get("role") == "aoe", "profession hotbar loads chosen skill")
	check(not state.set_skill_slot(0, 10), "passive skill cannot occupy active hotbar")
	state.job_skill_loadout = [0, 1, 2]
	var passive_attack_before: int = state.attack_power()
	check(state.upgrade_skill(10), "profession passive can be upgraded")
	check(state.attack_power() > passive_attack_before, "passive upgrade affects attack")
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
	check(game.hud_status_panel != null and game.hud_quest_panel != null and game.hud_target_panel != null, "polished status quest target HUD frames exist")
	check(game.hud_target_hp != null and game.hud_currency_label != null, "target HP and currency HUD are present")
	var asset_registry = load("res://scripts/content_registry.gd")
	check(int(asset_registry.manifest().get("version",0)) == 1, "asset manifest exists and has a stable format")
	check(asset_registry.character_scene("Male") == null and asset_registry.zone_scene(0) == null, "missing professional assets correctly use procedural fallbacks")
	check(asset_registry.character_scene("Female") != null, "female artist model is connected in the content manifest")
	var old_gender: String = state.gender
	state.gender = "Female"
	game._build_avatar()
	var female_visual: Node3D = game.imported_avatar_visual
	check(is_instance_valid(female_visual), "female avatar attaches a real GLB visual")
	if is_instance_valid(female_visual):
		check(bool(female_visual.get("visual_loaded")) and int(female_visual.get("rendered_mesh_count")) > 0, "female GLB imports usable MeshInstance3D geometry")
		check(absf(float(female_visual.get("rendered_height_m")) - 1.72) < 0.03, "female GLB is normalized to playable body height")
		check(female_visual.get_node_or_null("ModelFit") != null, "female art uses an independent fit transform without changing physics")
		var hidden_helper: Node = female_visual.find_child("Cube", true, false)
		check(hidden_helper is MeshInstance3D and not hidden_helper.visible, "female exported Cube helper must be hidden to reveal humanoid mesh")
		check(int(female_visual.get("rendered_mesh_count")) == 1, "female only fits the authored humanoid mesh, not its helper cube")
		var asset_walk: Array[Node] = [female_visual]
		var mesh_report: Array[String] = []
		var inspected_nodes := 0
		while not asset_walk.is_empty() and inspected_nodes < 250:
			var item: Node = asset_walk.pop_back()
			inspected_nodes += 1
			if item is MeshInstance3D:
				var mesh_instance: MeshInstance3D = item as MeshInstance3D
				if mesh_instance.mesh != null:
					var mesh_box: AABB = mesh_instance.get_aabb()
					mesh_report.append("%s aabb=%s surfaces=%d" % [str(item.get_path()), str(mesh_box), mesh_instance.mesh.get_surface_count()])
			for child in item.get_children():
				asset_walk.append(child)
		print("FEMALE_GLTF_MESH_REPORT=" + JSON.stringify(mesh_report.slice(0, 60)))
	state.gender = old_gender
	game._build_avatar()
	check(game.imported_avatar_visual == null, "male placeholder remains intact until male art is available")
	var original_hunt_settings: Dictionary = state.settings.duplicate(true)
	game._select_hunt_skill(1,false)
	game._select_hunt_radius(36.0)
	check(not game.hunt_skills[1] and is_equal_approx(game.hunt_radius,36.0), "auto-hunt skills and radius update")
	check(state.settings.get("auto_hunt_skills",[]).size() == 3 and float(state.settings.get("auto_hunt_radius",0)) == 36.0, "auto-hunt preferences persisted into existing settings")
	game.hunt_skills[1] = true
	game.hunt_radius = 12.0
	game._load_hunt_preferences()
	check(not game.hunt_skills[1] and is_equal_approx(game.hunt_radius,36.0), "auto-hunt preferences load from saved settings")
	state.settings = original_hunt_settings
	game._load_hunt_preferences()
	check(game.buttons.size() == 2, "nine menu shortcuts replaced by one player control and one owner-only control")
	check(game.owner_gm_button.visible and not game.gm_authorized, "offline visitor sees red local GM control without online owner role")
	game._show_panel("GM")
	check(game.panel.visible and game.active_panel == "GM", "offline GM is accessible for local testing")
	game._close_panel()
	# The new silver workspace supersedes the old gold two-pane Bag layout.
	game._show_panel("Bag")
	await process_frame
	var workspace: Control = game.silver_workspace
	check(workspace != null and workspace.visible, "Bag opens the new silver workspace")
	check(not game.panel.visible and not game.bag_dock_panel.visible, "legacy bag panels stay hidden when new inventory is open")
	check(workspace.main_frame != null and workspace.main_frame.visible, "main silver base appears")
	check(not workspace.extension_frame.visible and workspace.extension_mode == "", "extension base is hidden by default")
	check(workspace.menu_buttons.size() == 14, "all 14 player menu entries are inside the left sidebar")
	check(not workspace.menu_buttons.has("GM"), "GM button stays outside player sidebar")
	check(workspace.equipment_buttons.size() == 14, "seven warrior slots to left and seven fashion slots to right")
	check(workspace.accessory_buttons.size() == 5, "five separate jewelry slots: ring bracelet necklace bracelet ring")
	check(is_instance_valid(workspace.avatar_viewport) and is_instance_valid(workspace.avatar_stage), "live character portrait is embedded between gear columns")
	check(workspace.avatar_stage.get_child_count() == 1, "live character portrait has one current character model")
	check(workspace.menu_buttons.has("Shop") and workspace.menu_buttons.has("Cash") and workspace.menu_buttons.has("Connect"), "all existing player systems remain reachable")
	check(workspace.find_child("SilverNavQuest", true, false) != null, "Quest menu retains its own icon and name")
	check(workspace.item_grid.columns == 6, "inventory grid has six columns")
	check(workspace.item_grid.get_child_count() == 100, "page one contains 100 reusable inventory slots")
	check(workspace.item_grid.find_child("InventorySlot0", true, false) != null, "first inventory slot is present")
	check(workspace.item_grid.find_child("InventorySlot99", true, false) != null, "last inventory slot of page one is present")
	workspace._page_change(1)
	await process_frame
	check(workspace.page == 1 and workspace.item_grid.get_child_count() == 100, "page two contains exactly 100 slots")
	check(workspace.item_grid.find_child("InventorySlot100", true, false) != null, "second page begins at slot 100")
	check(workspace.item_grid.find_child("InventorySlot199", true, false) != null, "second page ends at slot 199")
	workspace._page_change(-1)
	workspace._set_extension("Storage")
	check(workspace.extension_frame.visible and workspace.extension_mode == "Storage", "storage extension appears when opened")
	workspace._set_extension("Trade")
	check(workspace.extension_frame.visible and workspace.extension_mode == "Trade", "trade extension reuses the same frame")
	workspace._set_extension("Quest")
	check(workspace.extension_frame.visible and workspace.extension_mode == "Quest", "quest extension reuses the same frame")
	for menu_mode in ["Shop", "Cash", "World", "Pet", "Auto", "Skills", "Settings", "Connect", "Guild"]:
		workspace._set_extension(menu_mode)
		check(workspace.extension_frame.visible and workspace.extension_mode == menu_mode and workspace.extension_content.get_child_count() >= 2, "sidebar opens " + menu_mode)
	workspace._set_extension("")
	check(not workspace.extension_frame.visible, "extension frame collapses completely")
	workspace._toggle_bulk()
	check(workspace.bulk_mode, "multi-selection mode can be enabled")
	workspace._toggle_bulk()
	check(not workspace.bulk_mode and workspace.bulk_selection.is_empty(), "multi-selection mode can be canceled")
	check(workspace.equipment_buttons.size() == 14, "warrior and fashion slots remain present after other menu actions")
	await process_frame
	var portrait_rect: Rect2 = workspace.avatar_preview_frame.get_global_rect()
	var warrior_rect: Rect2 = workspace.equipment_buttons["hat"].get_global_rect()
	var fashion_rect: Rect2 = workspace.equipment_buttons["fashion_hat"].get_global_rect()
	check(warrior_rect.end.x <= portrait_rect.position.x + 1.0, "warrior equipment is left of the live character portrait")
	check(fashion_rect.position.x >= portrait_rect.end.x - 1.0, "fashion equipment is right of the live character portrait")
	var jewelry_order := ["ring", "bracelet_left", "accessory", "bracelet_right", "ring_right"]
	var previous_jewelry_x := -1000.0
	for jewelry_id in jewelry_order:
		var jewelry_rect: Rect2 = workspace.accessory_buttons[jewelry_id].get_global_rect()
		check(jewelry_rect.position.x > previous_jewelry_x, "jewelry order " + jewelry_id)
		previous_jewelry_x = jewelry_rect.position.x
	check(workspace.accessory_buttons["accessory"].get_global_rect().position.y > portrait_rect.position.y, "jewelry row lies beneath portrait top")
	check(workspace.stats_label.text.contains("PvE"), "PvE text is displayed separately")
	workspace.close_workspace()
	check(not workspace.visible and game.active_panel == "", "closing inventory returns to the world")
	game._show_panel("Bag")
	check(workspace.visible, "Bag can be reopened after closing")
	game._close_panel()
	check(not workspace.visible, "Escape closes the silver workspace")
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
			check(game.owner_gm_button.visible, "red GM button remains visible in offline sandbox")
		game._show_panel(name)
		check(game.silver_workspace.visible if name == "Bag" else game.panel.visible, "open " + name)
	game._close_panel()
	game._set_gm_authorized(false)
	check(game.owner_gm_button.visible and not game.gm_authorized, "offline sandbox keeps GM test button after role reset")
	game.network.active = true
	game._set_gm_authorized(false)
	check(not game.owner_gm_button.visible, "unverified online users cannot see GM")
	game.network.active = false
	game._set_gm_authorized(false)
	check(game.owner_gm_button.visible, "restoring offline mode restores the local GM button")
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
	state.pet_equipped = {"pet_ring":{"id":"pet_ring_moon","count":1,"enhancement":0}}
	check(state.save_game(), "save write")
	state.gold = 0
	state.pet_equipped.clear()
	check(state.load_game() and state.gold == 123, "save load round trip")
	check(state.pet_equipped.has("pet_ring"), "pet equipment persists through versioned offline save")
	state.pet_equipped.clear()
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
