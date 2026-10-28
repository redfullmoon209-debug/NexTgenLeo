extends Node
## Non-destructive fantasy UI skin. Applies to runtime-generated controls
## without changing their signals, actions, inventory, or saved game data.
const NAVY := Color("#07142E")
const PANEL := Color("#0D2854")
const EDGE := Color("#D5A65A")
const GOLD := Color("#FFE4A1")
const TEXT := Color("#F8F5F0")
const MUTED := Color("#B2CBEC")
const BLUE := Color("#55B3FF")
var _tick := 0.0
var _normal: StyleBox
var _hover: StyleBox
var _pressed: StyleBox
var _disabled: StyleBoxFlat
var _focus: StyleBoxFlat
var _plate: StyleBox
var _input: StyleBoxFlat
var _progress_bg: StyleBoxFlat

func _ready() -> void:
	var png_style = load("res://scripts/royal_png_ui.gd")
	_normal = png_style.style("button_normal")
	_hover = png_style.style("button_hover")
	_pressed = png_style.style("button_selected")
	_disabled = _box(Color("#11213D"), Color("#51688A"), 9, 1)
	_focus = _box(Color.TRANSPARENT, GOLD, 9, 2)
	_plate = png_style.style("panel")
	_input = _box(PANEL, EDGE, 8, 2)
	_progress_bg = _box(Color("#040F25"), Color("#6B9DD9"), 6, 1)
	set_process(true)
	call_deferred("_refresh")

func _box(bg: Color, border: Color, radius: int, thickness: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(thickness)
	s.border_width_top = maxi(thickness, 2)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color("#1454AC9A")
	s.shadow_size = 5
	s.shadow_offset = Vector2(0, 2)
	s.content_margin_left = 8
	s.content_margin_right = 8
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
		b.add_theme_font_size_override("font_size", 16)
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
