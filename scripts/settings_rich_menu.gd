extends CanvasLayer
## Isolated, four-component Settings Rich Menu. No image crops or gameplay changes.
## Icon: vector glyph; Text: Label; Background: StyleBox fill; Frame: StyleBox border.
const TITLES := ["กราฟิกและหน้าจอ", "เสียง", "การควบคุม", "จัดตำแหน่ง HUD", "ตั้งค่า Auto Hunt", "ตั้งค่า Auto Potion", "การแจ้งเตือน", "ภาษา", "บัญชีและความปลอดภัย", "ออกจากเกม"]
const ICONS := ["▣", "◖))", "✣", "▦", "⚔", "♥", "♟", "◉", "⬡", "⇥"]
const ICON_COLORS := ["#149cf4", "#1198f2", "#168ff3", "#1a9dff", "#d8e7f4", "#f0444d", "#ffcd18", "#39bbd5", "#178ff1", "#248df5"]
var panel: PanelContainer
var toggle: Button
var list: VBoxContainer

func _ready() -> void:
	layer = 30
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	toggle = Button.new()
	toggle.text = "⚙"
	toggle.tooltip_text = "ตั้งค่าเกม"
	toggle.add_theme_font_size_override("font_size", 28)
	toggle.custom_minimum_size = Vector2(56, 52)
	toggle.anchor_left = 1.0
	toggle.anchor_right = 1.0
	toggle.offset_left = -265
	toggle.offset_right = -209
	toggle.offset_top = 10
	toggle.offset_bottom = 62
	toggle.pressed.connect(_toggle)
	root.add_child(toggle)
	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -320
	panel.offset_right = 320
	panel.offset_top = -360
	panel.offset_bottom = 360
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	panel.add_child(outer)
	var heading := Button.new()
	heading.text = "⚙   ตั้งค่าเกม   ⌃"
	heading.custom_minimum_size.y = 65
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color.WHITE)
	heading.add_theme_color_override("font_outline_color", Color.BLACK)
	heading.add_theme_constant_override("outline_size", 5)
	heading.add_theme_stylebox_override("normal", _gold_style())
	heading.add_theme_stylebox_override("hover", _gold_style())
	heading.pressed.connect(_toggle)
	outer.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	for i in range(TITLES.size()):
		_add_row(i)
	panel.visible = false
	get_viewport().size_changed.connect(_responsive)
	_responsive()

func _gold_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#F5AD21")
	s.border_color = Color("#17100A")
	s.set_border_width_all(4)
	s.set_corner_radius_all(28)
	s.shadow_color = Color("#050301AA")
	s.shadow_size = 3
	s.content_margin_left = 12
	s.content_margin_right = 12
	return s

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
	button.custom_minimum_size = Vector2(0, 59)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", _gold_style())
	button.add_theme_stylebox_override("hover", _gold_style())
	button.add_theme_stylebox_override("pressed", _gold_style())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func(): print("Settings selected: ", TITLES[index]))
	list.add_child(button)
	var contents := HBoxContainer.new()
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_left = 15
	contents.offset_right = -15
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 12)
	button.add_child(contents)
	var icon := Label.new()
	icon.text = ICONS[index]
	icon.custom_minimum_size.x = 47
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 28)
	icon.add_theme_color_override("font_color", Color(ICON_COLORS[index]))
	icon.add_theme_color_override("font_outline_color", Color("#092340"))
	icon.add_theme_constant_override("outline_size", 3)
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
	var arrow := Label.new()
	arrow.text = "❯"
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 24)
	arrow.add_theme_color_override("font_color", Color.WHITE)
	arrow.add_theme_color_override("font_outline_color", Color.BLACK)
	arrow.add_theme_constant_override("outline_size", 4)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(arrow)

func _toggle() -> void:
	panel.visible = not panel.visible

func _responsive() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var width := minf(640.0, viewport_size.x - 20.0)
	var height := minf(720.0, viewport_size.y - 20.0)
	panel.offset_left = -width / 2.0
	panel.offset_right = width / 2.0
	panel.offset_top = -height / 2.0
	panel.offset_bottom = height / 2.0
