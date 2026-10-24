extends Node
## NexTgenLeo gameplay state (prototype; server authority required for multiplayer).
signal progression_changed
signal inventory_changed
const MAX_CLASS := 10
const MAX_LEVEL := 100
const ELEMENTS := ["Earth", "Water", "Wind", "Fire", "Lightning", "Wood"]
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
var class_rank := 0
var level := 1
var exp := 0
var gold := 0
var cash := 0
var selected_element := ""
var selected_job := ""
var faction := ""
var hp := 100
var max_hp := 100
var stamina := 100
var max_stamina := 100
var inventory: Array[Dictionary] = []
var equipped: Dictionary = {}
var pet_level := 1

func exp_required() -> int:
	return 100 + (level - 1) * 35 + class_rank * 250

func add_exp(amount: int) -> void:
	if amount <= 0 or (class_rank == MAX_CLASS and level == MAX_LEVEL):
		return
	exp += amount
	while level < MAX_LEVEL and exp >= exp_required():
		exp -= exp_required()
		level += 1
		_recalculate_stats()
	if level == MAX_LEVEL:
		exp = 0
	progression_changed.emit()

func can_advance_class() -> bool:
	return level == MAX_LEVEL and class_rank < MAX_CLASS

func advance_class() -> bool:
	if not can_advance_class():
		return false
	class_rank += 1
	level = 1
	exp = 0
	_recalculate_stats()
	progression_changed.emit()
	return true

func select_element(element: String) -> bool:
	if class_rank < 3 or not ELEMENTS.has(element):
		return false
	selected_element = element
	progression_changed.emit()
	return true

func select_job(job: String) -> bool:
	if class_rank < 5 or job.strip_edges().is_empty():
		return false
	selected_job = job
	progression_changed.emit()
	return true

func select_faction(value: String) -> bool:
	if class_rank < 7 or not ["Light", "Dark"].has(value):
		return false
	faction = value
	progression_changed.emit()
	return true

func add_item(item_id: String, count: int = 1) -> bool:
	if item_id.is_empty() or count <= 0:
		return false
	for slot in inventory:
		if slot.get("id", "") == item_id and int(slot.get("count", 0)) < 99:
			var added: int = mini(count, 99 - int(slot["count"]))
			slot["count"] = int(slot["count"]) + added
			count -= added
			if count == 0:
				inventory_changed.emit()
				return true
	while count > 0:
		if inventory.size() >= 200:
			inventory_changed.emit()
			return false
		var stack: int = mini(count, 99)
		inventory.append({"id": item_id, "count": stack})
		count -= stack
	inventory_changed.emit()
	return true

func _recalculate_stats() -> void:
	max_hp = 100 + (level - 1) * 10 + class_rank * 100
	max_stamina = 100 + (level - 1) * 2 + class_rank * 20
	hp = max_hp
	stamina = max_stamina
