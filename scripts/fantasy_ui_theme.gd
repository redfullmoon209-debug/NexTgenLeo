extends Node
## Non-destructive fantasy UI skin. Applies to runtime-generated controls
## without changing their signals, actions, inventory, or saved game data.
const NAVY := Color("#091a32")
const PANEL := Color("#142942")
const EDGE := Color("#b4c6db")
const GOLD := Color("#e0e9f5")
const TEXT := Color("#f1f6ff")
const MUTED := Color("#9bb1ca")
const BLUE := Color("#628ecb")
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
	_normal = _box(Color("#132941"), EDGE, 9, 1)
	_hover = _box(Color("#29486b"), GOLD, 9, 2)
	_pressed = _box(Color("#355879"), Color("#edf4fc"), 9, 2)
	_disabled = _box(Color("#17273e"), Color("#586d87"), 9, 1)
	_focus = _box(Color.TRANSPARENT, GOLD, 9, 2)
	_plate = _box(Color("#0c1d35f7"), Color("#bfcee1"), 12, 2)
	_plate.border_width_top = 3
	_plate.shadow_size = 9
	_plate.shadow_offset = Vector2(0, 4)
	_input = _box(PANEL, EDGE, 8, 1)
	_progress_bg = _box(Color("#081629"), Color("#526e8b"), 6, 1)
	set_process(true)
	call_deferred("_refresh")

func _box(bg: Color, border: Color, radius: int, thickness: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(thickness)
	s.border_width_top = maxi(thickness, 2)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color("#020712a8")
	s.shadow_size = 3
	s.shadow_offset = Vector2(0, 2)
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
	# Only inspect HUD controls; scanning every 3D world object on a timer
	# is unnecessary and expensive on mobile / software rendering.
	var main := get_parent()
	if main == null:
		return
	var hud_root: Variant = main.get("hud")
	if hud_root is Control:
		_visit(hud_root)

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
			var attack := _box(Color("#263d5e"), GOLD, 13, 2)
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
	elif control is TabContainer:
		control.add_theme_stylebox_override("panel", _plate)
		control.add_theme_stylebox_override("tab_selected", _hover)
		control.add_theme_stylebox_override("tab_unselected", _normal)
		control.add_theme_color_override("font_selected_color", GOLD)
		control.add_theme_color_override("font_unselected_color", TEXT)
