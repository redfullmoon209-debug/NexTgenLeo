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
	game._toggle_player_dropdown()
	print("TRACE_MENU after_open view=",scene.get_viewport().get_visible_rect().size," state=",game.active_panel," drop=",game.player_dropdown.visible," backdrop=",game.dropdown_backdrop.visible," panel=",game.panel.visible," dock=",game.bag_dock_panel.visible)
	check(game.player_dropdown.visible and game.dropdown_backdrop.visible and game.active_panel == "Bag", "yellow hamburger opens pinned sidebar and bag workspace")
	check(game.dropdown_entries.size() == 10, "all ten player menus remain in sidebar")
	check(game.player_dropdown.size.x >= 255.0, "Royal left sidebar is wide enough to show full Thai menu labels")
	check(game.dropdown_entries["Status"].text.contains("ตัวละครและอุปกรณ์"), "Complete character and equipment title is present")
	check(game.dropdown_entries["Status"].size.x >= 225.0, "Long character title button does not use the old clipped 154px width")
	check(game.player_dropdown.get_node_or_null("SapphireGoldFrame") != null, "Sidebar has high-DPI gold trim")
	game._open_player_menu("Shop")
	print("TRACE_MENU after_shop state=",game.active_panel," drop=",game.player_dropdown.visible," dock=",game.bag_dock_panel.visible," viewport=",scene.get_viewport().get_visible_rect().size)
	check(game.player_dropdown.visible and game.active_panel == "Shop" and game.bag_dock_panel.visible, "shop opens to right of persistent bag")
	game._open_player_menu("Quest")
	check(game.player_dropdown.visible and game.active_panel == "Quest" and game.bag_dock_panel.visible, "quest replaces shop but keeps character bag")
	game._toggle_player_dropdown()
	check(not game.player_dropdown.visible and not game.dropdown_backdrop.visible and not game.panel.visible, "hamburger closes workspace completely")
	game._toggle_player_dropdown()
	check(game.active_panel == "Bag" and game.player_dropdown.visible, "hamburger reopens bag and navigation")
	game._close_panel()
	game._show_panel("Bag")
	await process_frame
	check(game.panel.position.x >= 275 and game.panel.position.x <= 305 and game.panel.position.y <= 16, "character bag appears to the right of expanded full-text sidebar")
	print("ROYAL_LAYOUT_TRACE panel=",game.panel.get_global_rect()," sidebar=",game.player_dropdown.get_global_rect()," char=",game.bag_character_panel.get_global_rect()," inv=",game.bag_inventory_panel.get_global_rect()," grid=",game.bag_slot_grid.get_global_rect()," slots=",game.bag_page_size)
	check(game.panel.size.x >= 535 and game.panel.size.x <= 570, "compact character bag preserves equipment without hiding the entire world")
	var viewport_height: float = scene.get_viewport().get_visible_rect().size.y
	var viewport_width: float = scene.get_viewport().get_visible_rect().size.x
	check(game.panel.size.y >= viewport_height - 30.0, "character bag stretches almost to the bottom")
	check(game.panel.position.y + game.panel.size.y <= viewport_height - 8.0, "bag fits within viewport bottom")
	check(game.panel.position.x + game.panel.size.x < viewport_width - 200, "game scene remains visible to right of workspace")
	check(game.panel.z_index >= 50 and game.panel.get_index() == game.panel.get_parent().get_child_count() - 1, "bag stays above other HUD elements")
	check(game.bag_character_panel != null and game.bag_inventory_panel != null, "character and bag panes created")
	check(game.bag_character_panel.get_node_or_null("SapphireGoldFrame") != null, "Character and equipment window has premium vector trim")
	check(game.bag_inventory_panel.get_node_or_null("SapphireGoldFrame") != null, "Inventory window has premium vector trim")
	check(game.bag_character_panel.find_child("PetEquipmentSection", true, false) != null, "character pane includes dedicated pet equipment section")
	check(game.bag_character_panel.find_child("UnassignedPetSilhouette", true, false) != null, "empty pet previews a silhouette instead of the test animal")
	check(state.add_item("loot_companion"), "pet to preview can be obtained")
	check("Used" in state.use_item(state.inventory.size() - 1), "loot pet can be worn")
	game._close_panel()
	game._show_panel("Bag")
	await process_frame
	check(game.bag_character_panel.find_child("EquippedPet3DPreview", true, false) != null, "worn pet renders the live in-game mesh in bag preview")
	check(game.bag_equipment_buttons.size() == 19 and game.pet_gear_buttons.size() == 6, "worn pet leaves all original equipment slots intact")
	check(state.unequip("loot_pet"), "loot pet can be removed")
	game._close_panel()
	game._show_panel("Bag")
	await process_frame
	check(game.bag_slot_grid != null and game.bag_slot_grid.columns >= 3 and game.bag_slot_grid.columns <= 6, "responsive bag grid has 3 to 6 columns")
	check(game.bag_page_size > 0 and game.bag_page_size < 100 and game.bag_page_count >= 3, "200 slots are divided among responsive numbered pages")
	check(game.bag_slot_grid.get_child_count() == game.bag_page_size, "bag renders only slots belonging to the visible page")
	check(game.bag_inventory_panel.find_child("BagSlotsScroll",true,false) == null, "bag item grid no longer has vertical scrolling")
	check(game.bag_inventory_panel.find_child("InventoryPagination",true,false) != null, "numbered pages and previous/next buttons exist")
	game._set_bag_page(1)
	await process_frame
	check(game.bag_page == 1 and game.bag_slot_grid.find_child("InventorySlot%d" % game.bag_page_size, true, false) != null, "second page starts at the next correct inventory slot")
	check(game.bag_equipment_buttons.size() == 19, "page switches preserve all 19 equipment slots")
	check(game.pet_gear_buttons.size() == 6, "pet card adds six slots without replacing any of the 19 character slots")
	game._set_bag_page(0)
	await process_frame
	check(game.bag_inventory_panel.find_child("BulkSellActions", true, false) != null, "inventory has multi-selection action row")
	game._toggle_bulk_mode()
	check(game.bag_bulk_mode, "multi-select selling mode can be enabled")
	game._toggle_bulk_mode()
	check(not game.bag_bulk_mode and game.bag_bulk_selection.is_empty(), "bulk selling mode can be canceled")
	check(game.bag_equipment_frame != null and game.bag_equipment_buttons.size() == 19, "all 19 named equipment slots are created")
	check(game.pet_gear_buttons.size() == 6, "six pet-only accessories are in distinct named slots")
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
	# Bulk-mode toggle recreates the container tree; let Godot compute the
	# new layout before reading global rects (not stale frame-zero geometry).
	await process_frame
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
			check(game.owner_gm_button.visible, "red GM button remains visible in offline sandbox")
		game._show_panel(name)
		check(game.panel.visible, "open " + name)
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
