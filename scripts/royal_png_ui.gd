extends RefCounted
## The actual PNG sprite atlas, split into individual reusable 9-slice sprites.
## None of these textures include live text, inventory icons, or player data.
const ATLAS_PATH := "res://assets/ui/royal/royal_atlas.png"

static func style(kind: String) -> StyleBoxTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ATLAS_PATH)
	var edge_x := 24.0
	var edge_y := 20.0
	var pad_x := 8.0
	var pad_y := 5.0
	match kind:
		"panel":
			atlas.region = Rect2(0, 0, 256, 256)
			edge_x = 34.0
			edge_y = 34.0
		"sidebar":
			atlas.region = Rect2(256, 0, 256, 256)
			edge_x = 34.0
			edge_y = 34.0
		"button_selected":
			atlas.region = Rect2(256, 256, 256, 64)
		"button_hover":
			atlas.region = Rect2(0, 320, 256, 64)
		"button_normal":
			atlas.region = Rect2(0, 256, 256, 64)
		"button_small":
			atlas.region = Rect2(256, 384, 256, 64)
		"slot_filled":
			atlas.region = Rect2(64, 384, 64, 64)
			edge_x = 14.0
			edge_y = 14.0
			pad_x = 1.0
			pad_y = 1.0
		"slot_empty":
			atlas.region = Rect2(0, 384, 64, 64)
			edge_x = 14.0
			edge_y = 14.0
			pad_x = 1.0
			pad_y = 1.0
		"pet_frame":
			atlas.region = Rect2(128, 384, 128, 128)
			edge_x = 24.0
			edge_y = 24.0
			pad_x = 5.0
			pad_y = 5.0
		_:
			atlas.region = Rect2(0, 256, 256, 64)
	var result := StyleBoxTexture.new()
	result.texture = atlas
	result.draw_center = true
	result.texture_margin_left = edge_x
	result.texture_margin_right = edge_x
	result.texture_margin_top = edge_y
	result.texture_margin_bottom = edge_y
	result.content_margin_left = pad_x
	result.content_margin_right = pad_x
	result.content_margin_top = pad_y
	result.content_margin_bottom = pad_y
	return result
