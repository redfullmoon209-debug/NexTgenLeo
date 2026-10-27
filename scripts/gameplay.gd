extends Node
## Playable offline systems; procedural art is explicitly temporary.
const ContentRegistry = preload("res://scripts/content_registry.gd")
var last_touch_action := -1000
var world: Node3D
var network: Node
var mobs: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var target := -1
var auto_attack := false
var auto_hunt := false
var pending_skill := 0
var cooldowns := [0.0, 0.0, 0.0, 0.0]
var hunt_skills := [true, true, true]
var hunt_radius := 18.0
var npc: Node3D
var pet: Node3D
var avatar: Node3D
var imported_avatar_visual: Node3D
var imported_zone_visual: Node3D
var limbs: Array[Node3D] = []
var weapon: Node3D
var stats_label: Label
var quest_label: Label
var target_label: Label
var notice: Label
var hud_status_panel: PanelContainer
var hud_quest_panel: PanelContainer
var hud_target_panel: PanelContainer
var hud_target_hp: ProgressBar
var hud_notice_panel: PanelContainer
var notice_hide_timer := 0.0
var hud_currency_label: Label
var hud_portrait_label: Label
var hud_state_label: Label
var hud_action_style_key := ""
var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var exp_bar: ProgressBar
var map_display: Control
var panel: PanelContainer
var menu: VBoxContainer
var buttons: Array[Button] = []
var skill_buttons: Array[Button] = []
var menu_toggle_button: Button
var owner_gm_button: Button
var player_dropdown: PanelContainer
var player_dropdown_column: VBoxContainer
var dropdown_backdrop: ColorRect
var dropdown_entries: Dictionary = {}
var gm_authorized := false
var active_panel := ""
var bag_page := 0
var bag_bulk_mode := false
var bag_bulk_selection: Dictionary = {}
var bag_character_panel: PanelContainer
var bag_inventory_panel: PanelContainer
var bag_equipment_buttons: Array[Button] = []
var bag_equipment_frame: HBoxContainer
var bag_slot_regions: Dictionary = {}
var bag_character_preview: SubViewportContainer
var bag_preview_stage: Node3D
var bag_preview_model: Node3D
var bag_slot_grid: GridContainer
var bag_status_label: Label
var bag_status_bars: Array[ProgressBar] = []
var selected_item := -1
var quantity: SpinBox
var save_timer := 0.0
var regen_timer := 0.0
var animation_time := 0.0
var swing := 0.0
var dead_timer := 0.0
var npc_navigation := false
var layout_edit := false
var dragging_button: Button
var ui_refresh := 0.0
var gm_choosers: Dictionary = {}
var gm_summary: Label
var selected_ring: MeshInstance3D
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	network = load("res://scripts/network_client.gd").new()
	network.game = self
	add_child(network)
	rng.seed = 74129
	_build_ui()
	_build_avatar()
	_build_zone()
	_load_hunt_preferences()
	GameState.appearance_changed.connect(_build_avatar)
	GameState.progression_changed.connect(_build_avatar)
	var saved: Array = GameState.location
	if saved.size() == 3:
		world.player.position = Vector3(float(saved[0]), maxf(1, float(saved[1])), float(saved[2]))
	_tell("เริ่มผจญภัย! เปิดเควสต์เพื่อคุยกับ Elara")

func _mesh(parent: Node3D, pos: Vector3, size: Vector3, color: Color, shape := "box") -> MeshInstance3D:
	var node := MeshInstance3D.new()
	if shape == "sphere":
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1
		mesh.radial_segments = 12
		mesh.rings = 6
		node.mesh = mesh
	elif shape == "cone":
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0
		mesh.bottom_radius = 0.5
		mesh.height = 1
		mesh.radial_segments = 8
		node.mesh = mesh
	else:
		var mesh := BoxMesh.new()
		node.mesh = mesh
	node.position = pos
	node.scale = size
	node.material_override = world._material(color)
	parent.add_child(node)
	return node

func _tag(parent: Node3D, text: String, y: float, color := Color.WHITE) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position.y = y
	label.font_size = 24
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	parent.add_child(label)
	return label

func _build_avatar() -> void:
	if is_instance_valid(avatar):
		avatar.queue_free()
	# Remove original capsule rendering, retain movement collider.
	for child in world.player.get_children():
		if child is MeshInstance3D:
			child.visible = false
	avatar = Node3D.new()
	world.player.add_child(avatar)
	var height := GameState.height_meters()
	avatar.scale = Vector3.ONE * height / 1.75
	avatar.position.y = -0.85
	var skin := Color("d9ac83")
	var cloth := Color("305e96") if GameState.gender == "Male" else Color("8567a2")
	if "fashion_shirt" in GameState.equipped:
		cloth = Color("557fbb")
	elif "shirt" in GameState.equipped:
		cloth = Color("258caf")
	_mesh(avatar, Vector3(0, 1.15, 0), Vector3(0.52, 0.58, 0.28), cloth)
	# Permanent abdomen: cropped shirts must not remove the underlying body.
	_mesh(avatar, Vector3(0, 0.82, 0), Vector3(0.38, 0.20, 0.25), skin)
	_mesh(avatar, Vector3(0, 1.64, 0), Vector3(0.38, 0.40, 0.36), skin, "sphere")
	_mesh(avatar, Vector3(0, 1.72, 0.03), Vector3(0.40, 0.23, 0.36), Color("b9c7d2") if "hair" in GameState.equipped else Color("342b32"), "sphere")
	for x in [-0.09, 0.09]:
		_mesh(avatar, Vector3(x, 1.65, -0.175), Vector3(0.045, 0.055, 0.03), Color("1a2635"))
	limbs.clear()
	for x in [-0.19, 0.19]:
		var leg := Node3D.new()
		leg.position = Vector3(x, 0.77, 0)
		avatar.add_child(leg)
		_mesh(leg, Vector3(0, -0.31, 0), Vector3(0.21, 0.60, 0.23), Color("4777a5") if "fashion_pants" in GameState.equipped else (Color("3c4657") if "pants" not in GameState.equipped else Color("335a70")))
		_mesh(leg, Vector3(0, -0.66, -0.06), Vector3(0.23, 0.17, 0.34), Color("9caec7") if "fashion_shoes" in GameState.equipped else (Color("3c2f2b") if "shoes" not in GameState.equipped else Color("91724c")))
		limbs.append(leg)
	for x in [-0.36, 0.36]:
		var arm := Node3D.new()
		arm.position = Vector3(x, 1.35, 0)
		avatar.add_child(arm)
		_mesh(arm, Vector3(0, -0.23, 0), Vector3(0.17, 0.49, 0.2), cloth)
		_mesh(arm, Vector3(0, -0.52, 0), Vector3(0.17, 0.18, 0.18), Color("709acb") if "fashion_gloves" in GameState.equipped else (skin if "gloves" not in GameState.equipped else Color("855b38")))
		limbs.append(arm)
	weapon = Node3D.new()
	limbs[3].add_child(weapon)
	var id: String = GameState.equipped.get("weapon", {}).get("id", "sword")
	var weapon_color := Color("c74f55") if id in ["sword","dual_sword","greatsword"] else Color("e4bb5b")
	if id in ["fist", "knuckle"]:
		for arm in [limbs[2],limbs[3]]:
			_mesh(arm, Vector3(0,-0.51,-0.06), Vector3(0.25,0.23,0.27), weapon_color if id == "knuckle" else skin, "sphere")
	elif id == "fan":
		for i in range(7):
			var blade := _mesh(weapon,Vector3(0,-0.44,-0.35),Vector3(0.08,0.03,0.65),Color("9cd6b7"))
			blade.rotation.y = (i-3)*0.23
	elif id in ["staff","wood_staff","spear","vine"]:
		_mesh(weapon,Vector3(0,-0.2,-0.3),Vector3(0.07,1.6,0.07),Color("977447"))
		_mesh(weapon,Vector3(0,0.65,-0.3),Vector3(0.30,0.4,0.30),Color("73b8d4") if id == "staff" else Color("74b875"),"cone")
	else:
		var firearm: bool = id in ["gun","pistol","dual_pistol"]
		var length := 0.43 if id in ["kunai","pistol","dual_pistol"] else 0.95
		_mesh(weapon, Vector3(0,-0.44,-length*0.55), Vector3(0.14 if firearm else 0.12,0.12 if firearm else 0.05,length), Color("526679") if firearm else weapon_color)
		_mesh(weapon, Vector3(0,-0.44,-0.15),Vector3(0.1 if firearm else 0.36,0.25 if firearm else 0.1,0.08),Color("e1bb68"))
		if id in ["dual_pistol","dual_sword"]:
			_mesh(limbs[2],Vector3(0,-0.44,-0.35),Vector3(0.12,0.08,length),weapon_color)
	if "hat" in GameState.equipped or "fashion_hat" in GameState.equipped:
		_mesh(avatar, Vector3(0, 1.88, -0.07), Vector3(0.48, 0.23, 0.28), Color("b2c8e4") if "fashion_hat" in GameState.equipped else Color("c1a258"), "cone")
	if "weapon_left" in GameState.equipped:
		var left_hand := str(GameState.equipped["weapon_left"].get("id", "offhand_blade"))
		_mesh(limbs[2], Vector3(0, -0.43, -0.31), Vector3(0.10, 0.06, 0.60), Color("a1c6e6") if left_hand == "offhand_blade" else Color("d9bc85"))
	if "accessory" in GameState.equipped:
		_mesh(avatar, Vector3(0, 1.28, -0.16), Vector3.ONE * 0.09, Color("f4d36c"), "sphere")
	_attach_optional_avatar_scene()
	_sync_bag_avatar_preview()

func _attach_optional_avatar_scene() -> void:
	imported_avatar_visual = null
	var scene: PackedScene = ContentRegistry.character_scene(GameState.gender)
	if scene == null:
		return
	var instance: Node = scene.instantiate()
	if not (instance is Node3D):
		instance.queue_free()
		_tell("ไฟล์โมเดลตัวละครต้องมี Node3D เป็นโหนดหลัก")
		return
	imported_avatar_visual = instance as Node3D
	imported_avatar_visual.name = "ImportedCharacterVisual"
	avatar.add_child(imported_avatar_visual)
	# Keep procedural artwork visible when the referenced art fails to import.
	# Older content scenes without the adapter's visual_loaded field still work.
	var loaded: Variant = imported_avatar_visual.get("visual_loaded")
	if loaded is bool and not loaded:
		imported_avatar_visual.queue_free()
		imported_avatar_visual = null
		return
	# Preserve capsule collision, height growth, equipment and combat logic.
	# Existing procedural mesh remains a non-rendered fallback, not deleted.
	for child in avatar.get_children():
		if child is Node3D and child != imported_avatar_visual:
			(child as Node3D).visible = false

func _sync_bag_avatar_preview() -> void:
	# Clone the live player's visible mesh, not an unrelated placeholder portrait.
	# Equipment and gender changes rebuild the same avatar, so the preview matches.
	if not is_instance_valid(bag_preview_stage) or not is_instance_valid(avatar):
		return
	if is_instance_valid(bag_preview_model):
		if bag_preview_model.get_parent() != null:
			bag_preview_model.get_parent().remove_child(bag_preview_model)
		bag_preview_model.queue_free()
	bag_preview_model = avatar.duplicate() as Node3D
	bag_preview_model.name = "DisplayedPlayerAvatar"
	bag_preview_model.position = Vector3.ZERO
	bag_preview_model.rotation = Vector3.ZERO
	bag_preview_model.scale = Vector3.ONE * 0.94
	bag_preview_stage.add_child(bag_preview_model)

func _build_bag_avatar_preview(parent: HBoxContainer) -> void:
	# SubViewport renders the actual procedural player and its equipped items.
	# It only exists while the inventory panel is open; the world remains visible.
	var preview_frame := PanelContainer.new()
	preview_frame.name = "PlayerModelFrame"
	preview_frame.custom_minimum_size = Vector2(98, 205)
	preview_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_frame.add_theme_stylebox_override("panel", _silver_panel_style(7, Color("0c1d35eb")))
	preview_frame.set_meta("leo_fantasy_skin", true)
	parent.add_child(preview_frame)
	bag_character_preview = SubViewportContainer.new()
	bag_character_preview.name = "Player3DPreview"
	bag_character_preview.custom_minimum_size = Vector2(94, 200)
	bag_character_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_character_preview.stretch = true
	bag_character_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_frame.add_child(bag_character_preview)
	var view := SubViewport.new()
	view.name = "CharacterPreviewViewport"
	view.size = Vector2i(150, 300)
	view.own_world_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	bag_character_preview.add_child(view)
	bag_preview_stage = Node3D.new()
	bag_preview_stage.name = "PreviewStage"
	view.add_child(bag_preview_stage)
	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-35, -30, 0)
	fill_light.light_energy = 2.0
	bag_preview_stage.add_child(fill_light)
	var camera := Camera3D.new()
	camera.name = "PortraitCamera"
	camera.position = Vector3(0, 1.02, -2.95)
	camera.fov = 39.0
	bag_preview_stage.add_child(camera)
	camera.look_at(Vector3(0, 0.92, 0), Vector3.UP)
	camera.current = true
	_sync_bag_avatar_preview()

func _build_zone() -> void:
	for mob in mobs:
		mob.node.queue_free()
	mobs.clear()
	for drop in drops:
		drop.node.queue_free()
	drops.clear()
	if is_instance_valid(npc):
		npc.queue_free()
	if is_instance_valid(pet):
		pet.queue_free()
	npc = Node3D.new()
	world.add_child(npc)
	npc.position = Vector3(-5, 0, -4)
	_mesh(npc, Vector3(0, 0.85, 0), Vector3(0.7, 1.7, 0.6), Color("e6c788"), "cone")
	_mesh(npc, Vector3(0, 1.8, 0), Vector3.ONE * 0.45, Color("eac29d"), "sphere")
	_tag(npc, "!  Warden Elara\nQUEST / SHOP / ADVANCE", 2.5, Color("ffe1a0"))
	pet = Node3D.new()
	world.add_child(pet)
	_mesh(pet, Vector3(0, 0.4, 0), Vector3(0.65, 0.55, 0.85), Color("f2e1b9"), "sphere")
	_mesh(pet, Vector3(0, 0.73, -0.32), Vector3.ONE * 0.43, Color("f2e1b9"), "sphere")
	for x in [-0.18, 0.18]:
		_mesh(pet, Vector3(x, 1.0, -0.32), Vector3(0.16, 0.35, 0.16), Color("daba91"), "cone")
	_tag(pet, "Loot companion", 1.35, Color("b5e8fc"))
	pet.position = world.player.position + Vector3(2, -1, 1)
	for i in range(14):
		_spawn_mob(i, "Normal" if i < 11 else ("Elite" if i == 11 else ("Boss" if i == 12 else "World Boss")))
	# Safe camp props and portal. All generated here; no third-party art.
	if not world.has_node("Camp"):
		var camp := Node3D.new()
		camp.name = "Camp"
		world.add_child(camp)
		_mesh(camp, Vector3(-4, 0.01, -2), Vector3(12, 0.05, 10), Color("9eaa7c"))
		_tag(camp, "SANCTUARY · SAFE ZONE", 3.7, Color("adebd5"))
		for i in range(3):
			_mesh(camp, Vector3(-10 + i * 4, 1.1, -8), Vector3(3, 2.2, 2.5), Color("b5a380"))
			_mesh(camp, Vector3(-10 + i * 4, 2.8, -8), Vector3(4, 1.5, 3.5), Color("4e686c"), "cone")
		_mesh(camp, Vector3(8, 1.5, -6), Vector3(2, 3, 0.3), Color("669ed4"))
		var portal_label := _tag(camp, "PORTAL\nOpen World Map", 4, Color("a8ceff"))
		portal_label.position.x = 8
		portal_label.position.z = -6
		world._add_box(Vector3(0, 0.005, -15), Vector3(4, 0.03, 30), Color("9c966d"), false)
	_attach_optional_zone_scene()
	target = -1

func _attach_optional_zone_scene() -> void:
	if is_instance_valid(imported_zone_visual):
		imported_zone_visual.queue_free()
	imported_zone_visual = null
	var scene: PackedScene = ContentRegistry.zone_scene(GameState.map_index)
	if scene == null:
		if world.has_node("Camp"):
			world.get_node("Camp").visible = true
		return
	var instance: Node = scene.instantiate()
	if not (instance is Node3D):
		instance.queue_free()
		_tell("ไฟล์แผนที่ต้องมี Node3D เป็นโหนดหลัก")
		return
	imported_zone_visual = instance as Node3D
	imported_zone_visual.name = "ImportedZoneScenery"
	world.add_child(imported_zone_visual)
	# Hide generic placeholder camp when an authored map is supplied.
	# Monster/quest spawn and movement remain owned by the gameplay systems.
	if world.has_node("Camp"):
		world.get_node("Camp").visible = false

func _spawn_mob(index: int, kind: String) -> void:
	var node := Node3D.new()
	world.add_child(node)
	var angle := float(index) * 2.4
	node.position = Vector3(cos(angle) * (10 + index % 4 * 4), 0, sin(angle) * (10 + index % 4 * 4))
	var scale_value := 1.0 if kind == "Normal" else (1.4 if kind == "Elite" else 2.0)
	var color := Color("a3b56f") if kind == "Normal" else (Color("dca552") if kind == "Elite" else Color("a76179"))
	_mesh(node, Vector3(0, 0.6 * scale_value, 0), Vector3(1.1, 1.1, 1.1) * scale_value, color, "sphere")
	for x in [-0.22, 0.22]:
		_mesh(node, Vector3(x * scale_value, 0.85 * scale_value, -0.48 * scale_value), Vector3.ONE * 0.13, Color("233144"), "sphere")
	var mob_level := int(GameState.balance.maps[GameState.map_index].level) + index % 3
	var maximum := (60 + mob_level * 12) * (1 if kind == "Normal" else (3 if kind == "Elite" else 8))
	var label := _tag(node, "%s Lv.%d" % [kind + " Mossling", mob_level], 1.7 * scale_value)
	mobs.append({"node":node,"home":node.position,"hp":maximum,"max_hp":maximum,"level":mob_level,"kind":kind,"respawn":0.0,"attack_timer":0.0,"label":label})

func _style(bg: Color, border: Color, radius := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _label(text: String, size := 16) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, callback: Callable, parent: Node = null) -> Button:
	var button := Button.new()
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.text = text
	button.custom_minimum_size = Vector2(74, 40)
	button.add_theme_stylebox_override("normal", _style(Color("182b40e8"), Color("697d8f")))
	button.add_theme_stylebox_override("hover", _style(Color("33506b"), Color("ddc58d")))
	button.add_theme_stylebox_override("pressed", _style(Color("44617d"), Color("f1d89d")))
	button.pressed.connect(callback)
	(parent if parent != null else world.hud).add_child(button)
	return button

func _menu_orb_style(background: Color, rim: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = rim
	style.set_border_width_all(2)
	style.border_width_top = 3
	style.set_corner_radius_all(40)
	style.shadow_color = Color("020713c2")
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style

func _build_player_dropdown() -> void:
	dropdown_backdrop = ColorRect.new()
	dropdown_backdrop.name = "DropdownDismissLayer"
	dropdown_backdrop.color = Color.TRANSPARENT
	dropdown_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	dropdown_backdrop.z_index = 80
	dropdown_backdrop.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			_close_player_dropdown()
		elif event is InputEventScreenTouch and event.pressed:
			_close_player_dropdown()
	)
	world.hud.add_child(dropdown_backdrop)
	dropdown_backdrop.hide()
	player_dropdown = PanelContainer.new()
	player_dropdown.name = "PlayerMainDropdown"
	player_dropdown.z_index = 91
	player_dropdown.mouse_filter = Control.MOUSE_FILTER_STOP
	player_dropdown.set_meta("leo_fantasy_skin", true)
	player_dropdown.add_theme_stylebox_override("panel", _silver_panel_style(11, Color("0d213ceF")))
	world.hud.add_child(player_dropdown)
	var scroll := ScrollContainer.new()
	scroll.name = "DropdownScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_dropdown.add_child(scroll)
	player_dropdown_column = VBoxContainer.new()
	player_dropdown_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_dropdown_column.add_theme_constant_override("separation", 3)
	scroll.add_child(player_dropdown_column)
	var title := _label("เมนูหลัก", 17)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_dropdown_column.add_child(title)
	var specs := [
		["Bag", "▣", "[B]"],
		["Shop", "▤", "[P]"],
		["Status", "♙", "[C]"],
		["Quest", "✦", "[Q]"],
		["World", "◉", "[M]"],
		["Pet", "♧", ""],
		["Auto", "↻", ""],
		["Skills", "⚔", ""],
		["Settings", "⚙", ""],
		["Connect", "◇", ""]
	]
	for spec in specs:
		var menu_id: String = str(spec[0])
		var title_text: String = "  %s  %s  %s" % [str(spec[1]), "ผู้เล่นและระบบ" if menu_id == "Connect" else _thai_panel_name(menu_id), str(spec[2])]
		var entry := _button(title_text, func(): _open_player_menu(menu_id), player_dropdown_column)
		entry.name = "Menu_" + menu_id
		entry.custom_minimum_size = Vector2(215, 38)
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
		entry.set_meta("leo_fantasy_skin", true)
		entry.add_theme_font_size_override("font_size", 14)
		entry.add_theme_stylebox_override("normal", _silver_panel_style(7, Color("152e4adf")))
		entry.add_theme_stylebox_override("hover", _silver_panel_style(7, Color("2c4f73ff")))
		entry.add_theme_stylebox_override("pressed", _silver_panel_style(7, Color("365e82ff")))
		dropdown_entries[menu_id] = entry
	player_dropdown.hide()
	menu_toggle_button = _button("", _toggle_player_dropdown)
	menu_toggle_button.name = "PlayerMainMenuButton"
	# Draw a true three-bar hamburger; font glyph support varies on mobile.
	for line_y in [15.0, 23.0, 31.0]:
		var hamburger_line := ColorRect.new()
		hamburger_line.color = Color("49391e")
		hamburger_line.position = Vector2(15.0, line_y)
		hamburger_line.size = Vector2(22.0, 3.0)
		hamburger_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu_toggle_button.add_child(hamburger_line)
	menu_toggle_button.size = Vector2(52, 52)
	menu_toggle_button.z_index = 102
	menu_toggle_button.tooltip_text = "เมนูหลักสำหรับผู้เล่นทุกคน"
	menu_toggle_button.set_meta("leo_fantasy_skin", true)
	menu_toggle_button.add_theme_font_size_override("font_size", 28)
	menu_toggle_button.add_theme_color_override("font_color", Color("352916"))
	menu_toggle_button.add_theme_stylebox_override("normal", _menu_orb_style(Color("f5ce38"), Color("fff1a7")))
	menu_toggle_button.add_theme_stylebox_override("hover", _menu_orb_style(Color("ffe26b"), Color("fff8c5")))
	menu_toggle_button.add_theme_stylebox_override("pressed", _menu_orb_style(Color("dba719"), Color("ffec8e")))
	buttons.append(menu_toggle_button)
	owner_gm_button = _button("GM", func(): _show_panel("GM"))
	owner_gm_button.name = "OwnerGMButton"
	owner_gm_button.size = Vector2(52, 52)
	owner_gm_button.z_index = 102
	owner_gm_button.tooltip_text = "GM ทดสอบออฟไลน์ — คำสั่งไม่ส่งไปเซิร์ฟเวอร์"
	owner_gm_button.set_meta("leo_fantasy_skin", true)
	owner_gm_button.add_theme_font_size_override("font_size", 15)
	owner_gm_button.add_theme_color_override("font_color", Color.WHITE)
	owner_gm_button.add_theme_stylebox_override("normal", _menu_orb_style(Color("b51729"), Color("ffe1e3")))
	owner_gm_button.add_theme_stylebox_override("hover", _menu_orb_style(Color("e03942"), Color("ffffff")))
	owner_gm_button.add_theme_stylebox_override("pressed", _menu_orb_style(Color("7e101e"), Color("fff4f4")))
	buttons.append(owner_gm_button)
	_refresh_gm_button()

func _toggle_player_dropdown() -> void:
	if player_dropdown.visible:
		_close_player_dropdown()
	else:
		panel.hide()
		active_panel = ""
		dropdown_backdrop.show()
		player_dropdown.show()
		player_dropdown.move_to_front()
		menu_toggle_button.move_to_front()
		if owner_gm_button.visible:
			owner_gm_button.move_to_front()

func _close_player_dropdown() -> void:
	if is_instance_valid(player_dropdown):
		player_dropdown.hide()
	if is_instance_valid(dropdown_backdrop):
		dropdown_backdrop.hide()

func _open_player_menu(name: String) -> void:
	_close_player_dropdown()
	_show_panel(name)

func _player_entry_rects() -> Dictionary:
	var rects: Dictionary = {}
	if not is_instance_valid(player_dropdown) or not player_dropdown.visible:
		return rects
	for menu_id in dropdown_entries:
		var entry: Button = dropdown_entries[menu_id]
		if is_instance_valid(entry):
			var rect := entry.get_global_rect()
			rects[str(menu_id)] = [rect.get_center().x, rect.get_center().y]
	return rects

func _can_use_gm() -> bool:
	# Offline Sandbox is a PUBLIC playtest. Local GM is a development tool and
	# cannot grant server authority; anyone visiting the sandbox can use it.
	# While connecting/online, GM is strictly gated by server confirmation.
	return (not network.active and not network.connecting) or gm_authorized

func _refresh_gm_button() -> void:
	var allowed := _can_use_gm()
	if is_instance_valid(owner_gm_button):
		owner_gm_button.visible = allowed
		owner_gm_button.tooltip_text = "GM ทดสอบออฟไลน์ (สำหรับผู้ทดสอบทุกคน)" if not network.active and not network.connecting else "GM เจ้าของเซิร์ฟเวอร์ (ยืนยันสิทธิ์แล้ว)"
	if not allowed and active_panel == "GM":
		_close_panel()

func _set_gm_authorized(authorized: bool) -> void:
	gm_authorized = authorized
	_refresh_gm_button()

func _owner_login_panel() -> void:
	menu.add_child(_label("ยืนยันเจ้าของระบบกับเซิร์ฟเวอร์ผ่าน WSS เท่านั้น\nเว็บไซต์สาธารณะไม่เก็บรหัส GM และไม่ให้สิทธิ์แก่ผู้เล่นทั่วไป", 14))
	if not network.active:
		menu.add_child(_label("ยังไม่ได้เชื่อมต่อเซิร์ฟเวอร์ที่รองรับการยืนยันเจ้าของ", 14))
		_button("ตั้งค่าเซิร์ฟเวอร์", func(): _show_panel("Connect"), menu)
		return
	var field := LineEdit.new()
	field.name = "OwnerSecretInput"
	field.secret = true
	field.placeholder_text = "รหัสเจ้าของจากเซิร์ฟเวอร์ (อย่างน้อย 24 ตัวอักษร)"
	field.custom_minimum_size = Vector2(235, 42)
	menu.add_child(field)
	_button("ยืนยันเจ้าของ / เปิดปุ่ม GM", func():
		network.authenticate_owner(field.text)
		field.clear()
		_close_panel()
	, menu)

func _build_ui() -> void:
	var theme := Theme.new()
	var steel = load("res://scripts/celestial_steel.gd")
	var font: FontFile = load("res://assets/fonts/NotoSansThai.ttf")
	font.fallbacks = [ThemeDB.fallback_font]
	theme.default_font = font
	world.hud.theme = theme
	# Compact premium navy-and-silver HUD, leaving the middle of the screen
	# clear for the real 3D player and eventual professional assets.
	hud_status_panel = PanelContainer.new()
	hud_status_panel.name = "HUDCharacterFrame"
	hud_status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_status_panel.set_meta("leo_fantasy_skin", true)
	hud_status_panel.add_theme_stylebox_override("panel", steel.panel_style(Color("#10233DF2"), Color("#B7D4ED"), 14))
	hud_status_panel.size = Vector2(324, 155)
	world.hud.add_child(hud_status_panel)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 3)
	hud_status_panel.add_child(stack)
	var brand_line := _label("N E X T G E N   L E O  /  ADVENTURE", 11)
	brand_line.name = "CelestialBrandLine"
	brand_line.set_meta("leo_fantasy_skin", true)
	brand_line.add_theme_color_override("font_color", Color("#E4C987"))
	stack.add_child(brand_line)
	var identity_row := HBoxContainer.new()
	identity_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(identity_row)
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(42, 39)
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.set_meta("leo_fantasy_skin", true)
	portrait_frame.add_theme_stylebox_override("panel", _silver_panel_style(18, Color("254464")))
	identity_row.add_child(portrait_frame)
	hud_portrait_label = _label("✦", 23)
	hud_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_frame.add_child(hud_portrait_label)
	stats_label = _label("", 15)
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_row.add_child(stats_label)
	hp_bar = _bar(stack, Color("cf5567"))
	stamina_bar = _bar(stack, Color("e6bf46"))
	exp_bar = _bar(stack, Color("4e9fd9"))
	hud_currency_label = _label("", 12)
	stack.add_child(hud_currency_label)
	hud_quest_panel = PanelContainer.new()
	hud_quest_panel.name = "HUDQuestFrame"
	hud_quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_quest_panel.set_meta("leo_fantasy_skin", true)
	hud_quest_panel.add_theme_stylebox_override("panel", steel.panel_style(Color("#0C233BE9"), Color("#6597C6"), 12))
	hud_quest_panel.size = Vector2(324, 83)
	world.hud.add_child(hud_quest_panel)
	quest_label = _label("", 13)
	hud_quest_panel.add_child(quest_label)
	hud_target_panel = PanelContainer.new()
	hud_target_panel.name = "HUDTargetFrame"
	hud_target_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_target_panel.set_meta("leo_fantasy_skin", true)
	hud_target_panel.add_theme_stylebox_override("panel", steel.panel_style(Color("#18273CF0"), Color("#D7BE8A"), 12))
	hud_target_panel.size = Vector2(350, 80)
	world.hud.add_child(hud_target_panel)
	var target_stack := VBoxContainer.new()
	target_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_target_panel.add_child(target_stack)
	target_label = _label("กด TAB เพื่อล็อกเป้าหมาย", 16)
	target_stack.add_child(target_label)
	hud_target_hp = _bar(target_stack, Color("c74e5d"))
	hud_target_hp.visible = false
	hud_notice_panel = PanelContainer.new()
	hud_notice_panel.name = "HUDNoticeToast"
	hud_notice_panel.size = Vector2(520, 74)
	hud_notice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_notice_panel.set_meta("leo_fantasy_skin", true)
	hud_notice_panel.add_theme_stylebox_override("panel", steel.panel_style(Color("#132D48EF"), Color("#8FB9DD"), 12))
	world.hud.add_child(hud_notice_panel)
	notice = _label("", 14)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_notice_panel.add_child(notice)
	hud_notice_panel.hide()
	hud_state_label = _label("", 13)
	hud_state_label.add_theme_color_override("font_shadow_color", Color("020612"))
	hud_state_label.add_theme_constant_override("shadow_offset_y", 1)
	world.hud.add_child(hud_state_label)
	# The gold menu is shared by all players. In the public Offline Sandbox,
	# the separate red GM orb exposes LOCAL TEST TOOLS to all visitors.
	# Once a server connection begins, it requires server owner verification.
	_build_player_dropdown()
	var controls := ["ล็อกเป้า\n[TAB]", "เก็บของ\n[E]", "โจมตี\n[F]", "สกิล 1\n[1]", "สกิล 2\n[2]", "สกิล 3\n[3]", "พุ่ง\n[R]", "ล่าอัตโนมัติ\n[H]"]
	for i in range(controls.size()):
		var index := i
		var button := _button(controls[i], func(): _action(index))
		button.size = Vector2(90, 65)
		button.set_meta("layout_id", "action_%d" % i)
		button.set_meta("leo_fantasy_skin", true)
		button.add_theme_font_size_override("font_size", 12)
		button.tooltip_text = ["ล็อกเป้าหมาย", "เก็บของ", "โจมตีปกติ", "สกิล 1", "สกิล 2", "สกิล 3", "พุ่งหลบ", "ล่าอัตโนมัติ"][i]
		button.text = ""
		var art := Control.new()
		art.set_script(load("res://scripts/celestial_action_icon.gd"))
		art.set("action_id", i)
		art.name = "ActionIcon"
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var caption := Label.new()
		caption.name = "ActionCaption"
		caption.text = ["ล็อก", "เก็บ", "โจมตี", "สกิล 1", "สกิล 2", "สกิล 3", "พุ่ง", "ออโต้"][i]
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.set_meta("leo_fantasy_skin", true)
		caption.add_theme_color_override("font_color", Color("#F5F9FF"))
		caption.add_theme_color_override("font_shadow_color", Color("#081122"))
		caption.add_theme_constant_override("shadow_offset_x", 1)
		caption.add_theme_constant_override("shadow_offset_y", 1)
		caption.add_theme_font_size_override("font_size", 11)
		button.add_child(caption)
		caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		skill_buttons.append(button)
	_style_hud_actions("")
	map_display = Control.new()
	map_display.set_script(load("res://scripts/minimap.gd"))
	map_display.game = self
	map_display.size = Vector2(155, 155)
	map_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.hud.add_child(map_display)
	panel = PanelContainer.new()
	# Dock every opened menu within the far-left highlighted area.
	panel.position = Vector2(12, 12)
	panel.size = Vector2(390, 696)
	panel.z_index = 100
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("leo_fantasy_skin", true)
	panel.add_theme_stylebox_override("panel", _silver_panel_style(12, Color("102440f7")))
	world.hud.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	menu = VBoxContainer.new()
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(menu)
	panel.hide()
	world.get_viewport().size_changed.connect(_layout)
	_layout()

func _style_hud_actions(faction_id: String) -> void:
	var steel = load("res://scripts/celestial_steel.gd")
	for i in range(skill_buttons.size()):
		var button: Button = skill_buttons[i]
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			button.add_theme_stylebox_override(state, steel.action_style(i, faction_id, state))
		button.add_theme_color_override("font_color", Color("#F3F7FF"))
		var art: Control = button.get_node_or_null("ActionIcon")
		if is_instance_valid(art):
			art.queue_redraw()
	hud_action_style_key = faction_id

func _bar(parent: Node, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(270, 20)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("fill", _style(color, color, 4))
	bar.add_theme_stylebox_override("background", _style(Color("0c1828"), Color("33475a"), 4))
	for key in ["fill","background"]:
		var box: StyleBoxFlat = bar.get_theme_stylebox(key)
		box.content_margin_top = 0
		box.content_margin_bottom = 0
	parent.add_child(bar)
	var value_label := _label("",13)
	value_label.name = "Value"
	value_label.set_meta("leo_fantasy_skin", true)
	bar.add_child(value_label)
	value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return bar

func _layout() -> void:
	var responsive = load("res://scripts/responsive_ui.gd")
	var size: Vector2 = world.get_viewport().get_visible_rect().size
	var bounds: Rect2 = responsive.safe_bounds(world.get_viewport())
	var portrait: bool = responsive.is_portrait(bounds.size)
	var ui_scale: float = float(GameState.settings.get("ui_scale", 1.0))
	var offset_key: String = responsive.offsets_key(size)
	var saved_offsets: Dictionary = GameState.settings.get(offset_key, {})
	# Older user saves remain compatible with the original landscape layout.
	if not portrait and saved_offsets.is_empty():
		saved_offsets = GameState.settings.get("button_offsets", {})
	for i in range(skill_buttons.size()):
		var button := skill_buttons[i]
		var base_rect: Rect2 = responsive.action_slot_rect(i, bounds, ui_scale)
		button.size = base_rect.size
		var caption: Label = button.get_node_or_null("ActionCaption")
		if is_instance_valid(caption):
			caption.add_theme_font_size_override("font_size", clampi(roundi(11.0 * responsive.input_scale(bounds, ui_scale)), 11, 48))
		var offset: Array = saved_offsets.get(str(button.get_meta("layout_id")), [0, 0])
		var requested := Rect2(base_rect.position + Vector2(float(offset[0]), float(offset[1])), base_rect.size)
		button.position = responsive.keep_inside(requested, bounds).position
	var visual_scale: float = responsive.input_scale(bounds, ui_scale) if portrait else 1.0
	if portrait:
		# Use real canvas-sized controls and native-scale font rasterization.
		# Scaling a 13px Label node 3x produces blurry letters in the Web
		# canvas on narrow phones. Instead rasterize text at 40+ canvas px.
		for node in [hud_status_panel, hud_quest_panel, hud_target_panel, hud_notice_panel, hud_state_label]:
			node.scale = Vector2.ONE
		map_display.scale = Vector2.ONE * (visual_scale * 0.60)
		var status_width := minf(bounds.size.x * 0.74, 286.0 * visual_scale)
		hud_status_panel.size = Vector2(status_width, 133.0 * visual_scale)
		hud_status_panel.position = bounds.position
		var brand: Label = hud_status_panel.find_child("CelestialBrandLine", true, false)
		if is_instance_valid(brand):
			brand.text = "NEX TGEN LEO"
			brand.add_theme_font_size_override("font_size", roundi(12.0 * visual_scale))
		stats_label.add_theme_font_size_override("font_size", roundi(15.0 * visual_scale))
		hud_portrait_label.add_theme_font_size_override("font_size", roundi(20.0 * visual_scale))
		var portrait_frame: Control = hud_portrait_label.get_parent()
		portrait_frame.custom_minimum_size = Vector2(36.0, 36.0) * visual_scale
		hud_currency_label.add_theme_font_size_override("font_size", roundi(13.0 * visual_scale))
		quest_label.add_theme_font_size_override("font_size", roundi(14.0 * visual_scale))
		target_label.add_theme_font_size_override("font_size", roundi(14.0 * visual_scale))
		notice.add_theme_font_size_override("font_size", roundi(14.0 * visual_scale))
		hud_state_label.add_theme_font_size_override("font_size", roundi(13.0 * visual_scale))
		for plate in [hud_status_panel, hud_quest_panel, hud_target_panel, hud_notice_panel]:
			var old_style: StyleBoxFlat = plate.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			old_style.content_margin_left = 8.0 * visual_scale
			old_style.content_margin_right = 8.0 * visual_scale
			old_style.content_margin_top = 6.0 * visual_scale
			old_style.content_margin_bottom = 6.0 * visual_scale
			old_style.set_corner_radius_all(roundi(10.0 * visual_scale))
			old_style.set_border_width_all(maxi(1, roundi(visual_scale)))
			old_style.border_width_top = maxi(2, roundi(2.0 * visual_scale))
			plate.add_theme_stylebox_override("panel", old_style)
		for bar in [hp_bar, stamina_bar, exp_bar]:
			bar.custom_minimum_size = Vector2(0.0, 17.0 * visual_scale)
			var value_text: Label = bar.get_node("Value")
			value_text.add_theme_font_size_override("font_size", roundi(12.0 * visual_scale))
		hud_quest_panel.size = Vector2(minf(bounds.size.x * 0.59, 230.0 * visual_scale), 52.0 * visual_scale)
		hud_quest_panel.position = Vector2(bounds.position.x, bounds.position.y + 139.0 * visual_scale)
		hud_target_panel.size = Vector2(minf(bounds.size.x * 0.80, 296.0 * visual_scale), 53.0 * visual_scale)
		hud_target_panel.position = Vector2(bounds.position.x, bounds.position.y + 195.0 * visual_scale)
		hud_target_hp.custom_minimum_size = Vector2(0.0, 17.0 * visual_scale)
		var hp_text: Label = hud_target_hp.get_node("Value")
		hp_text.add_theme_font_size_override("font_size", roundi(12.0 * visual_scale))
		map_display.position = Vector2(bounds.end.x - map_display.size.x * map_display.scale.x, bounds.position.y)
		hud_notice_panel.size = Vector2(minf(bounds.size.x * 0.76, 285.0 * visual_scale), 50.0 * visual_scale)
		hud_notice_panel.position = Vector2(bounds.position.x, bounds.position.y + (253.0 if target >= 0 else 195.0) * visual_scale)
		hud_state_label.position = Vector2(bounds.position.x, bounds.end.y - 278.0 * visual_scale)
	else:
		for node in [hud_status_panel, hud_quest_panel, hud_target_panel, hud_notice_panel, hud_state_label, map_display]:
			node.scale = Vector2.ONE
		var steel = load("res://scripts/celestial_steel.gd")
		hud_status_panel.add_theme_stylebox_override("panel", steel.panel_style(Color("#10233DF2"), Color("#B7D4ED"), 14))
		hud_quest_panel.add_theme_stylebox_override("panel", steel.panel_style(Color("#0C233BE9"), Color("#6597C6"), 12))
		hud_target_panel.add_theme_stylebox_override("panel", steel.panel_style(Color("#18273CF0"), Color("#D7BE8A"), 12))
		hud_notice_panel.add_theme_stylebox_override("panel", steel.panel_style(Color("#132D48EF"), Color("#8FB9DD"), 12))
		var portrait_frame: Control = hud_portrait_label.get_parent()
		portrait_frame.custom_minimum_size = Vector2(42.0, 39.0)
		hud_portrait_label.add_theme_font_size_override("font_size", 23)
		target_label.add_theme_font_size_override("font_size", 16)
		for bar in [hp_bar, stamina_bar, exp_bar]:
			bar.custom_minimum_size = Vector2(270.0, 20.0)
			var value_text: Label = bar.get_node("Value")
			value_text.add_theme_font_size_override("font_size", 13)
		hud_target_hp.custom_minimum_size = Vector2(270.0, 20.0)
		var hp_text: Label = hud_target_hp.get_node("Value")
		hp_text.add_theme_font_size_override("font_size", 13)
		var brand: Label = hud_status_panel.find_child("CelestialBrandLine", true, false)
		if is_instance_valid(brand):
			brand.text = "N E X T G E N   L E O  /  ADVENTURE"
			brand.add_theme_font_size_override("font_size", 11)
		stats_label.add_theme_font_size_override("font_size", 15)
		hud_currency_label.add_theme_font_size_override("font_size", 12)
		quest_label.add_theme_font_size_override("font_size", 13)
		notice.add_theme_font_size_override("font_size", 14)
		hud_state_label.add_theme_font_size_override("font_size", 13)
		hud_status_panel.size = Vector2(324, 155)
		for bar in [hp_bar, stamina_bar, exp_bar]:
			bar.custom_minimum_size.x = 270.0
		hud_quest_panel.size = Vector2(324, 83)
		hud_target_panel.size = Vector2(350, 80)
		hud_notice_panel.size.x = 520.0
		hud_status_panel.position = Vector2(12, 12)
		hud_quest_panel.position = Vector2(12, 175)
		hud_target_panel.position = Vector2(maxf(342.0, (size.x - 350.0) * 0.5), 14)
		hud_notice_panel.position = Vector2(maxf(345.0, (size.x - hud_notice_panel.size.x) * 0.5), 103.0)
		hud_state_label.position = Vector2(minf(340.0, maxf(220.0, size.x * 0.27)), maxf(260.0, size.y - 78.0))
		map_display.position = Vector2(size.x - 175, 12)
	var menu_top := bounds.position.y + (145.0 * visual_scale if portrait else 20.0)
	if is_instance_valid(menu_toggle_button):
		menu_toggle_button.scale = Vector2.ONE * visual_scale
		menu_toggle_button.position = Vector2(bounds.end.x - menu_toggle_button.size.x * visual_scale, menu_top) if portrait else Vector2(maxf(6.0, size.x - 243.0), 32.0)
	if is_instance_valid(owner_gm_button):
		owner_gm_button.scale = Vector2.ONE * visual_scale
		owner_gm_button.position = Vector2(bounds.end.x - 2.0 * menu_toggle_button.size.x * visual_scale - 10.0 * visual_scale, menu_top) if portrait else Vector2(maxf(6.0, size.x - 305.0), 32.0)
	if is_instance_valid(dropdown_backdrop):
		dropdown_backdrop.position = Vector2.ZERO
		dropdown_backdrop.size = size
	if is_instance_valid(player_dropdown):
		player_dropdown.scale = Vector2.ONE * visual_scale
		if portrait:
			var max_local_width := bounds.size.x / visual_scale
			var max_local_height := bounds.size.y / visual_scale
			player_dropdown.size = Vector2(minf(240.0, max_local_width), minf(475.0, max_local_height - 225.0))
			player_dropdown.position = Vector2(bounds.end.x - player_dropdown.size.x * visual_scale, menu_top + 58.0 * visual_scale)
		else:
			var dropdown_height := minf(475.0, maxf(180.0, size.y - 108.0))
			player_dropdown.size = Vector2(minf(240.0, maxf(170.0, size.x - 16.0)), dropdown_height)
			player_dropdown.position = Vector2(maxf(8.0, size.x - 425.0), 92.0 if size.y >= 560.0 else 65.0)
	panel.position = bounds.position if portrait else Vector2(12, 12)
	if active_panel == "Bag":
		var bag_width: float = minf(620.0, maxf(300.0, size.x * 0.44))
		if portrait:
			bag_width = bounds.size.x
		var bag_height: float = maxf(160.0, size.y - 24.0)
		panel.size = Vector2(minf(bag_width, maxf(150.0, size.x - 24.0)), bag_height)
	else:
		panel.size = Vector2(minf(390.0, maxf(150.0, size.x - 24.0)), maxf(160.0, size.y - 24.0))
	if portrait:
		panel.scale = Vector2.ONE * visual_scale
		panel.size = bounds.size / visual_scale
	else:
		panel.scale = Vector2.ONE

func _tell(text: String) -> void:
	notice.text = text
	notice_hide_timer = (3.5 if world.get_viewport().get_visible_rect().size.y > world.get_viewport().get_visible_rect().size.x else 5.5) if not text.is_empty() else 0.0
	if is_instance_valid(hud_notice_panel):
		hud_notice_panel.visible = not text.is_empty()

func _action(index: int, from_touch := false) -> void:
	if not from_touch and Time.get_ticks_msec() - last_touch_action < 200: return
	if from_touch: last_touch_action = Time.get_ticks_msec()
	match index:
		0: _select_target()
		1: _pickup()
		2, 3, 4, 5:
			if target < 0:
				_tell("Select a target first")
				return
			pending_skill = index - 2
			auto_attack = true
		6:
			if GameState.stamina >= 10 and GameState.hp > 0:
				GameState.stamina -= 10
				world.dash_time = 0.2
				auto_attack = false
				auto_hunt = false
				world.auto_destination = Vector3.INF
		7:
			auto_hunt = not auto_hunt
			auto_attack = auto_hunt
			_tell("Auto Hunt " + ("ON" if auto_hunt else "OFF"))

func _select_target() -> void:
	var candidates: Array[int] = []
	for i in range(mobs.size()):
		if int(mobs[i].hp) > 0:
			candidates.append(i)
	candidates.sort_custom(func(a, b): return world.player.position.distance_squared_to(mobs[a].node.position) < world.player.position.distance_squared_to(mobs[b].node.position))
	if candidates.is_empty():
		target = -1
		return
	var index := candidates.find(target)
	target = candidates[(index + 1) % candidates.size()]

func _attack(index: int) -> void:
	if target < 0 or GameState.hp <= 0:
		return
	if network.active:
		_online_attack(index)
		return
	var skill: Dictionary = GameState.skill_definition(index)
	if float(cooldowns[index]) > 0 or GameState.stamina < float(skill.cost):
		return
	var mob: Dictionary = mobs[target]
	if int(mob.hp) <= 0:
		return
	var reach: float = skill.range
	var id: String = GameState.equipped.get("weapon", {}).get("id", "sword")
	var job: Dictionary = GameState.job_definition()
	if index == 0 and not job.is_empty():
		reach = float(job.range)
	elif index == 0 and id != "sword":
		reach = 12 if id == "gun" else 7
	var distance: float = world.player.position.distance_to(mob.node.position)
	if distance > reach:
		world.auto_destination = mob.node.position
		return
	world.auto_destination = Vector3.INF
	world.player.look_at(Vector3(mob.node.position.x, world.player.position.y, mob.node.position.z))
	GameState.stamina -= float(skill.cost)
	cooldowns[index] = float(skill.cooldown) * (1.5 if id == "gun" else (1.2 if id == "kunai" else 1.0))
	if index == 0 and not job.is_empty():
		cooldowns[0] = float(job.interval)
	swing = 0.35
	var critical := rng.randf() < float(GameState.balance.critical_chance) or index == 3
	var damage := maxi(1, int(GameState.attack_power() * float(skill.power) * (float(GameState.balance.critical_multiplier) if critical else 1.0)) - int(mob.level) * 2)
	var hit_indices: Array[int] = [target]
	if float(skill.radius) > 0 or (GameState.class_rank >= 7 and GameState.skill_mode == "AoE" and index > 0):
		for i in range(mobs.size()):
			if i != target and int(mobs[i].hp) > 0 and mobs[i].node.position.distance_to(mob.node.position) < 4:
				hit_indices.append(i)
	for i in hit_indices:
		mobs[i].hp = maxi(0, int(mobs[i].hp) - damage)
		var text := _tag(mobs[i].node, str(damage) + ("!" if critical else ""), 2.6, Color("ffe59b"))
		var tween := create_tween()
		tween.tween_property(text, "position:y", 3.8, 0.6)
		tween.tween_callback(text.queue_free)
		if int(mobs[i].hp) == 0:
			_killed(i)
	var flash := _mesh(world, mob.node.position + Vector3(0, 0.8, 0), Vector3.ONE * (1.8 if index > 0 else 0.8), Color("e9c886"), "sphere")
	var effect := create_tween()
	effect.tween_property(flash, "scale", Vector3.ONE * 0.01, 0.24)
	effect.tween_callback(flash.queue_free)
	pending_skill = 0

func _killed(index: int) -> void:
	var mob: Dictionary = mobs[index]
	mob.node.visible = false
	mob.respawn = 12.0 if mob.kind == "Normal" else (1200.0 if mob.kind == "Elite" else (43200.0 if mob.kind == "Boss" else 86400.0))
	GameState.add_exp(35 + int(mob.level) * 10)
	GameState.record_kill()
	var drop := Node3D.new()
	world.add_child(drop)
	drop.position = mob.node.position + Vector3(0, 0.25, 0)
	_mesh(drop, Vector3.ZERO, Vector3.ONE * 0.3, Color("f5cd70"), "sphere")
	drops.append({"node":drop,"id":"ore" if mob.kind != "Normal" else "herb","gold":5 + int(mob.level)})
	if index == target:
		target = -1
		world.auto_destination = Vector3.INF

func _pickup() -> void:
	for i in range(drops.size() - 1, -1, -1):
		var drop: Dictionary = drops[i]
		if world.player.position.distance_to(drop.node.position) <= 4 and GameState.add_item(drop.id):
			GameState.gold += int(drop.gold)
			drop.node.queue_free()
			drops.remove_at(i)

func _revive(at_spot := false) -> void:
	if at_spot:
		for i in range(GameState.inventory.size()):
			if GameState.inventory[i].id == "revive":
				GameState.use_item(i)
				_close_panel()
				return
		_tell("Revive crystal required")
		return
	GameState.exp = maxi(0, GameState.exp - int(GameState.exp_required() * 0.02))
	GameState.hp = GameState.max_hp
	world.player.position = Vector3(-3, 1.1, -2)
	dead_timer = 0
	_close_panel()

func _process(delta: float) -> void:
	if notice_hide_timer > 0.0:
		notice_hide_timer = maxf(0.0, notice_hide_timer - delta)
		if notice_hide_timer <= 0.0 and is_instance_valid(hud_notice_panel):
			hud_notice_panel.hide()
	if network.active:
		_online_tick(delta)
		return
	animation_time += delta
	swing = maxf(0, swing - delta)
	for i in range(4):
		cooldowns[i] = maxf(0, float(cooldowns[i]) - delta)
	GameState.stamina = minf(GameState.max_stamina, GameState.stamina + delta * 7)
	regen_timer += delta
	if regen_timer > 1:
		regen_timer = 0
		GameState._recalculate_stats(false)
	if GameState.hp <= 0:
		dead_timer += delta
		if active_panel != "Death" and not panel.visible:
			_show_panel("Death")
		if dead_timer > 30:
			_revive()
		avatar.rotation.z = lerpf(avatar.rotation.z, PI / 2, delta * 5)
	else:
		avatar.rotation.z = 0
		var moving: float = Vector2(world.player.velocity.x, world.player.velocity.z).length()
		for i in range(limbs.size()):
			limbs[i].rotation.x = sin(animation_time * 9 + (PI if i % 2 else 0)) * minf(0.55, moving * 0.09)
		if swing > 0:
			limbs[3].rotation.x = -1.6 + (0.35 - swing) * 7
		_tick_mobs(delta)
		if auto_hunt and target < 0:
			_select_target()
			if target >= 0 and world.player.position.distance_to(mobs[target].node.position) > hunt_radius:
				target = -1
		if (auto_attack or auto_hunt) and target >= 0:
			if auto_hunt:
				for i in range(3, 0, -1):
					if hunt_skills[i - 1] and float(cooldowns[i]) == 0 and GameState.stamina >= float(GameState.skill_definition(i).cost):
						pending_skill = i
						break
			_attack(pending_skill)
		if npc_navigation and world.player.position.distance_to(npc.position) < 3:
			npc_navigation = false
			world.auto_destination = Vector3.INF
			_tell(GameState.interact_quest())
	pet.visible = GameState.pet_enabled
	if pet.visible:
		var destination: Vector3 = world.player.position + Vector3(1.4, -0.9, 1)
		pet.position = pet.position.lerp(destination, delta * 3)
		pet.position.y = 0.05 + sin(animation_time * 5) * 0.07
		if GameState.hp > 0:
			_pickup()
	save_timer += delta
	if save_timer > 10:
		save_timer = 0
		_save()
	ui_refresh += delta
	if ui_refresh > 0.15:
		ui_refresh = 0
		_refresh_hud()

func _tick_mobs(delta: float) -> void:
	for mob in mobs:
		if int(mob.hp) <= 0:
			mob.respawn = float(mob.respawn) - delta
			if float(mob.respawn) <= 0:
				mob.hp = mob.max_hp
				mob.node.position = mob.home
				mob.node.visible = true
			continue
		var offset: Vector3 = world.player.position - mob.node.position
		offset.y = 0
		var distance := offset.length()
		var player_safe: bool = world.player.position.x > -10 and world.player.position.x < 2 and world.player.position.z > -7 and world.player.position.z < 3
		var aggro: bool = (int(mob.hp) < int(mob.max_hp) or int(mob.level) > GameState.level or mob.kind != "Normal") and distance < 12 and not player_safe
		var destination: Vector3 = mob.home
		if aggro and mob.node.position.distance_to(mob.home) < 17:
			destination = world.player.position
		if mob.kind == "Normal" and float(mob.hp) / float(mob.max_hp) < 0.08:
			destination = mob.node.position - offset.normalized() * 4
		var travel: Vector3 = destination - mob.node.position
		travel.y = 0
		if travel.length() > 1.5:
			mob.node.position += travel.normalized() * delta * (2.0 if mob.kind == "Normal" else 2.8)
		mob.attack_timer = maxf(0, float(mob.attack_timer) - delta)
		if aggro and distance < 1.9 and float(mob.attack_timer) <= 0:
			mob.attack_timer = 1.5
			GameState.hp = maxi(0, GameState.hp - maxi(1, int(mob.level) * 3 + 8 - GameState.defense()))
			if GameState.hp == 0:
				auto_hunt = false
				auto_attack = false
				world.auto_destination = Vector3.INF
		mob.label.text = "%s Lv.%d\n%d / %d" % [mob.kind + " Mossling", int(mob.level), int(mob.hp), int(mob.max_hp)]
		mob.label.modulate = Color("ffe2a4") if target >= 0 and mobs[target] == mob else Color.WHITE
		mob.node.visible = mob.node.position.distance_squared_to(world.player.position) < 1600

func _thai_skill_name(index: int) -> String:
	var definition: Dictionary = GameState.skill_definition(index)
	var raw: String = str(definition.get("name", "สกิล"))
	var basic := {"Claymore":"ดาบใหญ่", "Crescent":"จันทร์เสี้ยว", "Pierce":"ทะลวง", "Judgment":"พิพากษา"}
	if basic.has(raw):
		return str(basic[raw])
	var element: String = str(definition.get("element", ""))
	var elements := {"Earth":"ดิน", "Water":"น้ำ", "Wind":"ลม", "Fire":"ไฟ", "Lightning":"สายฟ้า", "Wood":"พฤกษา"}
	if not elements.has(element):
		return raw
	var suffix := "สกิล"
	if raw.ends_with(" Burst"):
		suffix = "ระเบิด"
	elif raw.ends_with(" Strike"):
		suffix = "โจมตี"
	elif raw.ends_with(" Finale"):
		suffix = "ท่าไม้ตาย"
	return str(elements[element]) + suffix

func _refresh_hud() -> void:
	var portrait_ui := world.get_viewport().get_visible_rect().size.y > world.get_viewport().get_visible_rect().size.x
	stats_label.text = ("%s  |  C%d Lv%d" % ["ชาย" if GameState.gender == "Male" else "หญิง", GameState.class_rank, GameState.level]) if portrait_ui else ("%s · คลาส %d / เลเวล %d" % ["ชาย" if GameState.gender == "Male" else "หญิง", GameState.class_rank, GameState.level])
	hud_portrait_label.text = "ช" if GameState.gender == "Male" else "ญ"
	hud_currency_label.text = ("ทอง %d  |  แคช %d" if portrait_ui else "ทอง %d   |   แคช %d") % [GameState.gold, GameState.cash]
	hp_bar.max_value = GameState.max_hp
	hp_bar.value = GameState.hp
	stamina_bar.max_value = GameState.max_stamina
	stamina_bar.value = GameState.stamina
	exp_bar.max_value = GameState.exp_required()
	exp_bar.value = GameState.exp
	hp_bar.get_node("Value").text = "HP  %d / %d" % [GameState.hp, GameState.max_hp]
	stamina_bar.get_node("Value").text = ("STM %d / %d" if portrait_ui else "Stamina  %d / %d") % [int(GameState.stamina),GameState.max_stamina]
	exp_bar.get_node("Value").text = "EXP  %d / %d" % [GameState.exp,GameState.exp_required()]
	if active_panel == "Bag" and is_instance_valid(bag_status_label):
		bag_status_label.text = _bag_status_text()
		if bag_status_bars.size() == 3 and is_instance_valid(bag_status_bars[0]):
			for i in range(3):
				var bar := bag_status_bars[i]
				var value: float = float([float(GameState.hp), float(GameState.stamina), float(GameState.exp)][i])
				var maximum: float = float([float(GameState.max_hp), float(GameState.max_stamina), float(GameState.exp_required())][i])
				bar.max_value = maxf(1.0, maximum)
				bar.value = value
				bar.get_node("Value").text = "%s  %d / %d" % [["HP", "พลังงาน", "EXP"][i], int(value), int(maximum)]
	var quest_title: String = "ยังไม่ได้รับ" if GameState.quest_state == "available" else ("เสร็จสิ้น" if GameState.quest_state == "complete" else "กำลังทำ")
	quest_label.text = ("เควสต์: %s  %d/5\n%s" if portrait_ui else "แผนที่: %s\nเควสต์เริ่มต้น: %s   %d/5") % ([quest_title, GameState.quest_kills, str(GameState.balance.maps[GameState.map_index].name)] if portrait_ui else [str(GameState.balance.maps[GameState.map_index].name), quest_title, GameState.quest_kills])
	target_label.text = "กด TAB หรือ LOCK เพื่อเลือกเป้าหมาย" if target < 0 else "%s · Lv.%d · HP %d/%d" % [mobs[target].kind + " Mossling", int(mobs[target].level), int(mobs[target].hp), int(mobs[target].max_hp)]
	hud_target_hp.visible = target >= 0 and target < mobs.size()
	if hud_target_hp.visible:
		hud_target_hp.max_value = maxf(1.0, float(mobs[target].max_hp))
		hud_target_hp.value = float(mobs[target].hp)
		hud_target_hp.get_node("Value").text = "%d / %d" % [int(mobs[target].hp), int(mobs[target].max_hp)]
	var active_buffs := 0
	for buff_id in GameState.buffs:
		if GameState.buff_active(str(buff_id)):
			active_buffs += 1
	hud_state_label.text = ("AUTO %s  /  PET %s  /  BUFF %d" % ["ON" if auto_hunt else "OFF", "ON" if GameState.pet_enabled else "OFF", active_buffs]) if world.get_viewport().get_visible_rect().size.y > world.get_viewport().get_visible_rect().size.x else ("ล่าอัตโนมัติ: %s  |  สัตว์เก็บของ: %s  |  บัฟ: %d" % ["เปิด" if auto_hunt else "ปิด", "เรียก" if GameState.pet_enabled else "เก็บ", active_buffs])
	hud_target_panel.visible = target >= 0 or world.get_viewport().get_visible_rect().size.x >= world.get_viewport().get_visible_rect().size.y
	for i in range(4):
		var button := skill_buttons[i + 2]
		var caption: Label = button.get_node_or_null("ActionCaption")
		if is_instance_valid(caption):
			caption.text = ("%.1fs" % float(cooldowns[i])) if float(cooldowns[i]) > 0 else (["โจมตี", "สกิล 1", "สกิล 2", "สกิล 3"][i])
		button.disabled = i > 0 and float(cooldowns[i]) > 0.0
	var active_faction := GameState.faction if GameState.class_rank >= 7 and GameState.faction in ["Light", "Dark"] else ""
	var faction_color := Color("e4e5da") if active_faction == "Light" else Color("9a77c5")
	world.joystick_base.color = Color(faction_color, 0.25) if not active_faction.is_empty() else Color.TRANSPARENT
	if hud_action_style_key != active_faction:
		_style_hud_actions(active_faction)
	if OS.has_feature("web"):
		var gm_rects: Dictionary = {}
		var gm_popups: Dictionary = {}
		if active_panel == "GM":
			for key in gm_choosers:
				if is_instance_valid(gm_choosers[key]):
					var center: Vector2 = gm_choosers[key].get_global_rect().get_center()
					gm_rects[key] = [center.x,center.y]
					var popup: PopupMenu = gm_choosers[key].get_popup()
					gm_popups[key] = {"visible":popup.visible,"position":[popup.position.x,popup.position.y],"size":[popup.size.x,popup.size.y]}
		var close_center := Vector2.ZERO
		if panel.visible and menu.get_child_count() > 1 and menu.get_child(1) is Button:
			close_center = (menu.get_child(1) as Button).get_global_rect().get_center()
		var bag_left_rect := Rect2()
		var bag_right_rect := Rect2()
		var preview_rect := Rect2()
		var preview_model_parts := 0
		var visible_equipment_slots := 0
		var equipment_rects: Dictionary = {}
		if active_panel == "Bag" and is_instance_valid(bag_character_preview) and is_instance_valid(bag_preview_model):
			preview_rect = bag_character_preview.get_global_rect()
			preview_model_parts = bag_preview_model.get_child_count()
			var character_rect := bag_character_panel.get_global_rect()
			for equip_button in bag_equipment_buttons:
				if is_instance_valid(equip_button):
					var equip_rect := equip_button.get_global_rect()
					equipment_rects[str(equip_button.get_meta("equip_slot_id"))] = [equip_rect.position.x, equip_rect.position.y, equip_rect.size.x, equip_rect.size.y]
					if equip_rect.position.y >= character_rect.position.y and equip_rect.end.y <= character_rect.end.y:
						visible_equipment_slots += 1
		if active_panel == "Bag" and is_instance_valid(bag_character_panel) and is_instance_valid(bag_inventory_panel):
			bag_left_rect = bag_character_panel.get_global_rect()
			bag_right_rect = bag_inventory_panel.get_global_rect()
		var bulk_toggle_center := Vector2.ZERO
		var bulk_sell_center := Vector2.ZERO
		var bulk_first_slot_center := Vector2.ZERO
		if active_panel == "Bag" and is_instance_valid(bag_inventory_panel):
			var toggle_node := bag_inventory_panel.find_child("BulkSelectionToggle", true, false)
			var sell_node := bag_inventory_panel.find_child("BulkSaleButton", true, false)
			if toggle_node is Control:
				bulk_toggle_center = (toggle_node as Control).get_global_rect().get_center()
			if sell_node is Control:
				bulk_sell_center = (sell_node as Control).get_global_rect().get_center()
			if is_instance_valid(bag_slot_grid) and bag_slot_grid.get_child_count() > 0:
				bulk_first_slot_center = (bag_slot_grid.get_child(0) as Control).get_global_rect().get_center()
		var action_rects: Array = []
		for action_button in skill_buttons:
			var action_rect := action_button.get_global_rect()
			action_rects.append([action_rect.position.x, action_rect.position.y, action_rect.size.x, action_rect.size.y])
		var mini_rect := map_display.get_global_rect()
		var stat_rect := hud_status_panel.get_global_rect()
		var quest_rect := hud_quest_panel.get_global_rect()
		var target_rect := hud_target_panel.get_global_rect()
		var gender_toggle_rect := Rect2()
		if active_panel == "Status":
			for control in menu.get_children():
				if control is Button and (control as Button).text == "Switch Male / Female":
					gender_toggle_rect = (control as Button).get_global_rect()
					break
		var model_mesh_count := 0
		if is_instance_valid(imported_avatar_visual):
			var mesh_count_value: Variant = imported_avatar_visual.get("rendered_mesh_count")
			if mesh_count_value != null:
				model_mesh_count = int(mesh_count_value)
		var diagnostic := {"hud_status_rect":[stat_rect.position.x,stat_rect.position.y,stat_rect.size.x,stat_rect.size.y],"hud_quest_rect":[quest_rect.position.x,quest_rect.position.y,quest_rect.size.x,quest_rect.size.y],"hud_target_rect":[target_rect.position.x,target_rect.position.y,target_rect.size.x,target_rect.size.y],"hud_action_style":hud_action_style_key,"bag_bulk_mode":bag_bulk_mode,"bag_bulk_count":bag_bulk_selection.size(),"bag_bulk_toggle":[bulk_toggle_center.x,bulk_toggle_center.y],"bag_bulk_sale":[bulk_sell_center.x,bulk_sell_center.y],"bag_bulk_first_slot":[bulk_first_slot_center.x,bulk_first_slot_center.y],"bag_preview_rect":[preview_rect.position.x,preview_rect.position.y,preview_rect.size.x,preview_rect.size.y],"bag_preview_parts":preview_model_parts,"bag_equipment_count":bag_equipment_buttons.size(),"bag_equipment_visible":visible_equipment_slots,"bag_equipment_rects":equipment_rects,"bag_equipment_regions":bag_slot_regions,"bag_left_rect":[bag_left_rect.position.x,bag_left_rect.position.y,bag_left_rect.size.x,bag_left_rect.size.y],"bag_right_rect":[bag_right_rect.position.x,bag_right_rect.position.y,bag_right_rect.size.x,bag_right_rect.size.y],"bag_columns":bag_slot_grid.columns if active_panel == "Bag" and is_instance_valid(bag_slot_grid) else 0,"drawer_rect":[panel.position.x,panel.position.y,panel.size.x,panel.size.y],"drawer_close":[close_center.x,close_center.y],"drawer_z":panel.z_index,"gender_toggle_rect":[gender_toggle_rect.position.x,gender_toggle_rect.position.y,gender_toggle_rect.size.x,gender_toggle_rect.size.y],"avatar_model_meshes":model_mesh_count,"version":"female-glb-v1-20261028","orientation":"portrait" if world.get_viewport().get_visible_rect().size.y > world.get_viewport().get_visible_rect().size.x else "landscape","action_rects":action_rects,"minimap_rect":[mini_rect.position.x,mini_rect.position.y,mini_rect.size.x,mini_rect.size.y],"gm_controls":gm_rects,"gm_popups":gm_popups,"gender":GameState.gender,"job":GameState.selected_job,"faction":GameState.faction,"class_rank":GameState.class_rank,"screen_size":[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y],"viewport_size":[world.get_viewport().get_visible_rect().size.x,world.get_viewport().get_visible_rect().size.y],"position":[world.player.position.x,world.player.position.y,world.player.position.z],"camera_zoom":world.camera.position.z,"player_screen":[world.camera.unproject_position(world.player.position).x,world.camera.unproject_position(world.player.position).y],"yaw":world.yaw,"target":target,"hp":GameState.hp,"panel":active_panel,"mobs":mobs.size(),"fps":Engine.get_frames_per_second(),"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"online":network.active,"attacking":auto_attack,"joystick":[world.joystick_vector.x,world.joystick_vector.y],"menu_open":player_dropdown.visible,"menu_button_rect":[menu_toggle_button.position.x,menu_toggle_button.position.y,menu_toggle_button.size.x,menu_toggle_button.size.y],"gm_button_visible":owner_gm_button.visible,"gm_button_rect":[owner_gm_button.position.x,owner_gm_button.position.y,owner_gm_button.size.x,owner_gm_button.size.y],"menu_dropdown_rect":[player_dropdown.position.x,player_dropdown.position.y,player_dropdown.size.x,player_dropdown.size.y],"menu_entry_rects":_player_entry_rects()}
		JavaScriptBridge.eval("window.leoDiagnostics=" + JSON.stringify(diagnostic), true)
	map_display.queue_redraw()

func _save() -> void:
	if network.active or network.connecting: return
	var pos: Vector3 = world.player.position
	GameState.location = [pos.x, pos.y, pos.z]
	GameState.save_game()

func _input(event: InputEvent) -> void:
	# Handle each action finger independently; emulated mouse handles only one finger.
	if event is InputEventScreenTouch and event.pressed and not panel.visible and not player_dropdown.visible:
		for i in range(skill_buttons.size()):
			if skill_buttons[i].get_global_rect().has_point(event.position):
				if skill_buttons[i].disabled:
					return
				_action(i, true)
				world.get_viewport().set_input_as_handled()
				return
		if world.jump_button.get_global_rect().has_point(event.position):
			world.jump_requested = true
			world.get_viewport().set_input_as_handled()
			return
	if layout_edit and event is InputEventMouseButton:
		if event.pressed:
			for button in skill_buttons:
				if button.get_global_rect().has_point(event.position):
					dragging_button = button
		else:
			if is_instance_valid(dragging_button):
				var i := skill_buttons.find(dragging_button)
				var size: Vector2 = world.get_viewport().get_visible_rect().size
				var responsive = load("res://scripts/responsive_ui.gd")
				var bounds: Rect2 = responsive.safe_bounds(world.get_viewport())
				var base: Vector2 = responsive.action_slot_rect(i, bounds, float(GameState.settings.get("ui_scale", 1.0))).position
				var offset := dragging_button.position - base
				var key: String = responsive.offsets_key(size)
				var saved: Dictionary = GameState.settings.get(key, {}).duplicate(true)
				saved[str(dragging_button.get_meta("layout_id"))] = [offset.x, offset.y]
				GameState.settings[key] = saved
				dragging_button = null
				_save()
	if layout_edit and event is InputEventMouseMotion and is_instance_valid(dragging_button):
		dragging_button.position += event.relative
		world.get_viewport().set_input_as_handled()
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_TAB: _select_target()
			KEY_F: _action(2)
			KEY_1: _action(3)
			KEY_2: _action(4)
			KEY_3: _action(5)
			KEY_R: _action(6)
			KEY_H: _action(7)
			KEY_E: _pickup()
			KEY_B: _show_panel("Bag")
			KEY_P: _show_panel("Shop")
			KEY_C: _show_panel("Status")
			KEY_Q: _show_panel("Quest")
			KEY_M: _show_panel("World")
			KEY_ESCAPE:
				_close_panel()
				auto_attack = false
				auto_hunt = false
				world.auto_destination = Vector3.INF
			KEY_W, KEY_A, KEY_S, KEY_D:
				npc_navigation = false
				auto_attack = false
				auto_hunt = false
	if event is InputEventScreenDrag and event.index == world.joystick_finger:
		npc_navigation = false
		auto_attack = false
		auto_hunt = false

func _load_hunt_preferences() -> void:
	var saved: Variant = GameState.settings.get("auto_hunt_skills", [true, true, true])
	if saved is Array and saved.size() == 3:
		for i in range(3):
			hunt_skills[i] = bool(saved[i])
	hunt_radius = clampf(float(GameState.settings.get("auto_hunt_radius", 18.0)), 8.0, 40.0)

func _save_hunt_preferences() -> void:
	if network.active or network.connecting:
		return
	GameState.settings["auto_hunt_skills"] = hunt_skills.duplicate()
	GameState.settings["auto_hunt_radius"] = hunt_radius
	_save()

func _select_hunt_skill(index: int, enabled: bool) -> void:
	if index < 0 or index >= hunt_skills.size():
		return
	hunt_skills[index] = enabled
	_save_hunt_preferences()

func _select_hunt_radius(radius: float) -> void:
	hunt_radius = clampf(radius, 8.0, 40.0)
	_save_hunt_preferences()
	_tell("บันทึกระยะล่าอัตโนมัติ %d เมตร" % int(hunt_radius))

func _close_panel() -> void:
	_close_player_dropdown()
	panel.hide()
	active_panel = ""

func _thai_panel_name(name: String) -> String:
	var names := {"BulkSellConfirm":"ยืนยันขายหลายชิ้น", "Bag":"กระเป๋า", "Shop":"ร้านค้า", "Cash":"ร้านค้าแคช", "Status":"ตัวละครและอุปกรณ์", "Quest":"ภารกิจ", "World":"แผนที่โลก", "Pet":"สัตว์เลี้ยง", "Auto":"ล่าอัตโนมัติ", "Skills":"ทักษะ", "GM":"ผู้ดูแลระบบ", "Settings":"ตั้งค่า", "Connect":"เชื่อมต่อ", "OwnerLogin":"ยืนยันสิทธิ์เจ้าของ", "Death":"ฟื้นคืนชีพ", "Item":"รายละเอียดไอเทม"}
	return str(names.get(name, name))

func _show_panel(name: String) -> void:
	if name == "GM" and not _can_use_gm():
		_tell("GM ออนไลน์ใช้ได้เฉพาะเจ้าของที่ผ่านการยืนยันสิทธิ์กับเซิร์ฟเวอร์")
		return
	_close_player_dropdown()
	if panel.visible and active_panel == name:
		_close_panel()
		return
	active_panel = name
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()
	_layout()
	panel.show()
	panel.move_to_front() # last sibling receives clicks before HUD controls beneath it
	var heading := _label(_thai_panel_name(name) + "   /   NEX TGEN LEO", 21)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu.add_child(heading)
	_button("ปิด [Esc]", _close_panel, menu)
	if name == "OwnerLogin":
		_owner_login_panel()
		return
	if network.active:
		_online_panel(name)
		return
	match name:
		"Bag": _bag()
		"BulkSellConfirm": _bag_bulk_confirm()
		"Shop", "Cash": _shop(name == "Cash")
		"Status": _status()
		"Quest":
			menu.add_child(_label("Starter Hunt · %s · %d / 5" % [GameState.quest_state, GameState.quest_kills]))
			_button("AUTO TO NPC", func(): npc_navigation = true; world.auto_destination = npc.position; _close_panel(), menu)
			_button("Talk to Elara", func():
				if world.player.position.distance_to(npc.position) < 4:
					_tell(GameState.interact_quest())
				else:
					_tell("Move closer, or use AUTO TO NPC")
				_close_panel(), menu)
			_button("Advance Class (Lv.100 + quest gate)", func(): _tell("Class advanced" if GameState.advance_class() else "Requirements not met"), menu)
		"World":
			for i in range(5):
				var index := i
				_button("Portal · " + str(GameState.balance.maps[i].name), func(): _warp(index), menu)
		"Pet":
			menu.add_child(_label("Companion Lv.%d  EXP %d  Evolution %d / 5\nAuto Loot active while summoned" % [GameState.pet_level, GameState.pet_exp, GameState.pet_stage]))
			_button("เรียก / เก็บสัตว์เลี้ยง", func(): GameState.pet_enabled = not GameState.pet_enabled, menu)
		"Auto":
			for i in range(3):
				var index := i
				var check := CheckButton.new()
				check.text = "Use " + str(GameState.skill_definition(i + 1).name)
				check.button_pressed = hunt_skills[i]
				check.toggled.connect(func(on): _select_hunt_skill(index, on))
				menu.add_child(check)
			for radius in [12.0, 20.0, 36.0]:
				_button("ระยะค้นหา %d เมตร" % int(radius), func(): _select_hunt_radius(radius), menu)
			_button("Start / stop Auto Hunt", func(): _action(7); _close_panel(), menu)
		"Skills":
			_skills_panel()
			_button("Settings", func(): _show_panel("Settings"), menu)
		"Settings":
			_button("Multiplayer development server", func(): _show_panel("Connect"), menu)
			_button("เจ้าของ: ยืนยันสิทธิ์ GM", func(): _show_panel("OwnerLogin"), menu)
			_button("บันทึกเกม", func(): _save(); _tell("Offline save written"), menu)
			_button("Edit button layout: drag action buttons", func(): layout_edit = not layout_edit; _close_panel(); _tell("Layout editing " + str(layout_edit)), menu)
			_button("คืนตำแหน่งปุ่ม", func(): GameState.settings.button_offsets = {}; GameState.settings["button_offsets_portrait"] = {}; GameState.settings["button_offsets_landscape"] = {}; _layout(); _save(), menu)
			for ui_pct in [90, 100, 110, 120]:
				var pct: int = int(ui_pct)
				_button("ขนาด UI %d%%" % pct, func(): _set_ui_scale(float(pct) / 100.0), menu)
			for quality in ["Low", "Medium", "High"]:
				_button(quality, func(): GameState.settings.quality = quality; world.get_viewport().scaling_3d_scale = 0.65 if quality == "Low" else 1.0; _set_shadows(quality == "High"); _tell("Quality: " + quality), menu)
			menu.add_child(_label("FPS %d · Render objects %d\nStatic memory %.1f MB\nLocal sandbox saves use this browser only." % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0]))
		"Connect":
			menu.add_child(_label("Optional separate server · offline save stays separate\nLocal: ws://127.0.0.1:8765/ws · Remote: wss://your-host/ws"))
			var address := LineEdit.new()
			address.text = "ws://127.0.0.1:8765/ws"
			menu.add_child(address)
			_button("Connect", func(): network.connect_server(address.text); _close_panel(), menu)
		"GM": _gm()
		"Death":
			menu.add_child(_label("You have fallen. Auto Sanctuary revive in 30 seconds."))
			_button("Sanctuary · lose 2% EXP, no level down", func(): _revive(), menu)
			_button("Revive here · requires crystal", func(): _revive(true), menu)

func _bag_status_text() -> String:
	var gender_text := "ชาย" if GameState.gender == "Male" else "หญิง"
	var element_text := "ยังไม่เลือก" if GameState.selected_element.is_empty() else GameState.selected_element
	var faction_text := "ไม่มีฝ่าย" if GameState.faction.is_empty() else GameState.faction
	return "%s  •  คลาส %d / เลเวล %d\nโจมตี %d   ป้องกัน %d   สูง %.2f ม.\nธาตุ %s   ฝ่าย %s" % [gender_text, GameState.class_rank, GameState.level, GameState.attack_power(), GameState.defense(), GameState.height_meters(), element_text, faction_text]

func _bag_bar(parent: VBoxContainer, color: Color, current: float, maximum: float, title: String) -> void:
	var bar := _bar(parent, color)
	bar.custom_minimum_size = Vector2(184, 18)
	bar.max_value = maxf(1.0, maximum)
	bar.value = current
	bar.get_node("Value").text = "%s  %d / %d" % [title, int(current), int(maximum)]
	bag_status_bars.append(bar)

# Raised navy surface with reflective silver edge and deep shadow.
func _silver_panel_style(radius: int = 10, surface: Color = Color("0b1c34f6")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = surface
	style.border_color = Color("b6c9df")
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.set_corner_radius_all(radius)
	style.shadow_color = Color("020714c8")
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _equipment_slot_style(accent: Color, active: bool, hovered: bool = false) -> StyleBoxFlat:
	var bg := Color("1e3c5f") if hovered else (Color("1a3456") if active else Color("10243e"))
	var style := _silver_panel_style(7, bg)
	style.border_color = accent.lightened(0.18) if hovered else accent
	style.shadow_color = Color("020714b5")
	style.shadow_size = 3 if hovered else 2
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 1
	style.content_margin_right = 1
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style

func _bag_equipment_slot(slot_id: String, title: String, region: String, parent: Container, accent: Color, slot_height: float = 38.0) -> void:
	var equipped: Dictionary = GameState.equipped.get(slot_id, {})
	var item: Dictionary = GameState.balance.items.get(str(equipped.get("id", "")), {})
	var filled := not equipped.is_empty()
	var text_value := title + ("\n◆" if filled else "\n·")
	var button := _button(text_value, func(): _bag_equipment_clicked(slot_id), parent)
	button.name = "Equip_" + slot_id
	button.set_meta("equip_slot_id", slot_id)
	button.set_meta("equip_region", region)
	button.set_meta("leo_fantasy_skin", true)
	button.custom_minimum_size = Vector2(34, slot_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 9)
	button.add_theme_color_override("font_color", Color("ecf3ff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _equipment_slot_style(accent, filled))
	button.add_theme_stylebox_override("hover", _equipment_slot_style(accent, filled, true))
	button.add_theme_stylebox_override("pressed", _equipment_slot_style(Color("ecf4ff"), filled, true))
	button.add_theme_stylebox_override("focus", _equipment_slot_style(Color("e6ecf5"), filled, true))
	button.tooltip_text = ("%s — แตะเพื่อเลือกไอเทมจากกระเป๋า" % title) if not filled else ("%s: %s — แตะเพื่อถอด" % [title, str(item.get("name", equipped.get("id", "")))])
	bag_equipment_buttons.append(button)
	bag_slot_regions[slot_id] = region

func _bag_equipment_clicked(slot_id: String) -> void:
	if slot_id in GameState.equipped:
		_bag_unequip(slot_id)
		return
	for index in range(GameState.inventory.size()):
		var slot: Dictionary = GameState.inventory[index]
		var item: Dictionary = GameState.balance.items.get(str(slot.get("id", "")), {})
		if str(item.get("slot", "")) == slot_id:
			_item_menu(index)
			return
	_tell("ยังไม่มีไอเทมสำหรับช่องนี้ในกระเป๋า")

func _bag_unequip(slot_id: String) -> void:
	if GameState.unequip(slot_id):
		_close_panel()
		_show_panel("Bag")
	else:
		_tell("ถอดอุปกรณ์ไม่ได้: กรุณาตรวจช่องกระเป๋า")

func _bag() -> void:
	bag_status_bars.clear()
	if not bag_bulk_mode:
		bag_bulk_selection.clear()
	bag_equipment_buttons.clear()
	bag_slot_regions.clear()
	var portrait_bag := world.get_viewport().get_visible_rect().size.y > world.get_viewport().get_visible_rect().size.x
	var wide := panel.size.x >= 550.0 and not portrait_bag
	var panes: BoxContainer = HBoxContainer.new() if wide else VBoxContainer.new()
	panes.name = "BagTwoPane"
	panes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panes.add_theme_constant_override("separation", 7)
	panes.custom_minimum_size.y = maxf(170.0, panel.size.y - 125.0)
	menu.add_child(panes)

	# Green area: status and supported equipment slots, always visible
	# while scrolling the inventory separately on the right.
	bag_character_panel = PanelContainer.new()
	bag_character_panel.name = "CharacterAndEquipment"
	bag_character_panel.set_meta("leo_fantasy_skin", true)
	bag_character_panel.add_theme_stylebox_override("panel", _silver_panel_style(10, Color("122944f8")))
	bag_character_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_character_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if wide: bag_character_panel.custom_minimum_size.x = 230
	panes.add_child(bag_character_panel)
	var character_scroll := ScrollContainer.new()
	character_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	character_scroll.custom_minimum_size.y = 220.0 if not wide else maxf(160.0, panel.size.y - 135.0)
	bag_character_panel.add_child(character_scroll)
	var character := VBoxContainer.new()
	character.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character.add_theme_constant_override("separation", 3)
	character_scroll.add_child(character)
	character.add_child(_label("สเตตัสตัวละคร", 14))
	bag_status_label = _label(_bag_status_text(), 12)
	bag_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character.add_child(bag_status_label)
	_bag_bar(character, Color("d65b68"), float(GameState.hp), float(GameState.max_hp), "HP")
	_bag_bar(character, Color("e6c85d"), GameState.stamina, float(GameState.max_stamina), "พลังงาน")
	_bag_bar(character, Color("518fdb"), float(GameState.exp), float(GameState.exp_required()), "EXP")
	# Exact positional mapping from the reference markup:
	# left weapons / mount / loot pet, center player, right five armor items.
	character.add_child(_label("ตัวละครและอุปกรณ์", 14))
	bag_equipment_frame = HBoxContainer.new()
	bag_equipment_frame.name = "EquipmentAroundAvatar"
	bag_equipment_frame.add_theme_constant_override("separation", 3)
	bag_equipment_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character.add_child(bag_equipment_frame)
	var equipment_left := VBoxContainer.new()
	equipment_left.name = "EquipmentLeft"
	equipment_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_left.add_theme_constant_override("separation", 5)
	bag_equipment_frame.add_child(equipment_left)
	_bag_equipment_slot("weapon", "มือขวา", "weapon", equipment_left, Color("bcbba6"), 42.0)
	_bag_equipment_slot("weapon_left", "มือซ้าย", "weapon", equipment_left, Color("bcbba6"), 42.0)
	var left_gap := Control.new()
	left_gap.custom_minimum_size.y = 10
	equipment_left.add_child(left_gap)
	_bag_equipment_slot("mount", "สัตว์ขี่", "mount", equipment_left, Color("c4aac9"), 43.0)
	_bag_equipment_slot("loot_pet", "เก็บของ", "pet", equipment_left, Color("95c6ba"), 43.0)
	_build_bag_avatar_preview(bag_equipment_frame)
	var equipment_right := VBoxContainer.new()
	equipment_right.name = "EquipmentRight"
	equipment_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_right.add_theme_constant_override("separation", 3)
	bag_equipment_frame.add_child(equipment_right)
	for slot_def in [
		{"id":"hat","title":"หมวก"},
		{"id":"shirt","title":"เสื้อ"},
		{"id":"gloves","title":"ถุงมือ"},
		{"id":"pants","title":"กางเกง"},
		{"id":"shoes","title":"รองเท้า"}
	]:
		_bag_equipment_slot(str(slot_def.id), str(slot_def.title), "armor", equipment_right, Color("bac9da"), 39.0)

	# Silver jewelry row, left-to-right: ring / bracelet / necklace / bracelet / ring.
	character.add_child(_label("เครื่องประดับ", 13))
	var jewelry_row := HBoxContainer.new()
	jewelry_row.name = "JewelryRow"
	jewelry_row.add_theme_constant_override("separation", 3)
	jewelry_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character.add_child(jewelry_row)
	for slot_def in [
		{"id":"ring","title":"แหวน\nซ้าย"},
		{"id":"bracelet_left","title":"กำไล\nซ้าย"},
		{"id":"accessory","title":"สร้อย"},
		{"id":"bracelet_right","title":"กำไล\nขวา"},
		{"id":"ring_right","title":"แหวน\nขวา"}
	]:
		_bag_equipment_slot(str(slot_def.id), str(slot_def.title), "jewelry", jewelry_row, Color("d4deea"), 38.0)

	# Five isolated cosmetic slots. Cosmetics never replace functional armor.
	character.add_child(_label("ชุดแฟชั่น", 13))
	var fashion_row := HBoxContainer.new()
	fashion_row.name = "FashionRow"
	fashion_row.add_theme_constant_override("separation", 3)
	fashion_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character.add_child(fashion_row)
	for slot_def in [
		{"id":"fashion_hat","title":"หมวก"},
		{"id":"fashion_shirt","title":"เสื้อ"},
		{"id":"fashion_gloves","title":"ถุงมือ"},
		{"id":"fashion_pants","title":"กางเกง"},
		{"id":"fashion_shoes","title":"รองเท้า"}
	]:
		_bag_equipment_slot(str(slot_def.id), str(slot_def.title), "fashion", fashion_row, Color("829fda"), 40.0)

	# Red area: smaller inventory cells with independent vertical scrolling.
	bag_inventory_panel = PanelContainer.new()
	bag_inventory_panel.name = "InventoryRight"
	bag_inventory_panel.set_meta("leo_fantasy_skin", true)
	bag_inventory_panel.add_theme_stylebox_override("panel", _silver_panel_style(10, Color("122944f8")))
	bag_inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_inventory_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if wide: bag_inventory_panel.custom_minimum_size.x = 275
	panes.add_child(bag_inventory_panel)
	var inventory_column := VBoxContainer.new()
	inventory_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_column.add_theme_constant_override("separation", 3)
	bag_inventory_panel.add_child(inventory_column)
	inventory_column.add_child(_label("กระเป๋า • %d / 200" % GameState.inventory.size(), 16))
	inventory_column.add_child(_label("ทอง %d  แคช %d  หน้า %d/2" % [GameState.gold, GameState.cash, bag_page + 1], 12))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 4)
	inventory_column.add_child(actions)
	var first_page := _button("◀ 1", func(): bag_page = 0; _close_panel(); _show_panel("Bag"), actions)
	var second_page := _button("2 ▶", func(): bag_page = 1; _close_panel(); _show_panel("Bag"), actions)
	var sort_button := _button("จัดเรียง", func(): bag_bulk_selection.clear(); GameState.inventory.sort_custom(func(a,b): return str(a.id) < str(b.id)); _close_panel(); _show_panel("Bag"), actions)
	for button in [first_page, second_page, sort_button]:
		button.custom_minimum_size = Vector2(60, 32)
		button.add_theme_font_size_override("font_size", 12)
	# The selection row is separate to avoid crowding the five-column grid.
	var bulk_actions := HBoxContainer.new()
	bulk_actions.name = "BulkSellActions"
	bulk_actions.add_theme_constant_override("separation", 4)
	inventory_column.add_child(bulk_actions)
	var toggle_bulk := _button("ปิดเลือก" if bag_bulk_mode else "เลือกหลายชิ้น", func(): _toggle_bulk_mode(), bulk_actions)
	toggle_bulk.name = "BulkSelectionToggle"
	toggle_bulk.custom_minimum_size = Vector2(98, 32)
	var selected_count := bag_bulk_selection.size()
	var bulk_sell := _button("ขายที่เลือก (%d)" % selected_count, func(): _bag_bulk_confirm_open(), bulk_actions)
	bulk_sell.name = "BulkSaleButton"
	bulk_sell.custom_minimum_size = Vector2(123, 32)
	bulk_sell.disabled = not bag_bulk_mode or selected_count == 0
	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.name = "BagSlotsScroll"
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_scroll.custom_minimum_size.y = maxf(125.0, panel.size.y - 220.0) if wide else 205.0
	inventory_column.add_child(inventory_scroll)
	bag_slot_grid = GridContainer.new()
	bag_slot_grid.name = "InventorySlots"
	bag_slot_grid.columns = 5 if wide else clampi(int((panel.size.x - 50.0) / 54.0), 2, 5)
	bag_slot_grid.add_theme_constant_override("h_separation", 4)
	bag_slot_grid.add_theme_constant_override("v_separation", 4)
	inventory_scroll.add_child(bag_slot_grid)
	for offset in range(100):
		var index := bag_page * 100 + offset
		var slot_text := "·"
		var item_tip := "ช่องว่าง %d" % (index + 1)
		if index < GameState.inventory.size():
			var slot: Dictionary = GameState.inventory[index]
			var item: Dictionary = GameState.balance.items.get(slot.id, {})
			slot_text = "%s\nx%d" % [str(item.get("icon", "◆")), int(slot.count)]
			item_tip = "%s ×%d" % [str(item.get("name", slot.id)), int(slot.count)]
		if bag_bulk_mode and bag_bulk_selection.has(index):
			slot_text = "✓ " + slot_text
		var button := _button(slot_text, func():
			if bag_bulk_mode:
				_toggle_bulk_item(index)
			else:
				_item_menu(index)
		, bag_slot_grid)
		button.name = "InventorySlot%d" % index
		button.custom_minimum_size = Vector2(47, 46)
		button.tooltip_text = item_tip
		button.add_theme_font_size_override("font_size", 12)
		button.set_meta("leo_fantasy_skin", true)
		button.add_theme_stylebox_override("normal", _equipment_slot_style(Color("7693b2"), index < GameState.inventory.size()))
		button.add_theme_stylebox_override("hover", _equipment_slot_style(Color("b8cde6"), true, true))
		button.add_theme_stylebox_override("pressed", _equipment_slot_style(Color("dbe8f7"), true, true))
	# On tall phones, show actual inventory items first. Equipment remains
	# below the grid, accessible by the outer menu's vertical scrolling.
	if portrait_bag:
		panes.move_child(bag_inventory_panel, 0)

func _toggle_bulk_mode() -> void:
	bag_bulk_mode = not bag_bulk_mode
	bag_bulk_selection.clear()
	_close_panel()
	_show_panel("Bag")

func _toggle_bulk_item(index: int) -> void:
	if not bag_bulk_mode or index < 0 or index >= GameState.inventory.size():
		return
	if bag_bulk_selection.has(index):
		bag_bulk_selection.erase(index)
	else:
		bag_bulk_selection[index] = int(GameState.inventory[index].count)
	_close_panel()
	_show_panel("Bag")

func _bag_bulk_confirm_open() -> void:
	if bag_bulk_selection.is_empty():
		_tell("เลือกไอเทมที่จะขายก่อน")
		return
	_show_panel("BulkSellConfirm")

func _bag_bulk_confirm() -> void:
	var total := 0
	var names: Array[String] = []
	for key in bag_bulk_selection:
		var index: int = int(key)
		if index < 0 or index >= GameState.inventory.size():
			_tell("กระเป๋าเปลี่ยนแล้ว กรุณาเลือกใหม่")
			bag_bulk_selection.clear()
			_close_panel()
			return
		var stack: Dictionary = GameState.inventory[index]
		var amount: int = int(bag_bulk_selection[key])
		var definition: Dictionary = GameState.balance.items.get(str(stack.id), {})
		total += int(definition.get("sell", 0)) * amount
		names.append("%s ×%d" % [str(definition.get("name", stack.id)), amount])
	menu.add_child(_label("ขายไอเทมที่เลือก %d ช่อง\n%s\nรับเงินรวม %d Gold" % [bag_bulk_selection.size(), "\n".join(names), total], 14))
	_button("ยืนยันขายทั้งหมด", func():
		var amount: int = GameState.sell_many(bag_bulk_selection)
		if amount >= 0:
			_tell("ขายสำเร็จ ได้รับ %d Gold" % amount)
			bag_bulk_mode = false
			bag_bulk_selection.clear()
		else:
			_tell("ขายไม่สำเร็จ กระเป๋าอาจเปลี่ยนแล้ว")
		_close_panel()
		_show_panel("Bag")
	, menu)
	_button("กลับไปกระเป๋า", func(): _close_panel(); _show_panel("Bag"), menu)

func _item_menu(index: int) -> void:
	if index >= GameState.inventory.size():
		return
	selected_item = index
	_show_panel("Item")
	var slot: Dictionary = GameState.inventory[index]
	menu.add_child(_label(str(GameState.balance.items[slot.id].name) + " +%d" % int(slot.enhancement)))
	quantity = SpinBox.new()
	quantity.min_value = 1
	quantity.max_value = int(slot.count)
	quantity.value = 1
	menu.add_child(quantity)
	_button("ใช้ / สวมใส่", func():
		var result := GameState.use_item(selected_item)
		_tell(result)
		if result == "warp": _warp(0)
		_close_panel(), menu)
	_button("ขายตามจำนวน", func(): GameState.sell(selected_item, int(quantity.value)); _close_panel(); _show_panel("Bag"), menu)
	_button("ทิ้งตามจำนวน", func(): GameState.remove_item(selected_item, int(quantity.value)); _close_panel(); _show_panel("Bag"), menu)

func _shop(is_cash: bool) -> void:
	_button("ร้านค้า NPC" if is_cash else "ร้านค้าแคช (ทดสอบ)", func(): _show_panel("Shop" if is_cash else "Cash"), menu)
	menu.add_child(_label("Gold %d · Cash %d" % [GameState.gold, GameState.cash]))
	for id in GameState.balance.items:
		var item: Dictionary = GameState.balance.items[id]
		if bool(item.get("cash", false)) != is_cash:
			continue
		_button("%s  %s · %d %s" % [item.icon, item.name, int(item.price), "Cash" if is_cash else "Gold"], func(): _tell("Purchased " + str(item.name) if GameState.buy(id) else "Insufficient currency or bag space"), menu)

func _status() -> void:
	menu.add_child(_label("%s · %.2fm\nClass %d · Level %d · EXP %d / %d\nATK %d · DEF %d · CRIT 12%%\nPath: %s · Profession: %s\nElement: %s · Faction: %s" % [GameState.gender, GameState.height_meters(), GameState.class_rank, GameState.level, GameState.exp, GameState.exp_required(), GameState.attack_power(), GameState.defense(), GameState.selected_path, GameState.selected_job, GameState.selected_element, GameState.faction]))
	_button("Switch Male / Female", func(): GameState.gender = "Female" if GameState.gender == "Male" else "Male"; _build_avatar(); _close_panel(); _show_panel("Status"), menu)
	for slot in GameState.equipped.keys():
		_button("Unequip " + str(slot), func(): GameState.unequip(slot); _close_panel(); _show_panel("Status"), menu)
		_button("Enhance " + str(slot) + " · 50 Gold + ore (test balance)", func(): _tell("Enhanced" if GameState.enhance(slot) else "Need ore / Gold, or max +10"), menu)
	for element in GameState.ELEMENTS:
		_button("Element: " + str(element), func(): _tell("Element selected" if GameState.select_element(element) else "Requires Class 3"), menu)
	for definition in GameState.balance.professions:
		if definition.element == GameState.selected_element:
			_button("Class 5 · " + str(definition.name) + " / " + str(definition.weapon), func(): _tell("Profession selected" if GameState.select_job(definition.id) else "Requires Class 5 and matching element"), menu)
	for faction in ["Light", "Dark"]:
		_button("Class 7 faction: " + faction, func(): _tell("Faction selected" if GameState.select_faction(faction) else "Requires Class 7"), menu)
	_button("Class 7 · AoE / Target", func():
		if GameState.class_rank >= 7:
			GameState.skill_mode = "AoE" if GameState.skill_mode == "Target" else "Target"
			_tell("Skill mode: " + GameState.skill_mode), menu)
	menu.add_child(_label("12 professions configured. Element advantage table awaits confirmed design.\nCurrent art: procedural stand-ins, no imported user skeleton."))

func _warp(index: int) -> void:
	GameState.map_index = index
	for child in world.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh and child.mesh.size.x == 80:
			child.material_override = world._material(Color(str(GameState.balance.maps[index].color)))
	world.player.position = Vector3(0, 1.1, 0)
	world.auto_destination = Vector3.INF
	auto_attack = false
	auto_hunt = false
	_build_zone()
	_tell("Entered " + str(GameState.balance.maps[index].name) + " · prototype zone")
	_close_panel()
	_save()

func _gm() -> void:
	if not _can_use_gm() or network.active or network.connecting: return
	menu.add_child(_label("GM · เลือกตัวละคร / อาชีพ / ฝ่าย",20))
	menu.add_child(_label("โหมดทดสอบออฟไลน์: ผู้เข้าชมเว็บนี้ทุกคนสามารถใช้ GM ได้\nไม่มีผลต่อเซิร์ฟเวอร์เกมออนไลน์", 13))
	menu.add_child(_label("เลือกอาชีพ: Class ขั้นต่ำ 5 · เลือกฝ่าย: Class ขั้นต่ำ 7",14))
	gm_summary = _label("")
	menu.add_child(gm_summary)
	_gm_choice_row("เพศ",[{"id":"Male","name":"ชาย / Male"},{"id":"Female","name":"หญิง / Female"}],GameState.gender,"gender")
	var jobs: Array = [{"id":"","name":"Novice / เริ่มต้น"}]
	for job in GameState.balance.professions:
		jobs.append({"id":job.id,"name":str(job.name)+" · "+str(job.element)})
	_gm_choice_row("อาชีพ",jobs,GameState.selected_job,"job")
	_gm_choice_row("ฝ่าย",[{"id":"","name":"ไม่มีฝ่าย"},{"id":"Light","name":"Light / แสง"},{"id":"Dark","name":"Dark / มืด"}],GameState.faction,"faction")
	_gm_update_summary()
	menu.add_child(_label("OFFLINE TEST TOOLS · no production server connection"))
	_button("+1 Level", func(): GameState.add_exp(GameState.exp_required()), menu)
	_button("+1 Class (test override)", func(): GameState.class_rank = mini(10, GameState.class_rank + 1); GameState.level = 1; GameState._recalculate_stats(); _build_avatar(), menu)
	_button("Level 100", func(): GameState.level = 100; GameState._recalculate_stats(); _build_avatar(), menu)
	_button("+1000 Gold / +100 Cash", func(): GameState.gold += 1000; GameState.cash += 100, menu)
	_button("Spawn Elite", func(): _spawn_mob(mobs.size(), "Elite"), menu)
	_button("Spawn Boss", func(): _spawn_mob(mobs.size(), "Boss"), menu)
	_button("Kill target", func():
		if target >= 0: mobs[target].hp = 0; _killed(target), menu)
	_button("Kill self", func(): GameState.hp = 0; _close_panel(), menu)
	_button("Revive", func(): _revive(), menu)
	_button("Add test items", func():
		for id in GameState.balance.items: GameState.add_item(id)
		_tell("Test items added"), menu)
	_button("Toggle flight (hold Space to rise)", func(): world.fly_enabled = not world.fly_enabled; _close_panel(), menu)
	_button("Reset hunt quest", func(): GameState.quest_state = "available"; GameState.quest_kills = 0, menu)

func _skills_panel() -> void:
	menu.add_child(_label("ขั้นแรก / Initial · available skills\nจอมจ้าว / Sovereign · unlock rule not yet specified"))
	if GameState.class_rank < 3:
		menu.add_child(_label("Novice training skills · choose an element at Class 3"))
	elif GameState.class_rank < 5:
		menu.add_child(_label("Class 3–4 · freely assign skills within your element"))
		if not GameState.selected_element.is_empty():
			for slot in range(3):
				for source in range(3):
					var a := slot
					var b := source
					_button("Slot %d ← %s" % [slot + 1, GameState.balance.element_skills[GameState.selected_element][source].name], func(): GameState.set_skill_slot(a,b); _tell("Loadout updated"), menu)
	else:
		menu.add_child(_label("Class 5+ · loadout fixed by profession"))
	for i in range(1,4):
		menu.add_child(_label("%d · %s · %.0f Stamina / %.1fs" % [i, GameState.skill_definition(i).name, GameState.skill_definition(i).cost, GameState.skill_definition(i).cooldown]))

func _online_tick(delta: float) -> void:
	animation_time += delta
	if (auto_attack or auto_hunt) and target >= 0:
		_online_attack(pending_skill)
	if target >= 0 and int(mobs[target].hp) <= 0:
		target = -1
		world.auto_destination = Vector3.INF
	if auto_hunt and target < 0: _select_target()
	for i in range(limbs.size()):
		limbs[i].rotation.x = sin(animation_time * 9 + (PI if i % 2 else 0)) * minf(0.55, Vector2(world.player.velocity.x,world.player.velocity.z).length() * 0.09)
	if GameState.hp <= 0:
		world.auto_destination = Vector3.INF
		auto_hunt = false
		auto_attack = false
		if not panel.visible: _show_panel("Death")
	pet.visible = false
	_refresh_hud()
	stats_label.text = "ONLINE · Class %d / Lv.%d" % [GameState.class_rank,GameState.level]

func _online_attack(index: int) -> void:
	if target < 0 or not network.have_snapshot: return
	var skill: Dictionary = GameState.skill_definition(index)
	var reach: float = skill.range
	var job: Dictionary = GameState.job_definition()
	if index == 0 and not job.is_empty():reach = float(job.range)
	if world.player.position.distance_to(mobs[target].node.position) > reach:
		world.auto_destination = mobs[target].node.position
		return
	world.auto_destination = Vector3.INF
	if network.action_timer <= 0:
		network.command("attack",{"target":target,"skill":index})
		network.action_timer = float(skill.cooldown)
		pending_skill = 0

func _online_panel(name: String) -> void:
	match name:
		"Death":
			_button("Server: revive at sanctuary", func(): network.command("revive"); _close_panel(), menu)
		"Bag":
			for i in range(GameState.inventory.size()):
				var index := i
				var slot: Dictionary = GameState.inventory[i]
				menu.add_child(_label("%s x%d" % [GameState.balance.items[slot.id].name,int(slot.count)]))
				_button("ใช้ / สวมใส่", func(): network.command("equip" if GameState.balance.items[GameState.inventory[index].id].kind == "equipment" else "use",{"slot":index}), menu)
				_button("Sell one", func(): network.command("sell",{"slot":index,"count":1}), menu)
		"Shop":
			for id in GameState.balance.items:
				if not GameState.balance.items[id].get("cash",false):
					_button("Buy " + str(GameState.balance.items[id].name), func(): network.command("buy",{"item":id,"count":1}), menu)
		"Quest":
			_button("AUTO TO NPC", func(): world.auto_destination = npc.position; _close_panel(), menu)
			_button("Server: accept / turn in", func(): network.command("quest"), menu)
			_button("Server: advance Class", func(): network.command("advance"), menu)
		"Skills":
			if GameState.class_rank >= 3 and GameState.class_rank < 5:
				for slot in range(3):
					for source in range(3):
						var a := slot
						var b := source
						_button("Slot %d ← skill %d" % [slot+1,source+1], func(): network.command("skill",{"slot":a,"source":b}), menu)
			else:
				menu.add_child(_label("Class 5+ skills fixed by profession. Sovereign unlock pending design."))
		"Settings":
			_button("เจ้าของ: ยืนยันสิทธิ์ GM", func(): _show_panel("OwnerLogin"), menu)
			_button("ออกจากเซิร์ฟเวอร์", func(): network.disconnect_server(); _close_panel(), menu)
		"GM":
			menu.add_child(_label("ยืนยันสิทธิ์ GM สำเร็จ แต่คำสั่งเปลี่ยนข้อมูลออนไลน์ยังถูกปิดจนกว่าจะเปิดระบบสิทธิ์คำสั่งบนเซิร์ฟเวอร์"))
		"Status":
			for element in GameState.ELEMENTS:
				_button("Class 3: " + element, func(): network.command("element",{"value":element}), menu)
			for job in GameState.balance.professions:
				if job.element == GameState.selected_element:
					_button("Class 5: " + str(job.name), func(): network.command("job",{"value":job.id}), menu)
			for faction in ["Light","Dark"]:
				_button("Class 7: " + faction, func(): network.command("faction",{"value":faction}), menu)
		_:
			menu.add_child(_label("Online test supports shared movement, PvE, inventory, shop, quests, chat, party rooms.\nOther offline features remain separate; production GM is disabled."))
			var field := LineEdit.new()
			field.placeholder_text = "Chat message / party room code"
			menu.add_child(field)
			_button("Send chat", func(): network.command("chat",{"text":field.text}), menu)
			_button("Join party room", func(): network.command("party",{"code":field.text}), menu)
			_button("Disconnect · return offline", func(): network.disconnect_server(); _close_panel(), menu)

func _set_ui_scale(value: float) -> void:
	GameState.settings.ui_scale = clampf(value, 0.85, 1.20)
	_layout()
	world._layout_touch_ui()
	_save()
	_tell("ปรับขนาด UI เป็น %d%%" % int(GameState.settings.ui_scale * 100.0))

func _set_shadows(enabled: bool) -> void:
	for child in world.get_children():
		if child is DirectionalLight3D: child.shadow_enabled = enabled

func pointer_over_ui(point: Vector2) -> bool:
	# Popup windows can extend beyond their parent panel; reserve pointer input until dismissed.
	for chooser in gm_choosers.values():
		if is_instance_valid(chooser) and chooser.get_popup().visible: return true
	if panel.visible and panel.get_global_rect().has_point(point): return true
	if is_instance_valid(player_dropdown) and player_dropdown.visible: return true
	for button in buttons + skill_buttons + [world.jump_button, world.run_button]:
		if button.is_visible_in_tree() and button.get_global_rect().has_point(point): return true
	return false

func _gm_choice_row(title: String, options: Array, current: String, kind: String) -> void:
	var row := HBoxContainer.new()
	menu.add_child(row)
	var label := _label(title)
	label.custom_minimum_size.x = 70
	row.add_child(label)
	var chooser := OptionButton.new()
	chooser.custom_minimum_size = Vector2(190,42)
	chooser.fit_to_longest_item = false
	chooser.clip_text = true
	chooser.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option in options:
		chooser.add_item(str(option.name))
		var index := chooser.item_count - 1
		chooser.set_item_metadata(index,option.id)
		if option.id == current: chooser.select(index)
	row.add_child(chooser)
	gm_choosers[kind] = chooser
	chooser.item_selected.connect(func(index):
		if not _gm_select(kind,str(chooser.get_item_metadata(index))):
			_tell("เปลี่ยนไม่ได้: กรุณาตรวจพื้นที่กระเป๋าหรือการเชื่อมต่อเซิร์ฟเวอร์")
			var actual: String = GameState.gender if kind == "gender" else (GameState.selected_job if kind == "job" else GameState.faction)
			for i in range(chooser.item_count):
				if str(chooser.get_item_metadata(i)) == actual: chooser.select(i)
	)

func _gm_update_summary() -> void:
	if is_instance_valid(gm_summary):
		var job: Dictionary = GameState.job_definition()
		gm_summary.text = "%s · %s · %s · Class %d" % ["ชาย" if GameState.gender == "Male" else "หญิง",str(job.get("name","Novice")),GameState.faction if not GameState.faction.is_empty() else "ไม่มีฝ่าย",GameState.class_rank]

func _gm_select(kind: String, value: String, persist := true) -> bool:
	if not _can_use_gm() or network.active or network.connecting: return false
	match kind:
		"gender":
			if value not in ["Male","Female"]: return false
			GameState.gender = value
		"job":
			var definition: Dictionary = GameState.job_definition(value)
			if not value.is_empty() and definition.is_empty(): return false
			var old: Dictionary = GameState.equipped.get("weapon",{})
			# Preserve actual equipment once; replacing GM previews never grants extra items.
			if not old.is_empty() and not old.get("gm_preview",false):
				if GameState.inventory.size() >= 200: return false
				GameState.inventory.append(old.duplicate(true))
			GameState.selected_job = value
			GameState.selected_element = str(definition.get("element",""))
			GameState.selected_path = GameState.selected_element
			GameState.equipped.weapon = {"id":definition.get("weapon","sword"),"count":1,"enhancement":0,"gm_preview":true}
			if not value.is_empty(): GameState.class_rank = maxi(5,GameState.class_rank)
			pending_skill = 0
			cooldowns = [0.0,0.0,0.0,0.0]
		"faction":
			if value not in ["","Light","Dark"]: return false
			GameState.faction = value
			if not value.is_empty(): GameState.class_rank = maxi(7,GameState.class_rank)
		_: return false
	GameState._recalculate_stats(false)
	GameState.appearance_changed.emit()
	_gm_update_summary()
	_refresh_hud()
	if persist: _save()
	_tell("GM: เปลี่ยน " + kind + " แล้ว")
	return true
