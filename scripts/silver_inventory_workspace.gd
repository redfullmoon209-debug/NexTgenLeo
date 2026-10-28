extends Control
## A composited silver inventory window. Main and extension are independent.
## All frames use reusable 9-slice PNGs; the item/equipment slots share one PNG.
## Data and equipment actions are provided by the existing GameState/gameplay.
const ROOT := "res://assets/ui/silver/"
const MAIN_WIDTH := 1210.0
const MAIN_HEIGHT := 720.0
const EXT_WIDTH := 305.0
const SLOT_SIDE := 60.0
const MENU_ATLAS_PATH := "res://assets/ui/silver/MenuIcons_Atlas.png"
const MENU_SPECS := [
	{"id":"Status", "title":"ตัวละครและอุปกรณ์", "icon":13},
	{"id":"Bag", "title":"กระเป๋าไอเทม", "icon":3},
	{"id":"Storage", "title":"คลังเก็บของ", "icon":5},
	{"id":"Trade", "title":"เทรดซื้อขาย", "icon":11},
	{"id":"Quest", "title":"เควสต์และภารกิจ", "icon":8},
	{"id":"Shop", "title":"ร้านค้า NPC", "icon":9},
	{"id":"Cash", "title":"ร้านค้าแคช", "icon":10},
	{"id":"World", "title":"แผนที่โลก", "icon":2},
	{"id":"Pet", "title":"สัตว์เลี้ยง", "icon":0},
	{"id":"Auto", "title":"ล่าอัตโนมัติ", "icon":1},
	{"id":"Skills", "title":"ทักษะ", "icon":12},
	{"id":"Settings", "title":"ตั้งค่า", "icon":6},
	{"id":"Connect", "title":"เชื่อมต่อออนไลน์", "icon":7},
	{"id":"Guild", "title":"กิลด์", "icon":4}
]
const EQUIPMENT_KEYS := [
	{"name":"หมวก","warrior":"hat","fashion":"fashion_hat"},
	{"name":"เสื้อ","warrior":"shirt","fashion":"fashion_shirt"},
	{"name":"ถุงมือ","warrior":"gloves","fashion":"fashion_gloves"},
	{"name":"กางเกง","warrior":"pants","fashion":"fashion_pants"},
	{"name":"รองเท้า","warrior":"shoes","fashion":"fashion_shoes"},
	{"name":"มือขวา","warrior":"weapon","fashion":"fashion_weapon"},
	{"name":"มือซ้าย","warrior":"weapon_left","fashion":"fashion_weapon_left"}
]
var game: Node
var main_frame: PanelContainer
var extension_frame: PanelContainer
var extension_content: VBoxContainer
var equipment_grid: HBoxContainer
var warrior_stack: VBoxContainer
var fashion_stack: VBoxContainer
var accessory_stack: HBoxContainer
var equipment_buttons: Dictionary = {}
var accessory_buttons: Dictionary = {}
var avatar_viewport: SubViewport
var avatar_stage: Node3D
var avatar_preview_frame: PanelContainer
var nav_scroll: ScrollContainer
var _menu_atlas: Texture2D
var _menu_icons: Dictionary = {}
var item_grid: GridContainer
var inventory_scroll: ScrollContainer
var inventory_summary: Label
var page_label: Label
var stats_label: Label
var menu_buttons: Dictionary = {}
var extension_mode := ""
var page := 0
var bulk_selection: Dictionary = {}
var bulk_mode := false
var _frame_cache: Dictionary = {}

func _ready() -> void:
	name = "SilverInventoryWorkspace"
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 130
	_build()
	get_viewport().size_changed.connect(_layout)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.appearance_changed.connect(_on_appearance_changed)
	visible = false

func _frame_style(filename: String, edge: float = 15.0) -> StyleBox:
	var key := filename + ":" + str(edge)
	if _frame_cache.has(key):
		return _frame_cache[key]
	var path := ROOT + filename
	if ResourceLoader.exists(path):
		var style := StyleBoxTexture.new()
		style.texture = load(path) as Texture2D
		style.texture_margin_left = edge
		style.texture_margin_right = edge
		style.texture_margin_top = edge
		style.texture_margin_bottom = edge
		style.content_margin_left = 7
		style.content_margin_right = 7
		style.content_margin_top = 7
		style.content_margin_bottom = 7
		style.draw_center = true
		_frame_cache[key] = style
		return style
	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color(0.025, 0.035, 0.05, 0.83)
	fallback.border_color = Color("#B6BDC9")
	fallback.set_border_width_all(2)
	fallback.set_corner_radius_all(10)
	fallback.content_margin_left = 8
	fallback.content_margin_right = 8
	fallback.content_margin_top = 8
	fallback.content_margin_bottom = 8
	_frame_cache[key] = fallback
	return fallback

func _slot_style() -> StyleBox:
	return _frame_style("Equipment_Inventory_Slot.png", 10.0)

func _menu_icon(index: int) -> Texture2D:
	if _menu_icons.has(index):
		return _menu_icons[index] as Texture2D
	if _menu_atlas == null:
		if not ResourceLoader.exists(MENU_ATLAS_PATH):
			return null
		_menu_atlas = load(MENU_ATLAS_PATH) as Texture2D
	if _menu_atlas == null:
		return null
	# The 14 supplied PNG menu icons are retained in one packed 7x2 atlas:
	# each 62x62 region contains a 56x56 icon with transparent padding.
	var tile := AtlasTexture.new()
	tile.atlas = _menu_atlas
	tile.region = Rect2(float(index % 7) * 62.0, float(index / 7) * 62.0, 62.0, 62.0)
	_menu_icons[index] = tile
	return tile

func _nav_button(menu_id: String, title: String, icon_index: int, parent: Node) -> Button:
	var b := _button("", func(): _navigate(menu_id), parent, 39.0)
	b.name = "SilverNav" + menu_id
	b.custom_minimum_size.x = 226.0
	b.tooltip_text = title
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 4)
	b.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var contents := HBoxContainer.new()
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 7)
	margin.add_child(contents)
	var image := TextureRect.new()
	image.name = "MenuIcon"
	image.texture = _menu_icon(icon_index)
	image.custom_minimum_size = Vector2(31, 31)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(image)
	var caption := _label(title, 13)
	caption.name = "MenuCaption"
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(caption)
	menu_buttons[menu_id] = b
	return b

func _navigate(menu_id: String) -> void:
	if menu_id in ["Bag", "Status"]:
		_set_extension("")
		return
	_set_extension(menu_id)

func _on_appearance_changed() -> void:
	if visible:
		_refresh_equipment()
		_refresh_character_preview()


func _label(value: String, size: int = 15) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_color_override("font_color", Color("#DFE4ED"))
	result.add_theme_font_size_override("font_size", size)
	return result

func _button(text: String, action: Callable, parent: Node, height: float = 34.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", _frame_style("Menu_Panel.png", 15.0))
	button.add_theme_stylebox_override("hover", _frame_style("Menu_Panel.png", 15.0))
	button.add_theme_stylebox_override("pressed", _frame_style("Menu_Panel.png", 15.0))
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("#EBEFF6"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.set_meta("leo_fantasy_skin", true)
	parent.add_child(button)
	button.pressed.connect(action)
	return button

func _panel(parent: Node, filename: String, min_width: float = 0.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _frame_style(filename))
	p.set_meta("leo_fantasy_skin", true)
	p.custom_minimum_size.x = min_width
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(p)
	return p

func _build() -> void:
	# The backdrop prevents world clicks while manipulating item slots.
	var cover := ColorRect.new()
	cover.color = Color(0, 0, 0, 0.22)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(cover)
	main_frame = _panel(self, "Main_Base.png")
	main_frame.name = "MainBase"
	main_frame.size_flags_horizontal = 0
	main_frame.size_flags_vertical = 0
	var main_margin := MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 10)
	main_margin.add_theme_constant_override("margin_right", 10)
	main_margin.add_theme_constant_override("margin_top", 10)
	main_margin.add_theme_constant_override("margin_bottom", 10)
	main_frame.add_child(main_margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 7)
	main_margin.add_child(columns)
	# Left navigation: every original player menu plus Storage, Trade, Guild,
	# Cash, with all 14 icons from the player's own icon ZIP (GM stays separate).
	var nav := _panel(columns, "Menu_Panel.png", 241.0)
	nav.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var nav_root := VBoxContainer.new()
	nav_root.add_theme_constant_override("separation", 5)
	nav.add_child(nav_root)
	nav_root.add_child(_label("NEX TGEN LEO", 17))
	nav_root.add_child(_label("เมนูรายการ", 13))
	nav_scroll = ScrollContainer.new()
	nav_scroll.name = "MenuListScroll"
	nav_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	nav_root.add_child(nav_scroll)
	var nav_stack := VBoxContainer.new()
	nav_stack.name = "FullMenuList"
	nav_stack.add_theme_constant_override("separation", 3)
	nav_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_scroll.add_child(nav_stack)
	for entry in MENU_SPECS:
		_nav_button(str(entry["id"]), str(entry["title"]), int(entry["icon"]), nav_stack)
	_button("ปิดหน้าต่าง [Esc]", func(): close_workspace(), nav_root, 38)
	# Character preview in the centre, combat equipment on the left,
	# fashion equipment on the right, and five jewellery slots below.
	var mid := VBoxContainer.new()
	mid.custom_minimum_size.x = 421
	mid.add_theme_constant_override("separation", 6)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(mid)
	var gear := _panel(mid, "Character_Equipment_Panel.png")
	gear.name = "CharacterEquipmentFrame"
	gear.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var gear_column := VBoxContainer.new()
	gear_column.add_theme_constant_override("separation", 4)
	gear.add_child(gear_column)
	gear_column.add_child(_label("ตัวละครและอุปกรณ์", 16))
	var gear_scroll := ScrollContainer.new()
	gear_scroll.name = "EquipmentScroll"
	gear_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gear_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gear_column.add_child(gear_scroll)
	var gear_stack := VBoxContainer.new()
	gear_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gear_stack.add_theme_constant_override("separation", 6)
	gear_scroll.add_child(gear_stack)
	equipment_grid = HBoxContainer.new()
	equipment_grid.name = "WarriorCharacterFashion"
	equipment_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_grid.add_theme_constant_override("separation", 6)
	gear_stack.add_child(equipment_grid)
	var warrior_col := VBoxContainer.new()
	warrior_col.custom_minimum_size.x = 63
	warrior_col.add_theme_constant_override("separation", 3)
	equipment_grid.add_child(warrior_col)
	var warrior_title := _label("ชุดนักรบ", 12)
	warrior_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warrior_col.add_child(warrior_title)
	warrior_stack = VBoxContainer.new()
	warrior_stack.name = "WarriorEquipmentSlots"
	warrior_stack.add_theme_constant_override("separation", 2)
	warrior_col.add_child(warrior_stack)
	var character_col := VBoxContainer.new()
	character_col.custom_minimum_size.x = 226
	character_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_col.add_theme_constant_override("separation", 3)
	equipment_grid.add_child(character_col)
	var portrait_title := _label("ตัวละคร", 12)
	portrait_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_col.add_child(portrait_title)
	_build_character_preview(character_col)
	var fashion_col := VBoxContainer.new()
	fashion_col.custom_minimum_size.x = 63
	fashion_col.add_theme_constant_override("separation", 3)
	equipment_grid.add_child(fashion_col)
	var fashion_title := _label("ชุดแฟชั่น", 12)
	fashion_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fashion_col.add_child(fashion_title)
	fashion_stack = VBoxContainer.new()
	fashion_stack.name = "FashionEquipmentSlots"
	fashion_stack.add_theme_constant_override("separation", 2)
	fashion_col.add_child(fashion_stack)
	# Jewellery remains independent from fashion, in the exact requested order.
	var jewelry_section := VBoxContainer.new()
	jewelry_section.name = "JewelrySection"
	jewelry_section.add_theme_constant_override("separation", 3)
	gear_stack.add_child(jewelry_section)
	var jewelry_title := _label("เครื่องประดับ", 13)
	jewelry_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jewelry_section.add_child(jewelry_title)
	accessory_stack = HBoxContainer.new()
	accessory_stack.name = "FiveJewelrySlots"
	accessory_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	accessory_stack.add_theme_constant_override("separation", 5)
	jewelry_section.add_child(accessory_stack)
	# PvE/PvP is a separate panel, and no invented PvP stats are displayed.
	var stats := _panel(mid, "PVE_PVP_Stats_Panel.png")
	stats.custom_minimum_size.y = 110
	stats.size_flags_vertical = Control.SIZE_SHRINK_END
	var stats_column := VBoxContainer.new()
	stats.add_child(stats_column)
	stats_column.add_child(_label("ค่าสถานะ PvE / PvP", 14))
	stats_label = _label("", 12)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_column.add_child(stats_label)
	# Main inventory pane.
	var bag := _panel(columns, "Inventory_Panel.png", 465.0)
	bag.name = "InventoryRight"
	var bag_stack := VBoxContainer.new()
	bag_stack.add_theme_constant_override("separation", 5)
	bag.add_child(bag_stack)
	bag_stack.add_child(_label("กระเป๋าไอเทม", 17))
	inventory_summary = _label("", 12)
	bag_stack.add_child(inventory_summary)
	var pagination := HBoxContainer.new()
	bag_stack.add_child(pagination)
	var prev := _button("◀", func(): _page_change(-1), pagination)
	prev.name = "SilverPrevPage"
	prev.custom_minimum_size.x = 45
	page_label = _label("", 13)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pagination.add_child(page_label)
	var next := _button("▶", func(): _page_change(1), pagination)
	next.name = "SilverNextPage"
	next.custom_minimum_size.x = 45
	var actions := HBoxContainer.new()
	bag_stack.add_child(actions)
	_button("จัดเรียง", func(): _sort_items(), actions)
	_button("เลือกหลายชิ้น", func(): _toggle_bulk(), actions)
	_button("ขายที่เลือก", func(): _confirm_sell(), actions)
	inventory_scroll = ScrollContainer.new()
	inventory_scroll.name = "InventoryScroll"
	inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bag_stack.add_child(inventory_scroll)
	item_grid = GridContainer.new()
	item_grid.columns = 6
	item_grid.add_theme_constant_override("h_separation", 4)
	item_grid.add_theme_constant_override("v_separation", 4)
	item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_scroll.add_child(item_grid)
	# Optional extension exists outside Main Base; it never leaves an empty strip.
	extension_frame = _panel(self, "Extension_Base.png")
	extension_frame.name = "ExtensionBase"
	extension_frame.size_flags_horizontal = 0
	extension_frame.size_flags_vertical = 0
	var ext_inner := _panel(extension_frame, "Extension_Content_Panel.png")
	var extension_scroll := ScrollContainer.new()
	extension_scroll.name = "ExtensionScroll"
	extension_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	extension_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ext_inner.add_child(extension_scroll)
	extension_content = VBoxContainer.new()
	extension_content.name = "ExtensionControls"
	extension_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extension_content.add_theme_constant_override("separation", 7)
	extension_scroll.add_child(extension_content)
	extension_frame.hide()


func _build_character_preview(parent: VBoxContainer) -> void:
	# A lightweight 3D portrait of the current equipped character, not a
	# prepainted person. The viewport draws on demand rather than every frame.
	avatar_preview_frame = _panel(parent, "Character_Equipment_Panel.png", 211.0)
	avatar_preview_frame.name = "LiveCharacterPortrait"
	avatar_preview_frame.custom_minimum_size.y = 415.0
	var frame_inner := VBoxContainer.new()
	avatar_preview_frame.add_child(frame_inner)
	var viewport_holder := SubViewportContainer.new()
	viewport_holder.name = "LivePortraitViewportContainer"
	viewport_holder.stretch = true
	viewport_holder.custom_minimum_size = Vector2(190.0, 390.0)
	viewport_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_inner.add_child(viewport_holder)
	avatar_viewport = SubViewport.new()
	avatar_viewport.name = "LiveCharacterViewport"
	avatar_viewport.size = Vector2i(144, 290)
	avatar_viewport.own_world_3d = true
	avatar_viewport.transparent_bg = true
	avatar_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport_holder.add_child(avatar_viewport)
	var stage_root := Node3D.new()
	avatar_viewport.add_child(stage_root)
	avatar_stage = Node3D.new()
	avatar_stage.name = "PortraitMeshStage"
	stage_root.add_child(avatar_stage)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-40, -32, 0)
	key_light.light_energy = 2.6
	stage_root.add_child(key_light)
	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-18, 95, 0)
	fill_light.light_energy = 1.25
	stage_root.add_child(fill_light)
	var camera := Camera3D.new()
	camera.name = "PortraitCamera"
	camera.position = Vector3(0.0, 1.16, -2.95)
	camera.fov = 34.0
	stage_root.add_child(camera)
	camera.look_at(Vector3(0.0, 0.98, 0.0), Vector3.UP)
	camera.current = true

func _refresh_character_preview() -> void:
	if not visible or not is_instance_valid(avatar_stage) or not is_instance_valid(game):
		return
	var current_avatar: Node3D = game.get("avatar")
	if not is_instance_valid(current_avatar):
		return
	# No duplicate() of skinned GLBs: use the existing shared Mesh resources,
	# which avoids the node duplication error in Godot and keeps WebGL lighter.
	for child in avatar_stage.get_children():
		avatar_stage.remove_child(child)
		child.queue_free()
	var model := Node3D.new()
	model.name = "PortraitModel"
	avatar_stage.add_child(model)
	game.call("_copy_preview_meshes", current_avatar, model)
	avatar_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func open_workspace() -> void:
	visible = true
	_set_extension("")
	_refresh_equipment()
	_refresh_contents()
	_refresh_character_preview()
	_layout()
	move_to_front()

func close_workspace() -> void:
	hide()
	extension_mode = ""
	if is_instance_valid(game):
		game.call("_close_panel")

func _set_extension(mode: String) -> void:
	extension_mode = mode
	extension_frame.visible = not mode.is_empty()
	for child in extension_content.get_children():
		extension_content.remove_child(child)
		child.queue_free()
	if mode.is_empty():
		_layout()
		return
	var menu_title: String = {
		"Shop":"ร้านค้า NPC", "Cash":"ร้านค้าแคช", "Quest":"เควสต์และภารกิจ",
		"World":"แผนที่โลก", "Pet":"สัตว์เลี้ยง", "Auto":"ล่าอัตโนมัติ",
		"Skills":"ทักษะ", "Settings":"ตั้งค่า", "Connect":"เชื่อมต่อออนไลน์",
		"Storage":"คลังเก็บของ", "Trade":"เทรดซื้อขาย", "Guild":"กิลด์"
	}.get(mode, mode)
	extension_content.add_child(_label(menu_title, 18))
	_button("ปิดกรอบเสริม", func(): _set_extension(""), extension_content, 33)
	match mode:
		"Shop", "Cash":
			_extension_shop(mode == "Cash")
		"Quest":
			_extension_quest()
		"World":
			for i in range(GameState.balance.maps.size()):
				var map_index: int = i
				var map_name: String = str(GameState.balance.maps[i].get("name", "Map"))
				_button("ไปยัง " + map_name, func(): game.call("_warp", map_index), extension_content, 36)
		"Pet":
			extension_content.add_child(_label("สัตว์เลี้ยง Lv.%d · EXP %d\nวิวัฒนาการ %d / 5" % [GameState.pet_level, GameState.pet_exp, GameState.pet_stage], 13))
			_button("เรียกสัตว์เลี้ยง" if not GameState.pet_enabled else "เก็บสัตว์เลี้ยง", func():
				GameState.pet_enabled = not GameState.pet_enabled
				game.call("_save")
				call_deferred("_set_extension", "Pet")
			, extension_content, 40)
		"Auto":
			extension_content.add_child(_label("เลือกสกิลที่ใช้ระหว่างล่าอัตโนมัติ", 12))
			for i in range(3):
				var slot_index: int = i
				var check := CheckButton.new()
				check.text = str(GameState.skill_definition(i + 1).get("name", "Skill"))
				check.button_pressed = bool(game.hunt_skills[i])
				check.toggled.connect(func(on: bool): game.call("_select_hunt_skill", slot_index, on))
				extension_content.add_child(check)
			for radius in [12.0, 20.0, 36.0]:
				var hunting_radius: float = float(radius)
				_button("ระยะล่า %d เมตร" % int(radius), func(): game.call("_select_hunt_radius", hunting_radius), extension_content, 34)
			_button("เปิด / ปิดล่าอัตโนมัติ", func(): game.call("_action", 7); close_workspace(), extension_content, 41)
		"Skills":
			extension_content.add_child(_label("สกิลขั้นแรก / จอมจ้าว", 13))
			for skill_no in range(1, 4):
				var info: Dictionary = GameState.skill_definition(skill_no)
				extension_content.add_child(_label("%d. %s\nStamina %.0f · คูลดาวน์ %.1f วิ" % [skill_no, str(info.get("name", "Skill")), float(info.get("cost", 0.0)), float(info.get("cooldown", 0.0))], 12))
			if GameState.class_rank >= 3 and GameState.class_rank < 5 and GameState.selected_element in GameState.balance.element_skills:
				for slot_no in range(3):
					for source_no in range(3):
						var target_slot: int = slot_no
						var source_slot: int = source_no
						var definition: Dictionary = GameState.balance.element_skills[GameState.selected_element][source_no]
						_button("ช่อง %d: %s" % [slot_no + 1, str(definition.get("name", "Skill"))], func():
							GameState.set_skill_slot(target_slot, source_slot)
							game.call("_tell", "อัปเดตสกิลแล้ว")
						, extension_content, 33)
		"Settings":
			_button("บันทึกเกม", func(): game.call("_save"); game.call("_tell", "บันทึกเกมแล้ว"), extension_content)
			_button("ปรับตำแหน่งปุ่ม HUD", func(): game.layout_edit = not game.layout_edit; close_workspace(), extension_content)
			_button("คืนตำแหน่งปุ่ม HUD", func():
				GameState.settings["button_offsets"] = {}
				GameState.settings["button_offsets_portrait"] = {}
				GameState.settings["button_offsets_landscape"] = {}
				game.call("_layout")
				game.call("_save")
			, extension_content)
			for ui_pct in [90, 100, 110, 120]:
				var amount: int = int(ui_pct)
				_button("ขนาด UI %d%%" % amount, func(): game.call("_set_ui_scale", float(amount) / 100.0), extension_content)
		"Connect":
			extension_content.add_child(_label("การเชื่อมต่อออนไลน์ใช้เซิร์ฟเวอร์ที่เจ้าของระบุ\nข้อมูลออฟไลน์ไม่ย้ายไปเซิร์ฟเวอร์อัตโนมัติ", 12))
			var address := LineEdit.new()
			address.text = "ws://127.0.0.1:8765/ws"
			extension_content.add_child(address)
			_button("เชื่อมต่อ", func(): game.network.connect_server(address.text); close_workspace(), extension_content, 39)
		"Storage", "Trade", "Guild":
			var explanation: String = {
				"Storage":"คลังเก็บของยังไม่เชื่อมข้อมูลออนไลน์\nยังไม่อนุญาตให้ฝากหรือถอนจริง",
				"Trade":"เทรดระหว่างผู้เล่นยังไม่เชื่อมระบบเซิร์ฟเวอร์\nยังไม่อนุญาตให้โอนหรือแลกไอเทมจริง",
				"Guild":"เมนูกิลด์เตรียมไว้แล้ว\nระบบสมาชิกและบริจาคยังไม่เปิดใช้งาน"
			}.get(mode, "")
			var warning := _label(explanation, 12)
			warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			extension_content.add_child(warning)
		_:
			extension_content.add_child(_label("ยังไม่มีหน้าระบบสำหรับเมนูนี้", 12))
	_layout()

func _extension_shop(cash_shop: bool) -> void:
	var currency := _label("Gold %d  ·  Cash %d" % [GameState.gold, GameState.cash], 12)
	extension_content.add_child(currency)
	var quantity := SpinBox.new()
	quantity.name = "ShopQuantity"
	quantity.min_value = 1
	quantity.max_value = 99
	quantity.value = 1
	extension_content.add_child(_label("จำนวนที่ซื้อ", 12))
	extension_content.add_child(quantity)
	for item_id in GameState.balance.items:
		var product_id: String = str(item_id)
		var item: Dictionary = GameState.balance.items[product_id]
		if bool(item.get("cash", false)) != cash_shop:
			continue
		var caption: String = "%s · %d %s" % [str(item.get("name", product_id)), int(item.get("price", 0)), "Cash" if cash_shop else "Gold"]
		_button(caption, func():
			var ok: bool = GameState.buy(product_id, int(quantity.value))
			game.call("_tell", "ซื้อไอเทมสำเร็จ" if ok else "เงินไม่พอ หรือกระเป๋าเต็ม")
			if ok:
				game.call("_save")
				currency.text = "Gold %d  ·  Cash %d" % [GameState.gold, GameState.cash]
		, extension_content, 35)

func _extension_quest() -> void:
	extension_content.add_child(_label("เควสต์เริ่มต้น: %s\nกำจัดศัตรู %d / 5" % [GameState.quest_state, GameState.quest_kills], 13))
	_button("นำทางไปหา NPC เควสต์", func():
		var quest_npc: Node3D = game.get("npc")
		if is_instance_valid(quest_npc):
			game.set("npc_navigation", true)
			game.world.auto_destination = quest_npc.position
		close_workspace()
	, extension_content, 41)
	_button("สนทนากับ NPC", func():
		var quest_npc: Node3D = game.get("npc")
		if not is_instance_valid(quest_npc):
			return
		if game.world.player.position.distance_to(quest_npc.position) < 4.0:
			game.call("_tell", GameState.interact_quest())
			call_deferred("_set_extension", "Quest")
		else:
			game.call("_tell", "เข้าใกล้ NPC หรือกดนำทางก่อน")
	, extension_content, 38)
	_button("เลื่อนคลาส (Lv.100 + เควสต์)", func():
		game.call("_tell", "เลื่อนคลาสสำเร็จ" if GameState.advance_class() else "ยังไม่ผ่านเงื่อนไข")
	, extension_content, 40)

func _layout() -> void:
	if not is_instance_valid(main_frame):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	size = viewport_size
	var needed_width := MAIN_WIDTH + (EXT_WIDTH + 8.0 if extension_frame.visible else 0.0)
	var scale_value := minf(minf(1.0, (viewport_size.x - 16.0) / needed_width), (viewport_size.y - 16.0) / MAIN_HEIGHT)
	scale_value = maxf(0.28, scale_value)
	main_frame.scale = Vector2.ONE * scale_value
	main_frame.size = Vector2(MAIN_WIDTH, MAIN_HEIGHT)
	main_frame.position = Vector2(8.0, maxf(8.0, (viewport_size.y - MAIN_HEIGHT * scale_value) * 0.5))
	extension_frame.scale = Vector2.ONE * scale_value
	extension_frame.size = Vector2(EXT_WIDTH, MAIN_HEIGHT)
	extension_frame.position = main_frame.position + Vector2((MAIN_WIDTH + 8.0) * scale_value, 0)
	# Reuse existing UI scale preferences without squashing a slot graphic.
	item_grid.columns = 6

func _refresh_equipment() -> void:
	if not is_instance_valid(warrior_stack) or not is_instance_valid(fashion_stack) or not is_instance_valid(accessory_stack):
		return
	for stack in [warrior_stack, fashion_stack, accessory_stack]:
		for child in stack.get_children():
			stack.remove_child(child)
			child.queue_free()
	equipment_buttons.clear()
	accessory_buttons.clear()
	# One reusable PNG per slot, with the live item icon drawn only when worn.
	for definition in EQUIPMENT_KEYS:
		_equipment_slot(str(definition["warrior"]), str(definition["name"]), warrior_stack, false)
		_equipment_slot(str(definition["fashion"]), str(definition["name"]), fashion_stack, false)
	# Ordered exactly: ring, bracelet, necklace, bracelet, ring.
	for definition in [
		{"id":"ring","title":"แหวน"},
		{"id":"bracelet_left","title":"กำไล"},
		{"id":"accessory","title":"สร้อย"},
		{"id":"bracelet_right","title":"กำไล"},
		{"id":"ring_right","title":"แหวน"}
	]:
		_equipment_slot(str(definition["id"]), str(definition["title"]), accessory_stack, true)
	stats_label.text = "PvE  ATK %d  DEF %d  HP %d / %d\nPvP  แยกค่าสถานะเมื่อระบบ PvP เปิดใช้งาน" % [GameState.attack_power(), GameState.defense(), GameState.hp, GameState.max_hp]

func _equipment_slot(slot_id: String, caption: String, parent: BoxContainer, is_jewelry: bool) -> void:
	var unit := VBoxContainer.new()
	unit.name = "SlotContainer_" + slot_id
	unit.size_flags_horizontal = Control.SIZE_EXPAND_FILL if is_jewelry else Control.SIZE_SHRINK_CENTER
	unit.add_theme_constant_override("separation", 1)
	parent.add_child(unit)
	var slot := Button.new()
	slot.name = ("JewelrySlot_" if is_jewelry else "EquipmentSlot_") + slot_id
	slot.custom_minimum_size = Vector2(48, 48)
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.add_theme_stylebox_override("normal", _slot_style())
	slot.add_theme_stylebox_override("hover", _slot_style())
	slot.add_theme_stylebox_override("pressed", _slot_style())
	slot.set_meta("leo_fantasy_skin", true)
	slot.tooltip_text = caption
	var equipped: Dictionary = GameState.equipped.get(slot_id, {})
	if not equipped.is_empty():
		var details: Dictionary = GameState.balance.items.get(str(equipped.get("id", "")), {})
		slot.tooltip_text = str(details.get("name", slot_id))
		var png_path: String = str(details.get("icon_png", ""))
		if png_path != "" and ResourceLoader.exists(png_path):
			slot.icon = load(png_path) as Texture2D
			slot.expand_icon = true
		else:
			slot.text = str(details.get("icon", "◆"))
	slot.pressed.connect(func(): game.call("_bag_equipment_clicked", slot_id))
	unit.add_child(slot)
	var note := _label(caption, 11 if not is_jewelry else 10)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unit.add_child(note)
	if is_jewelry:
		accessory_buttons[slot_id] = slot
	else:
		equipment_buttons[slot_id] = slot

func _on_inventory_changed() -> void:
	if visible:
		_refresh_contents()

func _refresh_contents() -> void:
	if not is_instance_valid(item_grid):
		return
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()
	page = clampi(page, 0, 1)
	page_label.text = "หน้า %d / 2" % (page + 1)
	inventory_summary.text = "เก็บ %d / 200 ช่อง   •   Gold %d   •   Cash %d" % [GameState.inventory.size(), GameState.gold, GameState.cash]
	for offset in range(100):
		var index := page * 100 + offset
		var slot := Button.new()
		slot.name = "InventorySlot%d" % index
		slot.custom_minimum_size = Vector2(SLOT_SIDE, SLOT_SIDE)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_stylebox_override("normal", _slot_style())
		slot.add_theme_stylebox_override("hover", _slot_style())
		slot.add_theme_stylebox_override("pressed", _slot_style())
		slot.set_meta("leo_fantasy_skin", true)
		slot.tooltip_text = "ช่องว่าง %d" % (index + 1)
		if index < GameState.inventory.size():
			var owned: Dictionary = GameState.inventory[index]
			var item: Dictionary = GameState.balance.items.get(str(owned.get("id", "")), {})
			var image_path: String = str(item.get("icon_png", ""))
			if image_path != "" and ResourceLoader.exists(image_path):
				slot.icon = load(image_path)
				slot.expand_icon = true
			else:
				slot.text = str(item.get("icon", "◆")) + "\n" + str(owned.get("count", 1))
			slot.tooltip_text = "%s ×%d" % [str(item.get("name", owned.get("id", ""))), int(owned.get("count", 1))]
		if bulk_selection.has(index):
			slot.add_theme_color_override("font_color", Color("#D5E4FA"))
			slot.text = "✓" + slot.text
		slot.pressed.connect(func():
			if bulk_mode:
				_select_bulk(index)
			elif index < GameState.inventory.size():
				hide()
				game.call("_item_menu", index)
		)
		item_grid.add_child(slot)
	_refresh_equipment()

func _page_change(delta: int) -> void:
	page = clampi(page + delta, 0, 1)
	inventory_scroll.scroll_vertical = 0
	_refresh_contents()

func _sort_items() -> void:
	GameState.inventory.sort_custom(func(a, b): return str(a.get("id", "")) < str(b.get("id", "")))
	bulk_selection.clear()
	_refresh_contents()

func _toggle_bulk() -> void:
	bulk_mode = not bulk_mode
	bulk_selection.clear()
	_refresh_contents()

func _select_bulk(index: int) -> void:
	if index >= GameState.inventory.size():
		return
	if bulk_selection.has(index):
		bulk_selection.erase(index)
	else:
		bulk_selection[index] = int(GameState.inventory[index].get("count", 1))
	_refresh_contents()

func _confirm_sell() -> void:
	if bulk_selection.is_empty():
		return
	var sell_count := bulk_selection.size()
	var received := GameState.sell_many(bulk_selection)
	if received >= 0:
		bulk_selection.clear()
		bulk_mode = false
		game.call("_tell", "ขาย %d ช่อง ได้รับ %d Gold" % [sell_count, received])
		_refresh_contents()
	else:
		game.call("_tell", "ขายไม่สำเร็จ โปรดลองเลือกใหม่")
