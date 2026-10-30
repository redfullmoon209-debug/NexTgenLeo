extends RefCounted
## Localization keys for the eight independent primary icons.
## Image files contain icon artwork + EMPTY attached nameplates only.
## Thai/English strings are rendered by native Godot Label nodes, NOT PNG pixels.
## Extend with new language codes without editing any artwork.
const LABELS := {
	"GM": {"th": "GM", "en": "GM"},
	"Settings": {"th": "ตั้งค่า", "en": "Settings"},
	"Status": {"th": "ตัวละคร", "en": "Character"},
	"Bag": {"th": "กระเป๋า", "en": "Bag"},
	"Menu": {"th": "เมนู", "en": "Menu"},
	"Guild": {"th": "กิลด์", "en": "Guild"},
	"Party": {"th": "ปาร์ตี้", "en": "Party"},
	"Friends": {"th": "เพื่อน", "en": "Friends"},
	"Notice": {"th": "ประกาศ", "en": "Notice"}
}

static func label_for(menu_id: String, language: String = "th") -> String:
	var translations: Dictionary = LABELS.get(menu_id, {})
	return str(translations.get(language, translations.get("th", menu_id)))
