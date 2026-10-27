extends Node
## Non-destructive fantasy UI skin. Applies to runtime-generated controls
## without changing their signals, actions, inventory, or saved game data.
const NAVY := Color("#101b32")
const PANEL := Color("#152540")
const EDGE := Color("#7894b8")
const GOLD := Color("#f0cc84")
const TEXT := Color("#f0f5ff")
const MUTED := Color("#b5c5df")
const BLUE := Color("#527fc3")
var _tick := 0.0
var _normal: StyleBoxFlat
var _hover: StyleBoxFlat
var _pressed: StyleBoxFlat
var _disabled: StyleBoxFlat
var _focus: StyleBoxFlat
var _plate: StyleBoxFlat
var _input: StyleBoxFlat
var _progress_bg: StyleBoxFlat

func _ready() -> void:
	_normal = _box(Color("#1b3050"), EDGE, 10, 1)
	_hover = _box(Color("#294d76"), GOLD, 10, 2)
	_pressed = _box(Color("#365e8b"), GOLD, 10, 2)
	_disabled = _box(Color("#1b2537"), Color("#475268"), 10, 1)
	_focus = _box(Color.TRANSPARENT, GOLD, 10, 2)
	_plate = _box(Color("#101c34f0"), Color("#c6a96d"), 14, 2)
	_input = _box(PANEL, EDGE, 8, 1)
	_progress_bg = _box(Color("#0b1529"), Color("#49627f"), 6, 1)
	set_process(true)
	call_deferred("_refresh")

func _box(bg: Color, border: Color, radius: int, thickness: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(thickness)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _process(delta: float) -> void:
	_tick += delta
	if _tick >= 0.6:
		_tick = 0.0
		_refresh()

func _refresh() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	_visit(scene)

func _visit(node: Node) -> void:
	if node is Control and not node.has_meta("leo_fantasy_skin"):
		_skin(node)
		node.set_meta("leo_fantasy_skin", true)
	for child in node.get_children():
		_visit(child)

func _skin(control: Control) -> void:
	if control is Button:
		var b := control as Button
		b.add_theme_stylebox_override("normal", _normal)
		b.add_theme_stylebox_override("hover", _hover)
		b.add_theme_stylebox_override("pressed", _pressed)
		b.add_theme_stylebox_override("disabled", _disabled)
		b.add_theme_stylebox_override("focus", _focus)
		b.add_theme_color_override("font_color", TEXT)
		b.add_theme_color_override("font_hover_color", GOLD)
		b.add_theme_color_override("font_pressed_color", GOLD)
		b.add_theme_color_override("font_disabled_color", MUTED)
		b.add_theme_font_size_override("font_size", 15)
		if b.text.begins_with("ATK") or b.text.begins_with("1\n") or b.text.begins_with("2\n") or b.text.begins_with("3\n"):
			var attack := _box(Color("#263960"), GOLD, 13, 2)
			b.add_theme_stylebox_override("normal", attack)
	elif control is PanelContainer:
		control.add_theme_stylebox_override("panel", _plate)
	elif control is ProgressBar:
		var bar := control as ProgressBar
		bar.add_theme_stylebox_override("background", _progress_bg)
		var bar_color := BLUE
		var old_fill: StyleBox = bar.get_theme_stylebox("fill")
		if old_fill is StyleBoxFlat:
			bar_color = (old_fill as StyleBoxFlat).bg_color
		var fill := _box(bar_color, bar_color.lightened(0.2), 6, 0)
		fill.content_margin_top = 0
		fill.content_margin_bottom = 0
		bar.add_theme_stylebox_override("fill", fill)
	elif control is Label:
		var label := control as Label
		if label.name == "Value":
			label.add_theme_color_override("font_color", Color("#ffffff"))
			label.add_theme_font_size_override("font_size", 13)
		elif label.text.begins_with("NEX TGEN LEO"):
			label.add_theme_color_override("font_color", GOLD)
			label.add_theme_font_size_override("font_size", 21)
			label.add_theme_color_override("font_shadow_color", Color("#071329"))
			label.add_theme_constant_override("shadow_offset_x", 1)
			label.add_theme_constant_override("shadow_offset_y", 2)
		elif label.text.begins_with("PC:"):
			label.add_theme_color_override("font_color", MUTED)
		else:
			label.add_theme_color_override("font_color", TEXT)
	elif control is LineEdit:
		var edit := control as LineEdit
		edit.add_theme_stylebox_override("normal", _input)
		edit.add_theme_stylebox_override("focus", _focus)
		edit.add_theme_color_override("font_color", TEXT)
		edit.add_theme_color_override("font_placeholder_color", MUTED)
	elif control is TextEdit:
		control.add_theme_stylebox_override("normal", _input)
		control.add_theme_stylebox_override("focus", _focus)
		control.add_theme_color_override("font_color", TEXT)
	elif control is SpinBox:
		var spin := control as SpinBox
		spin.add_theme_color_override("font_color", TEXT)
	elif control is OptionButton:
		control.add_theme_stylebox_override("normal", _normal)
		control.add_theme_stylebox_override("hover", _hover)
	elif control is PopupPanel:
		control.add_theme_stylebox_override("panel", _plate)
	elif control is TabContainer:
		control.add_theme_stylebox_override("panel", _plate)
		control.add_theme_stylebox_override("tab_selected", _hover)
		control.add_theme_stylebox_override("tab_unselected", _normal)
		control.add_theme_color_override("font_selected_color", GOLD)
		control.add_theme_color_override("font_unselected_color", TEXT)
