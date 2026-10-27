extends Node
## Playable offline systems; procedural art is explicitly temporary.
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
var limbs: Array[Node3D] = []
var weapon: Node3D
var stats_label: Label
var quest_label: Label
var target_label: Label
var notice: Label
var hp_bar: ProgressBar
var stamina_bar: ProgressBar
var exp_bar: ProgressBar
var map_display: Control
var panel: PanelContainer
var menu: VBoxContainer
var buttons: Array[Button] = []
var skill_buttons: Array[Button] = []
var active_panel := ""
var bag_page := 0
var bag_character_panel: PanelContainer
var bag_inventory_panel: PanelContainer
var bag_equipment_grid: GridContainer
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
	GameState.appearance_changed.connect(_build_avatar)
	GameState.progression_changed.connect(_build_avatar)
	var saved: Array = GameState.location
	if saved.size() == 3:
		world.player.position = Vector3(float(saved[0]), maxf(1, float(saved[1])), float(saved[2]))
	_tell("Welcome. Talk to Warden Elara to accept Starter Hunt. TAB selects a target.")

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
	if "shirt" in GameState.equipped:
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
		_mesh(leg, Vector3(0, -0.31, 0), Vector3(0.21, 0.60, 0.23), Color("3c4657") if "pants" not in GameState.equipped else Color("335a70"))
		_mesh(leg, Vector3(0, -0.66, -0.06), Vector3(0.23, 0.17, 0.34), Color("3c2f2b") if "shoes" not in GameState.equipped else Color("91724c"))
		limbs.append(leg)
	for x in [-0.36, 0.36]:
		var arm := Node3D.new()
		arm.position = Vector3(x, 1.35, 0)
		avatar.add_child(arm)
		_mesh(arm, Vector3(0, -0.23, 0), Vector3(0.17, 0.49, 0.2), cloth)
		_mesh(arm, Vector3(0, -0.52, 0), Vector3(0.17, 0.18, 0.18), skin if "gloves" not in GameState.equipped else Color("855b38"))
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
	if "hat" in GameState.equipped:
		_mesh(avatar, Vector3(0, 1.88, -0.07), Vector3(0.48, 0.23, 0.28), Color("c1a258"), "cone")
	if "accessory" in GameState.equipped:
		_mesh(avatar, Vector3(0, 1.28, -0.16), Vector3.ONE * 0.09, Color("f4d36c"), "sphere")

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
	target = -1

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

func _build_ui() -> void:
	var theme := Theme.new()
	var font: FontFile = load("res://assets/fonts/NotoSansThai.ttf")
	font.fallbacks = [ThemeDB.fallback_font]
	theme.default_font = font
	world.hud.theme = theme
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.position = Vector2(14, 64)
	plate.size = Vector2(305, 134)
	plate.add_theme_stylebox_override("panel", _style(Color("142436dd"), Color("9c9276")))
	world.hud.add_child(plate)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(stack)
	stats_label = _label("", 18)
	stack.add_child(stats_label)
	hp_bar = _bar(stack, Color("d65b68"))
	stamina_bar = _bar(stack, Color("e6c85d"))
	exp_bar = _bar(stack, Color("518fdb"))
	quest_label = _label("", 15)
	quest_label.position = Vector2(18, 205)
	world.hud.add_child(quest_label)
	target_label = _label("TAB / LOCK to select target", 19)
	target_label.position = Vector2(450, 68)
	world.hud.add_child(target_label)
	notice = _label("", 16)
	notice.position = Vector2(330, 115)
	notice.size = Vector2(600, 75)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	world.hud.add_child(notice)
	var names := ["Bag [B]", "Shop [P]", "Status [C]", "Quest [Q]", "World [M]", "Pet", "Auto", "Skills", "GM"]
	for i in range(names.size()):
		var name: String = names[i].split(" ")[0]
		var button := _button(_thai_panel_name(name) + (" [" + names[i].split("[")[1] if "[" in names[i] else ""), func(): _show_panel(name))
		button.position = Vector2(18 + i % 3 * 90, 285 + int(i / 3.0) * 44)
		button.size = Vector2(86, 40)
		buttons.append(button)
	var controls := ["LOCK\n[TAB]", "PICK UP\n[E]", "ATK\n[F]", "1\nCrescent", "2\nPierce", "3\nJudgment", "DASH\n[R]", "HUNT\n[H]"]
	for i in range(controls.size()):
		var index := i
		var button := _button(controls[i], func(): _action(index))
		button.size = Vector2(90, 65)
		button.set_meta("layout_id", "action_%d" % i)
		skill_buttons.append(button)
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
	panel.add_theme_stylebox_override("panel", _style(Color("142435f5"), Color("b5a47a")))
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
	bar.add_child(value_label)
	value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return bar

func _layout() -> void:
	var size: Vector2 = world.get_viewport().get_visible_rect().size
	for i in range(skill_buttons.size()):
		var button := skill_buttons[i]
		button.position = Vector2(size.x - 330 + (i % 3) * 102, size.y - 240 + int(i / 3.0) * 73)
		var offset: Array = GameState.settings.button_offsets.get(str(button.get_meta("layout_id")), [0, 0])
		button.position += Vector2(float(offset[0]), float(offset[1]))
	map_display.position = Vector2(size.x - 175, 12)
	# Keep the world character visible to the right of the open inventory.
	# On landscape screens, the equipment and bag share a compact 2-column dock.
	# On narrow screens the panes stack and each section scrolls independently.
	panel.position = Vector2(12, 12)
	if active_panel == "Bag":
		var bag_width: float = minf(620.0, maxf(300.0, size.x * 0.44))
		# Extend to the viewport bottom while preserving the narrow left width
		# so the character remains visible in the center of the 3D world.
		var bag_height: float = maxf(160.0, size.y - 24.0)
		panel.size = Vector2(minf(bag_width, maxf(150.0, size.x - 24.0)), bag_height)
	else:
		panel.size = Vector2(minf(390.0, maxf(150.0, size.x - 24.0)), maxf(160.0, size.y - 24.0))

func _tell(text: String) -> void:
	notice.text = text

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

func _refresh_hud() -> void:
	stats_label.text = "%s  ·  Class %d / Lv.%d" % [GameState.gender, GameState.class_rank, GameState.level]
	hp_bar.max_value = GameState.max_hp
	hp_bar.value = GameState.hp
	stamina_bar.max_value = GameState.max_stamina
	stamina_bar.value = GameState.stamina
	exp_bar.max_value = GameState.exp_required()
	exp_bar.value = GameState.exp
	hp_bar.get_node("Value").text = "HP  %d / %d" % [GameState.hp, GameState.max_hp]
	stamina_bar.get_node("Value").text = "Stamina  %d / %d" % [int(GameState.stamina),GameState.max_stamina]
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
	quest_label.text = "%s\nStarter Hunt: %s  %d/5\nGold %d    Cash %d" % [GameState.balance.maps[GameState.map_index].name, GameState.quest_state, GameState.quest_kills, GameState.gold, GameState.cash]
	target_label.text = "Select target: TAB / LOCK" if target < 0 else "%s · Lv.%d · HP %d/%d" % [mobs[target].kind + " Mossling", int(mobs[target].level), int(mobs[target].hp), int(mobs[target].max_hp)]
	for i in range(4):
		var button := skill_buttons[i + 2]
		button.text = str(GameState.skill_definition(i).name) + ("\n%.1fs" % float(cooldowns[i]) if float(cooldowns[i]) > 0 else "\n[%s]" % ("F" if i == 0 else str(i)))
	var faction_color := Color("e4e5da") if GameState.faction == "Light" else Color("9a77c5")
	if GameState.class_rank >= 7 and GameState.faction in ["Light","Dark"]:
		world.joystick_base.color = Color(faction_color, 0.25)
		for button in skill_buttons:
			button.add_theme_stylebox_override("normal", _style(Color("182b40e8"),faction_color))
	else:
		world.joystick_base.color.a = 0
		for button in skill_buttons:
			button.add_theme_stylebox_override("normal", _style(Color("182b40e8"),Color("697d8f")))
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
		if active_panel == "Bag" and is_instance_valid(bag_character_panel) and is_instance_valid(bag_inventory_panel):
			bag_left_rect = bag_character_panel.get_global_rect()
			bag_right_rect = bag_inventory_panel.get_global_rect()
		var diagnostic := {"bag_left_rect":[bag_left_rect.position.x,bag_left_rect.position.y,bag_left_rect.size.x,bag_left_rect.size.y],"bag_right_rect":[bag_right_rect.position.x,bag_right_rect.position.y,bag_right_rect.size.x,bag_right_rect.size.y],"bag_columns":bag_slot_grid.columns if active_panel == "Bag" and is_instance_valid(bag_slot_grid) else 0,"drawer_rect":[panel.position.x,panel.position.y,panel.size.x,panel.size.y],"drawer_close":[close_center.x,close_center.y],"drawer_z":panel.z_index,"version":"gm-select-20261024-1","gm_controls":gm_rects,"gm_popups":gm_popups,"gender":GameState.gender,"job":GameState.selected_job,"faction":GameState.faction,"class_rank":GameState.class_rank,"screen_size":[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y],"viewport_size":[world.get_viewport().get_visible_rect().size.x,world.get_viewport().get_visible_rect().size.y],"position":[world.player.position.x,world.player.position.y,world.player.position.z],"camera_zoom":world.camera.position.z,"player_screen":[world.camera.unproject_position(world.player.position).x,world.camera.unproject_position(world.player.position).y],"yaw":world.yaw,"target":target,"hp":GameState.hp,"panel":active_panel,"mobs":mobs.size(),"fps":Engine.get_frames_per_second(),"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"online":network.active,"attacking":auto_attack,"joystick":[world.joystick_vector.x,world.joystick_vector.y]}
		JavaScriptBridge.eval("window.leoDiagnostics=" + JSON.stringify(diagnostic), true)
	map_display.queue_redraw()

func _save() -> void:
	if network.active or network.connecting: return
	var pos: Vector3 = world.player.position
	GameState.location = [pos.x, pos.y, pos.z]
	GameState.save_game()

func _input(event: InputEvent) -> void:
	# Handle each action finger independently; emulated mouse handles only one finger.
	if event is InputEventScreenTouch and event.pressed and not panel.visible:
		for i in range(skill_buttons.size()):
			if skill_buttons[i].get_global_rect().has_point(event.position):
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
				var base := Vector2(size.x - 330 + (i % 3) * 102, size.y - 240 + int(i / 3.0) * 73)
				var offset := dragging_button.position - base
				GameState.settings.button_offsets[str(dragging_button.get_meta("layout_id"))] = [offset.x, offset.y]
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

func _close_panel() -> void:
	panel.hide()
	active_panel = ""

func _thai_panel_name(name: String) -> String:
	var names := {"Bag":"กระเป๋า", "Shop":"ร้านค้า", "Cash":"ร้านค้าแคช", "Status":"ตัวละครและอุปกรณ์", "Quest":"ภารกิจ", "World":"แผนที่โลก", "Pet":"สัตว์เลี้ยง", "Auto":"ล่าอัตโนมัติ", "Skills":"ทักษะ", "GM":"ผู้ดูแลระบบ", "Settings":"ตั้งค่า", "Connect":"เชื่อมต่อ", "Death":"ฟื้นคืนชีพ", "Item":"รายละเอียดไอเทม"}
	return str(names.get(name, name))

func _show_panel(name: String) -> void:
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
	if network.active:
		_online_panel(name)
		return
	match name:
		"Bag": _bag()
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
				check.toggled.connect(func(on): hunt_skills[index] = on)
				menu.add_child(check)
			for radius in [12.0, 20.0, 36.0]:
				_button("Search radius %dm" % radius, func(): hunt_radius = radius, menu)
			_button("Start / stop Auto Hunt", func(): _action(7); _close_panel(), menu)
		"Skills":
			_skills_panel()
			_button("Settings", func(): _show_panel("Settings"), menu)
		"Settings":
			_button("Multiplayer development server", func(): _show_panel("Connect"), menu)
			_button("บันทึกเกม", func(): _save(); _tell("Offline save written"), menu)
			_button("Edit button layout: drag action buttons", func(): layout_edit = not layout_edit; _close_panel(); _tell("Layout editing " + str(layout_edit)), menu)
			_button("คืนตำแหน่งปุ่ม", func(): GameState.settings.button_offsets = {}; _layout(), menu)
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

func _bag_equipment_slot(slot_id: String, title: String) -> void:
	var equipped: Dictionary = GameState.equipped.get(slot_id, {})
	var item: Dictionary = GameState.balance.items.get(str(equipped.get("id", "")), {})
	var display_name := "ว่าง" if equipped.is_empty() else str(item.get("name", equipped.get("id", "")))
	var button := _button("%s\n%s" % [title, display_name], func(): _bag_unequip(slot_id), bag_equipment_grid)
	button.custom_minimum_size = Vector2(100, 43)
	button.add_theme_font_size_override("font_size", 11)
	button.clip_text = true
	button.tooltip_text = "กดถอดอุปกรณ์" if not equipped.is_empty() else "ยังไม่ได้สวมใส่"
	button.disabled = equipped.is_empty()

func _bag_unequip(slot_id: String) -> void:
	if GameState.unequip(slot_id):
		_close_panel()
		_show_panel("Bag")
	else:
		_tell("ถอดอุปกรณ์ไม่ได้: กรุณาตรวจช่องกระเป๋า")

func _bag() -> void:
	bag_status_bars.clear()
	var wide := panel.size.x >= 550.0
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
	character.add_theme_constant_override("separation", 4)
	character_scroll.add_child(character)
	character.add_child(_label("สเตตัสตัวละคร", 16))
	bag_status_label = _label(_bag_status_text(), 13)
	bag_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character.add_child(bag_status_label)
	_bag_bar(character, Color("d65b68"), float(GameState.hp), float(GameState.max_hp), "HP")
	_bag_bar(character, Color("e6c85d"), GameState.stamina, float(GameState.max_stamina), "พลังงาน")
	_bag_bar(character, Color("518fdb"), float(GameState.exp), float(GameState.exp_required()), "EXP")
	character.add_child(_label("อุปกรณ์สวมใส่", 16))
	bag_equipment_grid = GridContainer.new()
	bag_equipment_grid.name = "EquipmentSlots"
	bag_equipment_grid.columns = 2 if wide or panel.size.x >= 320.0 else 1
	bag_equipment_grid.add_theme_constant_override("h_separation", 4)
	bag_equipment_grid.add_theme_constant_override("v_separation", 4)
	character.add_child(bag_equipment_grid)
	for slot_def in [{"id":"weapon","title":"อาวุธ"},{"id":"hat","title":"หมวก"},{"id":"shirt","title":"เสื้อ"},{"id":"gloves","title":"ถุงมือ"},{"id":"pants","title":"กางเกง"},{"id":"shoes","title":"รองเท้า"},{"id":"ring","title":"แหวน"},{"id":"necklace","title":"สร้อย"}]:
		_bag_equipment_slot(str(slot_def.id), str(slot_def.title))
	character.add_child(_label("แตะช่องอุปกรณ์เพื่อถอด", 12))

	# Red area: smaller inventory cells with independent vertical scrolling.
	bag_inventory_panel = PanelContainer.new()
	bag_inventory_panel.name = "InventoryRight"
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
	var sort_button := _button("จัดเรียง", func(): GameState.inventory.sort_custom(func(a,b): return str(a.id) < str(b.id)); _close_panel(); _show_panel("Bag"), actions)
	for button in [first_page, second_page, sort_button]:
		button.custom_minimum_size = Vector2(60, 32)
		button.add_theme_font_size_override("font_size", 12)
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
		var button := _button(slot_text, func(): _item_menu(index), bag_slot_grid)
		button.custom_minimum_size = Vector2(47, 46)
		button.tooltip_text = item_tip
		button.add_theme_font_size_override("font_size", 12)

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
	menu.add_child(_label("GM · เลือกตัวละคร / อาชีพ / ฝ่าย",20))
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

func _set_shadows(enabled: bool) -> void:
	for child in world.get_children():
		if child is DirectionalLight3D: child.shadow_enabled = enabled

func pointer_over_ui(point: Vector2) -> bool:
	# Popup windows can extend beyond their parent panel; reserve pointer input until dismissed.
	for chooser in gm_choosers.values():
		if is_instance_valid(chooser) and chooser.get_popup().visible: return true
	if panel.visible and panel.get_global_rect().has_point(point): return true
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
	if network.active or network.connecting: return false
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
