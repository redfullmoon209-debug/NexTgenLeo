extends CanvasLayer
## Six new standalone icon buttons (3-8) + two rich lists, matching Settings.
## GM (1) and Settings (2) preserve their original actions and menus.
## All source icons are independent SVG assets; labels stay editable Thai text.

const ICON_PATH := "res://assets/ui/main_nav/icons/%s.svg"
const NAV_IDS := ["Bag", "Menu", "Guild", "Party", "Friends", "Notice"]
const NAV_LABELS := {
	"Bag": "กระเป๋า",
	"Menu": "เมนูหลัก",
	"Guild": "กิลด์",
	"Party": "ปาร์ตี้",
	"Friends": "รายชื่อเพื่อน",
	"Notice": "ประกาศจากเซิร์ฟเวอร์"
}
const NAV_ICONS := {
	"Bag": "bag", "Menu": "menu", "Guild": "guild",
	"Party": "party", "Friends": "friends", "Notice": "announcement"
}
const BAG_ITEMS := [
	["Bag", "กระเป๋า", "bag"],
	["Storage", "คลังเก็บของ", "storage"],
	["Trade", "เทรด", "trade"],
	["Status", "ตัวละครและอุปกรณ์", "status"],
	["Shop", "ร้านค้า", "shop"],
	["Cash", "ร้านค้าแคช", "cash"],
	["Pet", "สัตว์เลี้ยง", "pet"],
	["Skills", "สกิล", "skills"]
]
const MAIN_ITEMS := [
	["World", "แผนที่โลก", "map"],
	["Warp", "วาร์ป", "warp"],
	["Quest", "ภารกิจ", "quest"],
	["Auto", "ล่าอัตโนมัติ", "auto"],
	["Connect", "เชื่อมต่อเซิร์ฟเวอร์", "connect"]
]
const GUILD_ITEMS := [
	["GuildInfo", "ข้อมูลกิลด์", "guild"],
	["GuildMembers", "สมาชิกกิลด์", "party"],
	["GuildDonate", "บริจาคกิลด์", "cash"]
]
const PARTY_ITEMS := [
	["PartyInfo", "จัดการปาร์ตี้", "party"],
	["PartyInvites", "คำเชิญปาร์ตี้", "invite"]
]
const FRIEND_ITEMS := [
	["FriendList", "รายชื่อเพื่อน", "friends"],
	["FriendAdd", "เพิ่มเพื่อน", "invite"]
]
const NOTICE_ITEMS := [
	["ServerNews", "ประกาศจากเซิร์ฟเวอร์", "announcement"],
	["ServerEvents", "กิจกรรม", "events"]
]

var gameplay: Node
var root: Control
var nav_buttons: Dictionary = {}
var menu_panel: PanelContainer
var menu_header: Button
var menu_header_icon: TextureRect
var menu_header_title: Label
var row_column: VBoxContainer
var row_buttons: Array[Button] = []
var row_targets: Array[String] = []
var current_menu: String = ""
var menu_scroll: ScrollContainer

func _ready() -> void:
	layer = 29  # Settings remains on its established, higher CanvasLayer 30.
	name = "NexTgenLeoEightMainButtons"
	root = Control.new()
	root.name = "MainNavHitArea"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui_theme := Theme.new()
	ui_theme.default_font = load("res://assets/fonts/NotoSansThai.ttf")
	root.theme = ui_theme
	add_child(root)
	for menu_id in NAV_IDS:
		_create_main_icon(menu_id)
	_build_gold_dropdown()
	# Replace the old yellow hamburger with the approved transparent Menu icon.
	# Do not delete the original menu or its gameplay signals/keyboard shortcuts.
	if is_instance_valid(gameplay) and is_instance_valid(gameplay.menu_toggle_button):
		gameplay.menu_toggle_button.hide()
	_restyle_gm_icon()
	get_viewport().size_changed.connect(_responsive)
	_responsive()

func _no_backing(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.focus_mode = Control.FOCUS_NONE
	button.text = ""

func _icon_texture(name_id: String) -> Texture2D:
	return load(ICON_PATH % name_id)

func _create_main_icon(menu_id: String) -> void:
	var button := Button.new()
	button.name = "Primary_" + menu_id
	button.tooltip_text = str(NAV_LABELS[menu_id])
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	_no_backing(button)
	root.add_child(button)
	var art := TextureRect.new()
	art.name = "IndependentIconLayer"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = _icon_texture(str(NAV_ICONS[menu_id]))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(art)
	nav_buttons[menu_id] = button

func _restyle_gm_icon() -> void:
	if not is_instance_valid(gameplay) or not is_instance_valid(gameplay.owner_gm_button):
		return
	var gm_button: Button = gameplay.owner_gm_button
	# Only the OUTSIDE GM icon changes; permission checks and inner GM panel stay intact.
	_no_backing(gm_button)
	var art := TextureRect.new()
	art.name = "GM_IndependentRedShield"
	art.texture = _icon_texture("gm")
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gm_button.add_child(art)
	var caption := Label.new()
	caption.name = "GM_Caption"
	caption.text = "GM"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", Color("#FFFFFF"))
	caption.add_theme_color_override("font_outline_color", Color("#45101D"))
	caption.add_theme_constant_override("outline_size", 3)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gm_button.add_child(caption)

func _gold_button(button: Button) -> void:
	_no_backing(button)
	var fill := Panel.new()
	fill.name = "Layer_background"
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color("#F5A918")
	fill_style.shadow_color = Color("#4B2608A0")
	fill_style.shadow_size = 3
	fill_style.set_corner_radius_all(26)
	fill.add_theme_stylebox_override("panel", fill_style)
	button.add_child(fill)
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := Panel.new()
	frame.name = "Layer_base_frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border := StyleBoxFlat.new()
	border.bg_color = Color.TRANSPARENT
	border.border_color = Color("#201007")
	border.set_border_width_all(4)
	border.set_corner_radius_all(26)
	frame.add_theme_stylebox_override("panel", border)
	button.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shine := Panel.new()
	shine.name = "Layer_gold_highlight"
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shine_style := StyleBoxFlat.new()
	shine_style.bg_color = Color.TRANSPARENT
	shine_style.border_color = Color("#FFF1A0")
	shine_style.border_width_top = 2
	shine_style.border_width_left = 1
	shine_style.border_width_right = 1
	shine_style.border_width_bottom = 1
	shine_style.set_corner_radius_all(23)
	shine.add_theme_stylebox_override("panel", shine_style)
	button.add_child(shine)
	shine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shine.offset_left = 5
	shine.offset_right = -5
	shine.offset_top = 5
	shine.offset_bottom = -5

func _panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#160F09F2")
	s.border_color = Color("#DDA128")
	s.set_border_width_all(3)
	s.set_corner_radius_all(19)
	s.content_margin_left = 9
	s.content_margin_right = 9
	s.content_margin_top = 9
	s.content_margin_bottom = 9
	return s

func _decorate_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _build_gold_dropdown() -> void:
	menu_panel = PanelContainer.new()
	menu_panel.name = "RichGoldMainMenu"
	menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(menu_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	menu_panel.add_child(outer)
	menu_header = Button.new()
	menu_header.name = "RichMenuHeader"
	menu_header.custom_minimum_size = Vector2(0, 66)
	_gold_button(menu_header)
	outer.add_child(menu_header)
	var heading := HBoxContainer.new()
	heading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	heading.offset_left = 17
	heading.offset_right = -17
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_theme_constant_override("separation", 12)
	menu_header.add_child(heading)
	menu_header_icon = TextureRect.new()
	menu_header_icon.custom_minimum_size = Vector2(45, 45)
	menu_header_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_header_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	menu_header_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(menu_header_icon)
	menu_header_title = Label.new()
	menu_header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_decorate_label(menu_header_title, 24)
	heading.add_child(menu_header_title)
	var up := TextureRect.new()
	up.texture = load("res://assets/ui/settings/icons/chevron_up.svg")
	up.custom_minimum_size = Vector2(32, 32)
	up.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	up.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(up)
	menu_scroll = ScrollContainer.new()
	menu_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(menu_scroll)
	row_column = VBoxContainer.new()
	row_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_column.add_theme_constant_override("separation", 3)
	menu_scroll.add_child(row_column)
	menu_panel.hide()

func _items_for(menu_id: String) -> Array:
	match menu_id:
		"Bag": return BAG_ITEMS
		"Menu": return MAIN_ITEMS
		"Guild": return GUILD_ITEMS
		"Party": return PARTY_ITEMS
		"Friends": return FRIEND_ITEMS
		"Notice": return NOTICE_ITEMS
	return []

func _add_row(target_id: String, title: String, icon_name: String, index: int) -> void:
	var row := Button.new()
	row.name = "RichRow_" + target_id
	row.custom_minimum_size = Vector2(0, 55)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.tooltip_text = title
	_gold_button(row)
	row_column.add_child(row)
	var contents := HBoxContainer.new()
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_left = 15
	contents.offset_right = -15
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 11)
	row.add_child(contents)
	var artwork := TextureRect.new()
	artwork.texture = _icon_texture(icon_name)
	artwork.custom_minimum_size = Vector2(44, 44)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(artwork)
	var caption := Label.new()
	caption.text = str(index + 1) + ". " + title
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_decorate_label(caption, 19)
	contents.add_child(caption)
	var arrow := TextureRect.new()
	arrow.texture = load("res://assets/ui/settings/icons/chevron_right.svg")
	arrow.custom_minimum_size = Vector2(29, 29)
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(arrow)
	row_buttons.append(row)
	row_targets.append(target_id)

func _open_menu(menu_id: String) -> void:
	if current_menu == menu_id:
		_close_menu()
		return
	# A newly opened navigation list must not be covered by the existing bag or modal UI.
	if is_instance_valid(gameplay):
		if (is_instance_valid(gameplay.panel) and gameplay.panel.visible) or (is_instance_valid(gameplay.silver_workspace) and gameplay.silver_workspace.visible):
			gameplay._close_panel()
	current_menu = menu_id
	for child in row_column.get_children():
		row_column.remove_child(child)
		child.queue_free()
	row_buttons.clear()
	row_targets.clear()
	var specs: Array = _items_for(menu_id)
	for i in range(specs.size()):
		var item: Array = specs[i]
		_add_row(str(item[0]), str(item[1]), str(item[2]), i)
	menu_header_title.text = str(NAV_LABELS[menu_id])
	menu_header_icon.texture = _icon_texture(str(NAV_ICONS[menu_id]))
	# Online guild, party, friends and announcement services are not claimed ready.
	if menu_id not in ["Bag", "Menu"]:
		var hint := Label.new()
		hint.text = "ระบบเซิร์ฟเวอร์ออนไลน์: อยู่ระหว่างพัฒนา"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_color_override("font_color", Color("#FFE8B0"))
		hint.add_theme_font_size_override("font_size", 15)
		row_column.add_child(hint)
	menu_panel.show()
	_responsive()

func _close_menu() -> void:
	if current_menu.is_empty():
		return
	current_menu = ""
	menu_panel.hide()
	_update_web_diagnostics()

func _activate(target_id: String) -> void:
	_close_menu()
	if not is_instance_valid(gameplay):
		return
	if target_id in ["Storage", "Trade"]:
		gameplay._tell(("คลังเก็บของ" if target_id == "Storage" else "เทรด") + " — ยังไม่เปิดใช้งานในเวอร์ชันทดสอบ")
		return
	if target_id in ["GuildInfo", "GuildMembers", "GuildDonate", "PartyInfo", "PartyInvites", "FriendList", "FriendAdd", "ServerNews", "ServerEvents"]:
		gameplay._tell("เมนูนี้รอเชื่อมต่อระบบเซิร์ฟเวอร์ออนไลน์")
		return
	var route := "World" if target_id == "Warp" else target_id
	gameplay._show_panel(route)
	# The old sidebar is replaced by these rich gold menus, not shown twice.
	gameplay._close_player_dropdown()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_ESCAPE and not current_menu.is_empty():
			_close_menu()
			get_viewport().set_input_as_handled()
		return
	var point := Vector2.INF
	if event is InputEventMouseButton:
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
		point = event.position
	elif event is InputEventScreenTouch:
		if not event.pressed:
			return
		point = event.position
	else:
		return
	# Scoped hitboxes, identical in principle to the proven Settings toggle.
	for menu_id in NAV_IDS:
		var button: Button = nav_buttons[menu_id]
		if button.get_global_rect().has_point(point):
			_open_menu(menu_id)
			get_viewport().set_input_as_handled()
			return
	if current_menu.is_empty():
		return
	if menu_header.get_global_rect().has_point(point):
		_close_menu()
		get_viewport().set_input_as_handled()
		return
	if menu_panel.get_global_rect().has_point(point):
		for i in range(row_buttons.size()):
			var row: Button = row_buttons[i]
			if row.is_visible_in_tree() and row.get_global_rect().has_point(point):
				_activate(row_targets[i])
				get_viewport().set_input_as_handled()
				return
		return
	# Dismiss, but do not swallow a GM, Settings or gameplay click.
	_close_menu()

func _process(_delta: float) -> void:
	if current_menu.is_empty() or not is_instance_valid(gameplay):
		return
	if is_instance_valid(gameplay.panel) and gameplay.panel.visible:
		_close_menu()
	elif is_instance_valid(gameplay.silver_workspace) and gameplay.silver_workspace.visible:
		_close_menu()

func _responsive() -> void:
	var view := get_viewport().get_visible_rect().size
	var portrait := view.y > view.x
	var wide := view.x >= 1160.0 and not portrait
	var columns := 6 if wide else 3
	var icon_size := 54.0 if wide else (48.0 if portrait else 50.0)
	var gap := 9.0 if wide else 8.0
	var right_edge := view.x - (180.0 if wide else (175.0 if not portrait else 10.0))
	var first_y := 94.0 if wide else (277.0 if portrait else 104.0)
	var row_count := int(ceil(float(NAV_IDS.size()) / float(columns)))
	var total_width := float(columns) * icon_size + float(columns - 1) * gap
	var left_x := maxf(8.0, right_edge - total_width)
	for i in range(NAV_IDS.size()):
		var button: Button = nav_buttons[NAV_IDS[i]]
		button.position = Vector2(left_x + float(i % columns) * (icon_size + gap), first_y + float(i / columns) * (icon_size + gap))
		button.size = Vector2.ONE * icon_size
	if not current_menu.is_empty():
		var menu_width := minf(548.0, view.x - 20.0)
		var menu_y := first_y + float(row_count) * (icon_size + gap) + 2.0
		var item_count := row_buttons.size()
		var needed_height := 66.0 + 6.0 + 2.0 * 9.0 + float(item_count) * 55.0 + float(maxi(0, item_count - 1)) * 3.0 + (45.0 if current_menu not in ["Bag", "Menu"] else 0.0)
		var max_height := maxf(148.0, view.y - menu_y - 10.0)
		menu_panel.position = Vector2(clampf(right_edge - menu_width, 10.0, maxf(10.0, view.x - menu_width - 10.0)), menu_y)
		menu_panel.size = Vector2(menu_width, minf(needed_height, max_height))
	_update_web_diagnostics()

func _update_web_diagnostics() -> void:
	if not OS.has_feature("web"):
		return
	var rectangles: Dictionary = {}
	for menu_id in NAV_IDS:
		var rect: Rect2 = (nav_buttons[menu_id] as Button).get_global_rect()
		rectangles[menu_id] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	var area: Rect2 = menu_panel.get_global_rect()
	var data := {
		"buttons": rectangles,
		"open": not current_menu.is_empty(),
		"menu": current_menu,
		"rows": row_buttons.size(),
		"items": row_targets,
		"panel": [area.position.x, area.position.y, area.size.x, area.size.y],
		"legacy_menu_hidden": is_instance_valid(gameplay) and not gameplay.menu_toggle_button.visible
	}
	JavaScriptBridge.eval("window.leoMainRichNav = " + JSON.stringify(data), true)
