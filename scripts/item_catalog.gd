extends RefCounted
class_name LeoItemCatalog

const ITEMS := {
    "exp_2x_1h": {"name": "EXP x2 1h", "kind": "exp", "cost": 25, "glyph": "✦", "hours": 1, "description": "Prototype asset ID: exp_2x_1h"},
    "exp_2x_6h": {"name": "EXP x2 6h", "kind": "exp", "cost": 100, "glyph": "✦", "hours": 6, "description": "Prototype asset ID: exp_2x_6h"},
    "exp_2x_12h": {"name": "EXP x2 12h", "kind": "exp", "cost": 180, "glyph": "✦", "hours": 12, "description": "Prototype asset ID: exp_2x_12h"},
    "exp_2x_24h": {"name": "EXP x2 24h", "kind": "exp", "cost": 300, "glyph": "✦", "hours": 24, "description": "Prototype asset ID: exp_2x_24h"},
    "buff_attack_20": {"name": "Attack +20%", "kind": "buff", "cost": 80, "glyph": "⚔", "hours": 0, "description": "Prototype asset ID: buff_attack_20"},
    "buff_defense_20": {"name": "Defense +20%", "kind": "buff", "cost": 80, "glyph": "◆", "hours": 0, "description": "Prototype asset ID: buff_defense_20"},
    "buff_hp_20": {"name": "Max HP +20%", "kind": "buff", "cost": 80, "glyph": "♥", "hours": 0, "description": "Prototype asset ID: buff_hp_20"},
    "city_warp": {"name": "City Warp Scroll", "kind": "consumable", "cost": 20, "glyph": "↪", "hours": 0, "description": "Prototype asset ID: city_warp"},
    "sword_basic": {"name": "Training Sword", "kind": "weapon", "cost": 40, "glyph": "⚔", "hours": 0, "description": "Prototype asset ID: sword_basic"},
    "rifle_basic": {"name": "Training Rifle", "kind": "weapon", "cost": 40, "glyph": "➤", "hours": 0, "description": "Prototype asset ID: rifle_basic"},
    "kunai_basic": {"name": "Training Kunai", "kind": "weapon", "cost": 40, "glyph": "✧", "hours": 0, "description": "Prototype asset ID: kunai_basic"},
    "future_weapon": {"name": "Future Weapon", "kind": "weapon", "cost": 40, "glyph": "★", "hours": 0, "description": "Prototype asset ID: future_weapon"},
    "helmet_basic": {"name": "Helmet", "kind": "equipment", "cost": 25, "glyph": "♜", "hours": 0, "description": "Prototype asset ID: helmet_basic"},
    "chest_basic": {"name": "Armor", "kind": "equipment", "cost": 25, "glyph": "▣", "hours": 0, "description": "Prototype asset ID: chest_basic"},
    "gloves_basic": {"name": "Gloves", "kind": "equipment", "cost": 25, "glyph": "◈", "hours": 0, "description": "Prototype asset ID: gloves_basic"},
    "pants_basic": {"name": "Pants", "kind": "equipment", "cost": 25, "glyph": "▥", "hours": 0, "description": "Prototype asset ID: pants_basic"},
    "boots_basic": {"name": "Boots", "kind": "equipment", "cost": 25, "glyph": "♟", "hours": 0, "description": "Prototype asset ID: boots_basic"},
    "ring_basic": {"name": "Ring", "kind": "equipment", "cost": 25, "glyph": "◉", "hours": 0, "description": "Prototype asset ID: ring_basic"},
    "pet_food": {"name": "Pet Food", "kind": "pet", "cost": 15, "glyph": "●", "hours": 0, "description": "Prototype asset ID: pet_food"},
    "auto_loot_stone": {"name": "Auto Loot Stone", "kind": "pet", "cost": 120, "glyph": "◇", "hours": 0, "description": "Prototype asset ID: auto_loot_stone"},
    "pet_affinity": {"name": "Pet Affinity Gift", "kind": "pet", "cost": 30, "glyph": "♥", "hours": 0, "description": "Prototype asset ID: pet_affinity"},
    "upgrade_stone": {"name": "Upgrade Stone", "kind": "material", "cost": 35, "glyph": "◆", "hours": 0, "description": "Prototype asset ID: upgrade_stone"},
    "craft_material": {"name": "Craft Material", "kind": "material", "cost": 10, "glyph": "◈", "hours": 0, "description": "Prototype asset ID: craft_material"},
    "upgrade_1": {"name": "Upgrade +1", "kind": "equipment", "cost": 60, "glyph": "✦", "hours": 0, "description": "Prototype asset ID: upgrade_1"},
    "upgrade_2": {"name": "Upgrade +2", "kind": "equipment", "cost": 120, "glyph": "✦", "hours": 0, "description": "Prototype asset ID: upgrade_2"},
    "upgrade_3": {"name": "Upgrade +3", "kind": "equipment", "cost": 180, "glyph": "✦", "hours": 0, "description": "Prototype asset ID: upgrade_3"},
    "upgrade_4": {"name": "Upgrade +4", "kind": "equipment", "cost": 240, "glyph": "✦", "hours": 0, "description": "Prototype asset ID: upgrade_4"},
    "upgrade_5": {"name": "Upgrade +5", "kind": "equipment", "cost": 300, "glyph": "✦", "hours": 0, "description": "Prototype asset ID: upgrade_5"},
    "upgrade_6": {"name": "Upgrade +6", "kind": "equipment", "cost": 360, "glyph": "✦", "hours": 0, "description": "Prototype asset ID: upgrade_6"},
    "upgrade_7": {"name": "Upgrade +7", "kind": "equipment", "cost": 420, "glyph": "✦", "hours": 0, "description": "Prototype asset ID: upgrade_7"},
    "upgrade_8": {"name": "Upgrade +8", "kind": "equipment", "cost": 480, "glyph": "✦", "hours": 0, "description": "Prototype asset ID: upgrade_8"},
    "upgrade_9": {"name": "Upgrade +9", "kind": "equipment", "cost": 540, "glyph": "✦", "hours": 0, "description": "Prototype asset ID: upgrade_9"},
    "upgrade_10": {"name": "Upgrade +10", "kind": "equipment", "cost": 600, "glyph": "✦", "hours": 0, "description": "Prototype asset ID: upgrade_10"},
}

func ids() -> Array:
    return ITEMS.keys()

func get_item(id: String) -> Dictionary:
    return ITEMS.get(id, {})

func icon_path(id: String) -> String:
    return "res://assets/icons/" + id + ".png"

func model_path(id: String) -> String:
    return "res://assets/models/" + id + ".glb"
