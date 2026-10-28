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
	# One top header: gear lives INSIDE the gold frame; rows drop directly below.
	toggle = Button.new()
	toggle.text = ""
	toggle.tooltip_text = "ตั้งค่าเกม"
	toggle.anchor_left = 1.0
	toggle.anchor_right = 1.0
	toggle.anchor_top = 0.0
	toggle.anchor_bottom = 0.0
	toggle.pressed.connect(_toggle)
	for state in ["normal", "hover", "pressed"]:
		toggle.add_theme_stylebox_override(state, _gold_style())
	root.add_child(toggle)
	var header_content := HBoxContainer.new()
	header_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header_content.offset_left = 17
	header_content.offset_right = -17
	header_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle.add_child(header_content)
	var gear := Label.new()
	gear.text = "⚙"
	gear.custom_minimum_size.x = 48
	gear.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gear.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gear.add_theme_font_size_override("font_size", 37)
	gear.add_theme_color_override("font_color", Color("#168FF5"))
	gear.add_theme_color_override("font_outline_color", Color("#061D40"))
	gear.add_theme_constant_override("outline_size", 4)
	header_content.add_child(gear)
	var header_title := Label.new()
	header_title.text = "ตั้งค่าเกม"
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_title.add_theme_font_size_override("font_size", 25)
	header_title.add_theme_color_override("font_color", Color.WHITE)
	header_title.add_theme_color_override("font_outline_color", Color.BLACK)
	header_title.add_theme_constant_override("outline_size", 5)
	header_content.add_child(header_title)
	var chevron := Label.new()
	chevron.name = "Chevron"
	chevron.text = "⌄"
	chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chevron.add_theme_font_size_override("font_size", 28)
	chevron.add_theme_color_override("font_color", Color.WHITE)
	chevron.add_theme_color_override("font_outline_color", Color.BLACK)
	chevron.add_theme_constant_override("outline_size", 4)
	header_content.add_child(chevron)
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
	var chevron := toggle.get_node("HBoxContainer/Chevron") as Label
	chevron.text = "⌃" if panel.visible else "⌄"

func _responsive() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var width := minf(640.0, viewport_size.x - 20.0)
	var header_height := 66.0
	# Header is always the first row; menu expands downward, never as a centered popup.
	var x_right := -12.0
	var x_left := x_right - width
	toggle.offset_left = x_left
	toggle.offset_right = x_right
	toggle.offset_top = 12.0
	toggle.offset_bottom = 12.0 + header_height
	panel.offset_left = x_left
	panel.offset_right = x_right
	panel.offset_top = 12.0 + header_height + 4.0
	panel.offset_bottom = minf(viewport_size.y - 8.0, 12.0 + header_height + 4.0 + 10.0 * 64.0 + 22.0)
