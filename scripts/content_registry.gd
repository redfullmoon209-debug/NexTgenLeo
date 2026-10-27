extends RefCounted
## Local artist-content integration point. No runtime remote downloads.
## Scene paths must be under res://content/; empty entries keep placeholders.
const MANIFEST_PATH := "res://content/asset_manifest.json"

static func manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not (data is Dictionary) or int(data.get("version", 0)) != 1:
		return {}
	return data

static func _safe_scene(value: Variant) -> PackedScene:
	if typeof(value) != TYPE_STRING:
		return null
	var scene_path: String = str(value)
	if not scene_path.begins_with("res://content/") or not scene_path.ends_with(".tscn") or scene_path.contains(".."):
		return null
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		return null
	var resource: Resource = ResourceLoader.load(scene_path)
	return resource as PackedScene

static func character_scene(gender: String) -> PackedScene:
	var data: Dictionary = manifest()
	var characters: Variant = data.get("characters", {})
	if not characters is Dictionary or gender not in ["Male", "Female"]:
		return null
	return _safe_scene(characters.get(gender, ""))

static func zone_scene(index: int) -> PackedScene:
	if index < 0 or index >= 5:
		return null
	var data: Dictionary = manifest()
	var zones: Variant = data.get("zones", {})
	if not zones is Dictionary:
		return null
	return _safe_scene(zones.get(str(index), ""))
