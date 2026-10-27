extends RefCounted
## Celestial Steel visual language: compact metallic frames and semantic action hues.
## Shapes are procedural so no third-party icon or texture assets are needed.

static func accent(action_id: int, faction_id: String = "") -> Color:
	if faction_id == "Light" and action_id >= 2 and action_id <= 5:
		return Color("#F0D9A0")
	if faction_id == "Dark" and action_id >= 2 and action_id <= 5:
		return Color("#C7A4FF")
	match action_id:
		0: return Color("#D7C58E") # Target
		1: return Color("#89D7DE") # Loot
		2: return Color("#FFB979") # Basic attack
		3: return Color("#72B6FF") # Skill 1
		4: return Color("#A5A0FF") # Skill 2
		5: return Color("#EE95D6") # Skill 3
		6: return Color("#80DBD1") # Dash
		7: return Color("#A1D787") # Auto
	return Color("#C5D0DC")

static func action_style(action_id: int, faction_id: String, state: String) -> StyleBoxFlat:
	var edge := accent(action_id, faction_id)
	var bg := Color("#11253D")
	match action_id:
		2: bg = Color("#442D35")
		3,4,5: bg = Color("#172C50")
		6: bg = Color("#153842")
		7: bg = Color("#244034")
		0: bg = Color("#354031")
		1: bg = Color("#193D46")
	if state == "hover": bg = bg.lightened(0.15)
	if state == "pressed": bg = bg.darkened(0.16); edge = edge.lightened(0.12)
	if state == "disabled": bg = Color("#1B2533"); edge = Color("#566477")
	var result := StyleBoxFlat.new()
	result.bg_color = bg
	result.border_color = edge
	result.set_border_width_all(2)
	result.border_width_top = 3
	result.set_corner_radius_all(42)
	result.anti_aliasing = true
	result.corner_detail = 12
	result.shadow_color = Color(edge.r * 0.20, edge.g * 0.25, edge.b * 0.30, 0.75)
	result.shadow_size = 8 if action_id == 2 else 5
	result.shadow_offset = Vector2(0, 2)
	result.content_margin_left = 3
	result.content_margin_right = 3
	result.content_margin_top = 3
	result.content_margin_bottom = 3
	return result

static func movement_style(kind: String, state: String) -> StyleBoxFlat:
	var edge := Color("#9CBFE6") if kind == "jump" else Color("#B7C4D7")
	var bg := Color("#15314B") if kind == "jump" else Color("#1B2B3D")
	if state == "hover": bg = bg.lightened(0.16)
	if state == "pressed": bg = bg.darkened(0.15)
	var result := StyleBoxFlat.new()
	result.bg_color = bg
	result.border_color = edge
	result.set_border_width_all(2)
	result.border_width_top = 3
	result.set_corner_radius_all(22)
	result.shadow_color = Color("#071322B8")
	result.shadow_size = 5
	result.shadow_offset = Vector2(0, 3)
	result.content_margin_left = 4
	result.content_margin_right = 4
	return result

static func panel_style(surface: Color = Color("#10233DEB"), highlight: Color = Color("#9FBFDD"), radius: int = 14) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = surface
	result.border_color = highlight
	result.set_border_width_all(1)
	result.border_width_top = 3
	result.set_corner_radius_all(radius)
	result.shadow_color = Color("#020915D9")
	result.shadow_size = 12
	result.shadow_offset = Vector2(0, 4)
	result.content_margin_left = 9
	result.content_margin_right = 9
	result.content_margin_top = 7
	result.content_margin_bottom = 7
	return result
