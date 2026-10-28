extends CanvasLayer
## Six new standalone icon buttons (3-8) + two rich lists, matching Settings.
## GM (1) and Settings (2) preserve their original actions and menus.
## All eight standalone icons are independent artworks, never cut from a sprite sheet.

const ICON_PATH := "res://assets/ui/main_nav/icons/%s.svg"
const PRIMARY_ICON_PATH := "res://assets/ui/main_nav/standalone/%s.png"
const MainNavLayout = preload("res://scripts/main_nav_layout.gd")
const PRIMARY_ASSET_NAMES := {"Bag":"bag","Menu":"menu","Guild":"guild","Party":"party","Friends":"friends","Notice":"notice"}
const MainNavLocale = preload("res://scripts/main_nav_locale.gd")
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
var nav_grid: GridContainer
var nav_buttons: Dictionary = {}
var nav_labels: Dictionary = {}
var current_locale: String = "th"
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
	# A real GridContainer controls the primary button layout. The text is NOT baked into PNGs.
	nav_grid = GridContainer.new()
	nav_grid.name = "PrimaryIconGrid"
	nav_grid.columns = 6
	nav_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(nav_grid)
	current_locale = str(GameState.settings.get("language", "th"))
	for menu_id in NAV_IDS:
		_create_main_icon(menu_id)
	_build_gold_dropdown()
	# Replace the old yellow hamburger with the approved transparent Menu icon.
	# Do not delete the original menu or its gameplay signals/keyboard shortcuts.
	if is_instance_valid(gameplay) and is_instance_valid(gameplay.menu_toggle_button):
		gameplay.menu_toggle_button.hide()
	_restyle_gm_icon()
	_refresh_primary_captions()
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
	# Clicks are routed through _input; IGNORE lets two-finger camera gestures pass through.
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.size_flags_horizontal = Control.SIZE_FILL
	button.size_flags_vertical = Control.SIZE_FILL
	_no_backing(button)
	nav_grid.add_child(button)
	# One independent PNG for the ornament AND its ATTACHED, BLANK nameplate.
	var art := TextureRect.new()
	art.name = "IndependentIconAndBaseLayer"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = load(PRIMARY_ICON_PATH % str(PRIMARY_ASSET_NAMES[menu_id]))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(art)
	# Native Thai text, NOT printed on the PNG. Replaceable at runtime for any locale.
	var caption := Label.new()
	caption.name = "GridCaption"
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption.anchor_top = 0.77
	caption.anchor_bottom = 0.958
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_outline_color", Color("#020711"))
	caption.add_theme_constant_override("outline_size", 3)
	caption.add_theme_font_size_override("font_size", 14)
	button.add_child(caption)
	nav_buttons[menu_id] = button
	nav_labels[menu_id] = caption

func _restyle_gm_icon() -> void:
	if not is_instance_valid(gameplay) or not is_instance_valid(gameplay.owner_gm_button):
		return
	var gm_button: Button = gameplay.owner_gm_button
	# GM permission checks, authenticated routes and inner GM menu are unchanged.
	_no_backing(gm_button)
	gm_button.custom_minimum_size = Vector2.ZERO
	gm_button.size = MainNavLayout.slot(get_viewport(), 0).size
	var art := TextureRect.new()
	art.name = "GM_IllustrationAndBlankBase"
	art.texture = load(PRIMARY_ICON_PATH % "gm")
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gm_button.add_child(art)
	var caption := Label.new()
	caption.name = "GM_Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.anchor_left = 0.0
	caption.anchor_right = 1.0
	caption.anchor_top = 0.77
	caption.anchor_bottom = 0.958
	caption.add_theme_font_size_override("font_size", 13)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.add_theme_color_override("font_outline_color", Color("#020711"))
	caption.add_theme_constant_override("outline_size", 3)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gm_button.add_child(caption)

func _refresh_primary_captions() -> void:
	for menu_id in NAV_IDS:
		var caption: Label = nav_labels[menu_id]
		caption.text = MainNavLocale.label_for(str(menu_id), current_locale)
		var button: Button = nav_buttons[menu_id]
		button.tooltip_text = caption.text
	if is_instance_valid(gameplay) and is_instance_valid(gameplay.owner_gm_button):
		var gm_caption: Label = gameplay.owner_gm_button.get_node_or_null("GM_Caption")
		if is_instance_valid(gm_caption):
			gm_caption.text = MainNavLocale.label_for("GM", current_locale)


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

func _scale_gold_layers(button: Button, scale_factor: float) -> void:
	# Gold background/frame/highlight are independent and need native-size geometry.
	var backdrop: Panel = button.get_node("Layer_background")
	var backdrop_style: StyleBoxFlat = backdrop.get_theme_stylebox("panel")
	backdrop_style.set_corner_radius_all(roundi(26.0 * scale_factor))
	backdrop_style.shadow_size = roundi(3.0 * scale_factor)
	var frame: Panel = button.get_node("Layer_base_frame")
	var frame_style: StyleBoxFlat = frame.get_theme_stylebox("panel")
	frame_style.set_corner_radius_all(roundi(26.0 * scale_factor))
	frame_style.set_border_width_all(maxi(1,roundi(4.0 * scale_factor)))
	var highlight: Panel = button.get_node("Layer_gold_highlight")
	var highlight_style: StyleBoxFlat = highlight.get_theme_stylebox("panel")
	highlight_style.set_corner_radius_all(roundi(23.0 * scale_factor))
	highlight_style.border_width_top = maxi(1,roundi(2.0 * scale_factor))
	highlight_style.border_width_left = maxi(1,roundi(1.0 * scale_factor))
	highlight_style.border_width_right = maxi(1,roundi(1.0 * scale_factor))
	highlight_style.border_width_bottom = maxi(1,roundi(1.0 * scale_factor))
	highlight.offset_left = 5.0 * scale_factor
	highlight.offset_right = -5.0 * scale_factor
	highlight.offset_top = 5.0 * scale_factor
	highlight.offset_bottom = -5.0 * scale_factor

func _scale_menu_contents(scale_factor: float) -> void:
	# NEVER scale a Label/Panel node in portrait: it upscales 19px Thai glyphs
	# into blurry 60px textures. Set native font and control dimensions instead.
	menu_panel.scale = Vector2.ONE
	menu_panel.add_theme_stylebox_override("panel", _panel_style(scale_factor))
	var outer: VBoxContainer = menu_panel.get_node("MenuLayoutOuter")
	outer.add_theme_constant_override("separation", roundi(6.0 * scale_factor))
	menu_header.custom_minimum_size = Vector2(0.0, 66.0 * scale_factor)
	_scale_gold_layers(menu_header, scale_factor)
	var heading: HBoxContainer = menu_header.get_node("HeadingContent")
	heading.offset_left = 17.0 * scale_factor
	heading.offset_right = -17.0 * scale_factor
	heading.add_theme_constant_override("separation", roundi(12.0 * scale_factor))
	menu_header_icon.custom_minimum_size = Vector2.ONE * (45.0 * scale_factor)
	menu_header_title.add_theme_font_size_override("font_size", roundi(24.0 * scale_factor))
	menu_header_title.add_theme_constant_override("outline_size", roundi(5.0 * scale_factor))
	var header_arrow: TextureRect = heading.get_node("HeaderUp")
	header_arrow.custom_minimum_size = Vector2.ONE * (32.0 * scale_factor)
	row_column.add_theme_constant_override("separation", roundi(3.0 * scale_factor))
	for row in row_buttons:
		row.custom_minimum_size = Vector2(0.0, 55.0 * scale_factor)
		_scale_gold_layers(row, scale_factor)
		var contents: HBoxContainer = row.get_node("RowContents")
		contents.offset_left = 15.0 * scale_factor
		contents.offset_right = -15.0 * scale_factor
		contents.add_theme_constant_override("separation", roundi(11.0 * scale_factor))
		var artwork: TextureRect = contents.get_node("RowIcon")
		artwork.custom_minimum_size = Vector2.ONE * (44.0 * scale_factor)
		var caption: Label = contents.get_node("RowCaption")
		caption.add_theme_font_size_override("font_size", roundi(19.0 * scale_factor))
		caption.add_theme_constant_override("outline_size", roundi(5.0 * scale_factor))
		var arrow: TextureRect = contents.get_node("RowChevron")
		arrow.custom_minimum_size = Vector2.ONE * (29.0 * scale_factor)
	var hint: Label = row_column.get_node_or_null("OnlineHint")
	if is_instance_valid(hint):
		hint.add_theme_font_size_override("font_size", roundi(15.0 * scale_factor))

func _panel_style(scale_factor: float = 1.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#160F09F2")
	s.border_color = Color("#DDA128")
	s.set_border_width_all(maxi(1,roundi(3.0 * scale_factor)))
	s.set_corner_radius_all(roundi(19.0 * scale_factor))
	s.content_margin_left = 9.0 * scale_factor
	s.content_margin_right = 9.0 * scale_factor
	s.content_margin_top = 9.0 * scale_factor
	s.content_margin_bottom = 9.0 * scale_factor
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
	outer.name = "MenuLayoutOuter"
	outer.add_theme_constant_override("separation", 6)
	menu_panel.add_child(outer)
	menu_header = Button.new()
	menu_header.name = "RichMenuHeader"
	menu_header.custom_minimum_size = Vector2(0, 66)
	_gold_button(menu_header)
	outer.add_child(menu_header)
	var heading := HBoxContainer.new()
	heading.name = "HeadingContent"
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
	up.name = "HeaderUp"
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
	contents.name = "RowContents"
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_left = 15
	contents.offset_right = -15
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 11)
	row.add_child(contents)
	var artwork := TextureRect.new()
	artwork.name = "RowIcon"
	artwork.texture = _icon_texture(icon_name)
	artwork.custom_minimum_size = Vector2(44, 44)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(artwork)
	var caption := Label.new()
	caption.name = "RowCaption"
	caption.text = str(index + 1) + ". " + title
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_decorate_label(caption, 19)
	contents.add_child(caption)
	var arrow := TextureRect.new()
	arrow.name = "RowChevron"
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
		hint.name = "OnlineHint"
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
		# Fingers 2+ participate in camera pinch/drag; never steal those gestures.
		if not event.pressed or event.index >= 2:
			return
		point = event.position
	else:
		return
	# Scoped hitboxes, identical in principle to the proven Settings toggle.
	for menu_id in NAV_IDS:
		var button: Button = nav_buttons[menu_id]
		if button.is_visible_in_tree() and button.get_global_rect().has_point(point):
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
	if not is_instance_valid(gameplay):
		return
	var requested_locale: String = str(GameState.settings.get("language", "th"))
	if requested_locale != current_locale:
		current_locale = requested_locale
		_refresh_primary_captions()
	var modal_open: bool = (is_instance_valid(gameplay.panel) and gameplay.panel.visible) or (is_instance_valid(gameplay.silver_workspace) and gameplay.silver_workspace.visible)
	# Never cover Bag next-page buttons, item slots or modal confirmation controls.
	# Six new icons return automatically when the modal closes; GM/Settings are untouched.
	var visibility_changed := false
	for menu_id in NAV_IDS:
		var icon_button: Button = nav_buttons[menu_id]
		if icon_button.visible == modal_open:
			icon_button.visible = not modal_open
			visibility_changed = true
	if modal_open and not current_menu.is_empty():
		_close_menu()
	elif visibility_changed:
		_update_web_diagnostics()

func _responsive() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var slots: Array[Rect2] = MainNavLayout.slots(get_viewport())
	var portrait: bool = view.y > view.x
	var responsive = load("res://scripts/responsive_ui.gd")
	var bounds: Rect2 = responsive.safe_bounds(get_viewport())
	var touch_scale: float = responsive.input_scale(bounds, float(GameState.settings.get("ui_scale", 1.0))) if portrait else 1.0
	var icon_width: float = slots[2].size.x
	var gap: float = slots[3].position.x - slots[2].end.x
	# One row of six new buttons occupies slots 2..7.
	# The original GM and Settings nodes use the same geometry for slots 0..1.
	nav_grid.columns = 6
	nav_grid.add_theme_constant_override("h_separation", roundi(gap))
	nav_grid.add_theme_constant_override("v_separation", 0)
	nav_grid.position = slots[2].position
	nav_grid.size = Vector2(slots[7].end.x - slots[2].position.x, slots[2].size.y)
	for i in range(NAV_IDS.size()):
		var menu_id: String = str(NAV_IDS[i])
		var slot_rect: Rect2 = slots[i + 2]
		var button: Button = nav_buttons[menu_id]
		button.custom_minimum_size = slot_rect.size
		button.size = slot_rect.size
		var caption: Label = nav_labels[menu_id]
		var txt: String = caption.text
		var factor: float = 0.19 if txt.length() > 6 else 0.24
		caption.add_theme_font_size_override("font_size", roundi(clampf(icon_width * factor, 9.0 * touch_scale, 19.0 * touch_scale)))
		caption.add_theme_constant_override("outline_size", maxi(2, roundi(3.0 * touch_scale)))
	nav_grid.queue_sort()
	# The GM original click/permission code is unchanged.
	if is_instance_valid(gameplay) and is_instance_valid(gameplay.owner_gm_button):
		var gm_button: Button = gameplay.owner_gm_button
		gm_button.scale = Vector2.ONE
		gm_button.custom_minimum_size = slots[0].size
		gm_button.position = slots[0].position
		gm_button.size = slots[0].size
		var gm_caption: Label = gm_button.get_node_or_null("GM_Caption")
		if is_instance_valid(gm_caption):
			gm_caption.add_theme_font_size_override("font_size", roundi(clampf(icon_width * 0.24, 10.0 * touch_scale, 19.0 * touch_scale)))
	if not current_menu.is_empty():
		var menu_y: float = slots[2].end.y + 5.0 * touch_scale
		var item_count: int = row_buttons.size()
		var needed_height: float = 66.0 + 6.0 + 2.0 * 9.0 + float(item_count) * 55.0 + float(maxi(0, item_count - 1)) * 3.0 + (45.0 if current_menu not in ["Bag", "Menu"] else 0.0)
		_scale_menu_contents(touch_scale)
		var menu_width: float = minf(548.0 * touch_scale, view.x - 20.0 * touch_scale)
		var max_height: float = maxf(140.0 * touch_scale, view.y - menu_y - 10.0 * touch_scale)
		var min_left: float = 10.0 * touch_scale
		var desired_left: float = slots[7].end.x - menu_width
		var max_left: float = maxf(min_left, view.x - menu_width - min_left)
		menu_panel.position = Vector2(clampf(desired_left, min_left, max_left), menu_y)
		menu_panel.size = Vector2(menu_width, minf(needed_height * touch_scale, max_height))
	_update_web_diagnostics()
	call_deferred("_update_web_diagnostics")

func _update_web_diagnostics() -> void:
	if not OS.has_feature("web"):
		return
	var rectangles: Dictionary = {}
	var caption_texts: Dictionary = {}
	for menu_id in NAV_IDS:
		var rect: Rect2 = (nav_buttons[menu_id] as Button).get_global_rect()
		rectangles[menu_id] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
		caption_texts[menu_id] = (nav_labels[menu_id] as Label).text
	var area: Rect2 = menu_panel.get_global_rect()
	var data := {
		"buttons": rectangles,
		"all_slots": MainNavLayout.slots(get_viewport()).map(func(r: Rect2): return [r.position.x, r.position.y, r.size.x, r.size.y]),
		"caption_texts": caption_texts,
		"standalone_art": true,
		"same_row": true,
		"locale": current_locale,
		"native_grid": nav_grid is GridContainer,
		"open": not current_menu.is_empty(),
		"menu": current_menu,
		"rows": row_buttons.size(),
		"items": row_targets,
		"panel": [area.position.x, area.position.y, area.size.x, area.size.y],
		"legacy_menu_hidden": is_instance_valid(gameplay) and not gameplay.menu_toggle_button.visible,
		"icons_visible": (nav_buttons["Bag"] as Button).visible
	}
	JavaScriptBridge.eval("window.leoMainRichNav = " + JSON.stringify(data), true)
