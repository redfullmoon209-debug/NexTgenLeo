extends CanvasLayer
const MainNavLocale = preload("res://scripts/main_nav_locale.gd")
const MainNavLayout = preload("res://scripts/main_nav_layout.gd")
## Isolated, four-component Settings Rich Menu. No image crops or gameplay changes.
## Independent layers: SVG icons / editable Thai Labels / gold background Panel / frame Panel.
const TITLES := ["กราฟิกและหน้าจอ", "เสียง", "การควบคุม", "จัดตำแหน่ง HUD", "ตั้งค่า Auto Hunt", "ตั้งค่า Auto Potion", "การแจ้งเตือน", "ภาษา", "บัญชีและความปลอดภัย", "ออกจากเกม"]
const ICON_FILES := ["graphics", "audio", "controls", "hud", "auto_hunt", "auto_potion", "notifications", "language", "security", "exit"]
var panel: PanelContainer
var toggle: Button
var header_title: Label
var header_arrow: TextureRect
var header_content: HBoxContainer
var closed_gear: TextureRect
var closed_caption: Label
var list: VBoxContainer

func _ready() -> void:
	layer = 30
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui_theme := Theme.new()
	ui_theme.default_font = load("res://assets/fonts/NotoSansThai.ttf")
	root.theme = ui_theme
	add_child(root)
	# One top header: gear lives INSIDE the gold frame; rows drop directly below.
	toggle = Button.new()
	toggle.text = ""
	toggle.tooltip_text = ""
	toggle.anchor_left = 1.0
	toggle.anchor_right = 1.0
	toggle.anchor_top = 0.0
	toggle.anchor_bottom = 0.0
	# Handle the header hitbox directly; Godot Web can lose Button.pressed beneath canvas overlays.
	root.add_child(toggle)
	_decorate_button(toggle)
	header_content = HBoxContainer.new()
	header_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header_content.offset_left = 17
	header_content.offset_right = -17
	header_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle.add_child(header_content)
	closed_gear = TextureRect.new()
	closed_gear.name = "PrimarySettingsIllustration"
	closed_gear.texture = load("res://assets/ui/main_nav/standalone/settings.png")
	closed_gear.custom_minimum_size = Vector2(83, 102)
	closed_gear.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	closed_gear.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	closed_gear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_content.add_child(closed_gear)
	header_title = Label.new()
	header_title.text = "ตั้งค่าเกม"
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_title.add_theme_font_size_override("font_size", 25)
	header_title.add_theme_color_override("font_color", Color.WHITE)
	header_title.add_theme_color_override("font_outline_color", Color.BLACK)
	header_title.add_theme_constant_override("outline_size", 5)
	header_content.add_child(header_title)
	header_arrow = TextureRect.new()
	header_arrow.name = "Chevron"
	header_arrow.texture = load("res://assets/ui/settings/icons/chevron_down.svg")
	header_arrow.custom_minimum_size = Vector2(32, 32)
	header_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_content.add_child(header_arrow)
	# The attached navy nameplate belongs to the PNG, but this text stays native.
	closed_caption = Label.new()
	closed_caption.name = "NativeSettingsCaption"
	closed_caption.text = MainNavLocale.label_for("Settings", str(GameState.settings.get("language", "th")))
	closed_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	closed_caption.anchor_top = 0.60
	closed_caption.anchor_bottom = 0.82
	closed_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	closed_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	closed_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed_caption.add_theme_font_size_override("font_size", 13)
	closed_caption.add_theme_color_override("font_color", Color.WHITE)
	closed_caption.add_theme_color_override("font_outline_color", Color("#020711"))
	closed_caption.add_theme_constant_override("outline_size", 3)
	toggle.add_child(closed_caption)
	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	panel.add_child(outer)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	scroll.add_child(list)
	for i in range(TITLES.size()):
		_add_row(i)
	panel.visible = false
	header_title.hide()
	header_arrow.hide()
	get_viewport().size_changed.connect(_responsive)
	_responsive()

func _decorate_button(button: Button) -> void:
	# Four real independent Godot elements, with reliable rendering on web/mobile:
	# Background Panel, Frame Panel, Icon TextureRect, editable Thai Label.
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var background := Panel.new()
	background.name = "Layer_background"
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#F5A918")
	fill.set_corner_radius_all(26)
	fill.shadow_color = Color("#4B2608A0")
	fill.shadow_size = 3
	background.add_theme_stylebox_override("panel", fill)
	button.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := Panel.new()
	frame.name = "Layer_base_frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var trim := StyleBoxFlat.new()
	trim.bg_color = Color.TRANSPARENT
	trim.border_color = Color("#201007")
	trim.set_border_width_all(4)
	trim.set_corner_radius_all(26)
	frame.add_theme_stylebox_override("panel", trim)
	button.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Beveled gold inner border and light top band are independent visual accents.
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
	s.set_corner_radius_all(20)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 9
	s.content_margin_bottom = 9
	return s

func _add_row(index: int) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 55)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func(): print("Settings selected: ", TITLES[index]))
	list.add_child(button)
	_decorate_button(button)
	var contents := HBoxContainer.new()
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_left = 15
	contents.offset_right = -15
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 12)
	button.add_child(contents)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/ui/settings/icons/%s.svg" % ICON_FILES[index])
	icon.custom_minimum_size = Vector2(47, 47)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(icon)
	var label := Label.new()
	label.text = str(index + 1) + ". " + TITLES[index]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(label)
	var arrow := TextureRect.new()
	arrow.name = "Layer_chevron"
	arrow.texture = load("res://assets/ui/settings/icons/chevron_right.svg")
	arrow.custom_minimum_size = Vector2(28, 28)
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(arrow)

func _process(_delta: float) -> void:
	# A locale switch only replaces Label text, never re-generates the PNG asset.
	var label_text: String = MainNavLocale.label_for("Settings", str(GameState.settings.get("language", "th")))
	if closed_caption.text != label_text:
		closed_caption.text = label_text

func _input(event: InputEvent) -> void:
	# Scoped click/touch hit area only. No fullscreen interception and no HUD changes.
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
	if toggle.get_global_rect().has_point(point):
		_toggle()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	panel.visible = not panel.visible
	header_title.visible = panel.visible
	header_arrow.visible = panel.visible
	header_arrow.texture = load("res://assets/ui/settings/icons/chevron_up.svg") if panel.visible else load("res://assets/ui/settings/icons/chevron_down.svg")
	_responsive()

func _update_web_diagnostics() -> void:
	if not OS.has_feature("web"):
		return
	var r := toggle.get_global_rect()
	var p := panel.get_global_rect()
	var data := {"open": panel.visible, "header": [r.position.x, r.position.y, r.size.x, r.size.y], "panel": [p.position.x, p.position.y, p.size.x, p.size.y], "rows": list.get_child_count(), "native_caption": closed_caption.text}
	JavaScriptBridge.eval("window.leoSettingsRich = " + JSON.stringify(data), true)

func _responsive() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var is_wide := viewport_size.x >= 1160.0
	var header_height := 66.0
	var menu_width := minf(560.0, viewport_size.x - 20.0)
	# Collapsed gear occupies only its OWN small button, not the GM / menu buttons.
	# 1280px: x=892..964, GM starts at x=975. All other HUD remains untouched.
	var closed_slot: Rect2 = MainNavLayout.slot(get_viewport(), 1)
	var open_right := -180.0 if is_wide else -10.0
	var menu_top := 12.0 if is_wide else 10.0
	# Closed: show ONLY the blue gear. Remove the yellow/gold background and borders.
	# Open: restore the exact approved golden header and ten menu rows.
	for layer_name in ["Layer_background", "Layer_base_frame", "Layer_gold_highlight"]:
		var decoration := toggle.get_node_or_null(layer_name) as CanvasItem
		if decoration != null:
			decoration.visible = panel.visible
	header_content.offset_left = 17.0 if panel.visible else 0.0
	header_content.offset_right = -17.0 if panel.visible else 0.0
	header_content.alignment = BoxContainer.ALIGNMENT_BEGIN if panel.visible else BoxContainer.ALIGNMENT_CENTER
	# Only the COLLAPSED main-button art changes; the approved gold dropdown stays intact.
	closed_caption.visible = not panel.visible
	closed_gear.texture = load("res://assets/ui/settings/icons/gear.svg") if panel.visible else load("res://assets/ui/main_nav/standalone/settings.png")
	closed_gear.custom_minimum_size = Vector2(48, 48) if panel.visible else closed_slot.size
	if panel.visible:
		toggle.offset_left = open_right - menu_width
		toggle.offset_right = open_right
		toggle.offset_top = menu_top
		toggle.offset_bottom = menu_top + header_height
	else:
		# Slot 1 has the same Y and size as GM and the six navigation icons.
		toggle.offset_left = closed_slot.position.x - viewport_size.x
		toggle.offset_right = closed_slot.end.x - viewport_size.x
		toggle.offset_top = closed_slot.position.y
		toggle.offset_bottom = closed_slot.end.y
		closed_caption.add_theme_font_size_override("font_size", roundi(clampf(closed_slot.size.x * 0.28, 10.0, 23.0)))
	panel.offset_left = open_right - menu_width
	panel.offset_right = open_right
	panel.offset_top = menu_top + header_height + 4.0
	panel.offset_bottom = minf(viewport_size.y - 8.0, menu_top + header_height + 4.0 + 10.0 * 55.0 + 9.0 * 3.0 + 22.0)
	_update_web_diagnostics()
