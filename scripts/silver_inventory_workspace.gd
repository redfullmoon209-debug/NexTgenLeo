extends Control
## A composited silver inventory window. Main and extension are independent.
## All frames use reusable 9-slice PNGs; the item/equipment slots share one PNG.
## Data and equipment actions are provided by the existing GameState/gameplay.
const ROOT := "res://assets/ui/silver/"
const MAIN_WIDTH := 1060.0
const MAIN_HEIGHT := 720.0
const EXT_WIDTH := 305.0
const SLOT_SIDE := 60.0
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
var equipment_grid: GridContainer
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
	GameState.appearance_changed.connect(_refresh_equipment)
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
	# Left navigation.
	var nav := _panel(columns, "Menu_Panel.png", 168.0)
	nav.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var nav_stack := VBoxContainer.new()
	nav_stack.add_theme_constant_override("separation", 5)
	nav.add_child(nav_stack)
	nav_stack.add_child(_label("NEX TGEN LEO", 16))
	nav_stack.add_child(_label("เมนูรายการ", 13))
	for entry in [
		{"title":"ตัวละครและอุปกรณ์","mode":""},
		{"title":"กระเป๋า","mode":""},
		{"title":"คลัง","mode":"Storage"},
		{"title":"เทรดซื้อขาย","mode":"Trade"},
		{"title":"ภารกิจ","mode":"Quest"}
	]:
		var mode: String = entry.mode
		var nav_button := _button(entry.title, func(): _set_extension(mode), nav_stack, 39)
		nav_button.name = "SilverNav" + (mode if mode != "" else "Bag")
		menu_buttons[entry.title] = nav_button
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav_stack.add_child(filler)
	_button("ปิดหน้าต่าง [Esc]", func(): close_workspace(), nav_stack, 37)
	# Character + PvE/PvP stack in the middle.
	var mid := VBoxContainer.new()
	mid.custom_minimum_size.x = 338
	mid.add_theme_constant_override("separation", 6)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(mid)
	var gear := _panel(mid, "Character_Equipment_Panel.png")
	gear.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var gear_column := VBoxContainer.new()
	gear_column.add_theme_constant_override("separation", 4)
	gear.add_child(gear_column)
	gear_column.add_child(_label("ตัวละครและอุปกรณ์", 16))
	var gear_scroll := ScrollContainer.new()
	gear_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gear_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gear_column.add_child(gear_scroll)
	var gear_stack := VBoxContainer.new()
	gear_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gear_stack.add_theme_constant_override("separation", 7)
	gear_scroll.add_child(gear_stack)
		# Both columns use the same empty slot image; fashion gear is cosmetic.
	equipment_grid = GridContainer.new()
	equipment_grid.columns = 2
	equipment_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_grid.add_theme_constant_override("h_separation", 5)
	equipment_grid.add_theme_constant_override("v_separation", 5)
	gear_stack.add_child(equipment_grid)
	# Keep the existing live character preview without a second model system.
	var preview_row := HBoxContainer.new()
	preview_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gear_stack.add_child(preview_row)
	# Do not instantiate a second animated GLB viewport on this overlay:
	# its textures can exceed the WebGL memory budget when combined with 100 cells.
	var avatar_note := _label("ตัวละคร 3D แสดงในเกมด้านหลังหน้าต่าง", 12)
	avatar_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_row.add_child(avatar_note)
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
	var bag := _panel(columns, "Inventory_Panel.png", 445.0)
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
	extension_content = VBoxContainer.new()
	extension_content.add_theme_constant_override("separation", 9)
	ext_inner.add_child(extension_content)
	extension_frame.hide()

func open_workspace() -> void:
	visible = true
	_set_extension("")
	_refresh_equipment()
	_refresh_contents()
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
	if mode != "":
		extension_content.add_child(_label({"Storage":"คลังเก็บของ","Trade":"เทรดซื้อขาย","Quest":"ภารกิจ"}.get(mode, mode), 19))
		if mode == "Quest":
			extension_content.add_child(_label("สถานะ: %s   %d / 5" % [GameState.quest_state, GameState.quest_kills], 14))
			_button("ไปหา NPC ภารกิจ", func():
				var quest_npc: Node3D = game.get("npc")
				if is_instance_valid(quest_npc):
					game.set("npc_navigation", true)
					game.world.auto_destination = quest_npc.position
				close_workspace()
			, extension_content, 43)
		else:
			extension_content.add_child(_label("ระบบนี้ยังไม่มีฟังก์ชันออนไลน์ที่พร้อมใช้งาน\nแสดงกรอบไว้รองรับการเชื่อมต่อภายหลัง", 13))
		_button("ปิดกรอบเสริม", func(): _set_extension(""), extension_content)
	_layout()

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
	if not is_instance_valid(equipment_grid):
		return
	for child in equipment_grid.get_children():
		equipment_grid.remove_child(child)
		child.queue_free()
	var warrior_head := _label("ชุดนักรบ", 14)
	warrior_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_grid.add_child(warrior_head)
	var fashion_head := _label("ชุดแฟชั่น", 14)
	fashion_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_grid.add_child(fashion_head)
	for definition in EQUIPMENT_KEYS:
		_equipment_row(str(definition.warrior), str(definition.name))
		_equipment_row(str(definition.fashion), str(definition.name))
	stats_label.text = "PvE  ATK %d  DEF %d  HP %d / %d\nPvP  แยกค่าสถานะเมื่อระบบ PvP เปิดใช้งาน" % [GameState.attack_power(), GameState.defense(), GameState.hp, GameState.max_hp]


func _equipment_row(slot_id: String, caption: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	equipment_grid.add_child(row)
	var slot := Button.new()
	slot.custom_minimum_size = Vector2(46, 46)
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
			slot.icon = load(png_path)
			slot.expand_icon = true
		else:
			slot.text = str(details.get("icon", "◆"))
	slot.pressed.connect(func(): game.call("_bag_equipment_clicked", slot_id))
	row.add_child(slot)
	var note := _label(caption, 11)
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(note)

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
