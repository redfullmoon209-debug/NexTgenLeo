extends Node
## Offline sandbox state. Never accepted as multiplayer authority.
signal progression_changed
signal inventory_changed
signal appearance_changed
const MAX_CLASS := 10
const MAX_LEVEL := 100
const ELEMENTS := ["Earth", "Water", "Wind", "Fire", "Lightning", "Wood"]
const RARITIES := ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const SAVE_PATH := "user://character_v1.json"
var balance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
var class_rank := 0
var level := 1
var exp := 0
var gold := 150
var cash := 30
var selected_element := ""
var selected_path := ""
var selected_job := ""
var faction := ""
var gender := "Male"
var hp := 100
var max_hp := 100
var stamina := 100.0
var max_stamina := 100
var inventory: Array[Dictionary] = []
var equipped: Dictionary = {}
var pet_level := 1
var pet_exp := 0
var pet_stage := 1
var pet_enabled := true
var quest_state := "available"
var quest_kills := 0
var advancement_ready := false
var map_index := 0
var location := [0.0, 1.0, 0.0]
var buffs: Dictionary = {}
var settings := {"quality":"Medium", "ui_scale":1.0, "button_offsets":{}}
var skill_mode := "Target"
var skill_loadout := [0, 1, 2]

func _ready() -> void:
	if not load_game():
		add_item("potion", 5)
		add_item("sword")
		add_item("shirt")
		add_item("ore", 3)
	_recalculate_stats(false)

func exp_required() -> int:
	return int(balance.exp_base) + (level - 1) * int(balance.exp_per_level) + class_rank * int(balance.exp_per_class)

func add_exp(amount: int) -> void:
	if amount <= 0 or (class_rank == MAX_CLASS and level == MAX_LEVEL):
		return
	exp += amount * (2 if buff_active("exp") else 1)
	while level < MAX_LEVEL and exp >= exp_required():
		exp -= exp_required()
		level += 1
		_recalculate_stats()
	if level == MAX_LEVEL:
		exp = 0
	progression_changed.emit()

func can_advance_class() -> bool:
	return level == MAX_LEVEL and class_rank < MAX_CLASS and (class_rank > 2 or advancement_ready)

func advance_class() -> bool:
	if not can_advance_class():
		return false
	class_rank += 1
	level = 1
	exp = 0
	advancement_ready = false
	if class_rank <= 2:
		quest_state = "available"
		quest_kills = 0
	_recalculate_stats()
	progression_changed.emit()
	appearance_changed.emit()
	return true

func select_element(element: String) -> bool:
	if not selected_job.is_empty() and element != selected_element:
		return false
	if class_rank < 3 or not ELEMENTS.has(element):
		return false
	if selected_element != element:
		selected_job = ""
	selected_element = element
	selected_path = element
	progression_changed.emit()
	return true

func select_path(value: String) -> bool:
	if class_rank < 3 or value not in balance.paths:
		return false
	selected_path = value
	appearance_changed.emit()
	return true

func select_job(job: String) -> bool:
	if not selected_job.is_empty():
		return selected_job == job
	var definition := job_definition(job)
	if class_rank < 5 or definition.is_empty() or definition.element != selected_element:
		return false
	if "weapon" in equipped:
		if inventory.size() >= 200: return false
		inventory.append(equipped.weapon)
	selected_job = job
	equipped["weapon"] = {"id":definition.weapon,"count":1,"enhancement":0}
	appearance_changed.emit()
	progression_changed.emit()
	return true

func select_faction(value: String) -> bool:
	if class_rank < 7 or value not in ["Light", "Dark"]:
		return false
	faction = value
	progression_changed.emit()
	return true

func height_meters() -> float:
	var ceiling: float = balance.height_male_max if gender == "Male" else balance.height_female_max
	return lerpf(float(balance.height_min), ceiling, float(class_rank * 100 + level - 1) / 1099.0)

func buff_active(id: String) -> bool:
	return float(buffs.get(id, 0)) > Time.get_unix_time_from_system()

func attack_power() -> int:
	var enhancement := 0
	for item in equipped.values():
		enhancement += int(item.get("enhancement", 0))
	return int((int(balance.attack_base) + level * int(balance.attack_per_level) + class_rank * int(balance.attack_per_class) + enhancement * 2) * (1.2 if buff_active("attack") else 1.0))

func defense() -> int:
	return int((int(balance.defense_base) + level + equipped.size() * 2) * (1.2 if buff_active("defense") else 1.0))

func add_item(id: String, count: int = 1) -> bool:
	if id not in balance.items or count <= 0:
		return false
	var limit: int = balance.items[id].stack
	var free := (200 - inventory.size()) * limit
	for slot in inventory:
		if slot.id == id:
			free += limit - int(slot.count)
	if free < count:
		return false # Transactional: never partially grant on failure.
	for slot in inventory:
		if slot.id == id and int(slot.count) < limit:
			var n := mini(count, limit - int(slot.count))
			slot.count = int(slot.count) + n
			count -= n
	while count > 0:
		var n := mini(count, limit)
		inventory.append({"id":id,"count":n,"enhancement":0})
		count -= n
	inventory_changed.emit()
	return true

func remove_item(index: int, count: int = 1) -> bool:
	if index < 0 or index >= inventory.size() or count <= 0 or int(inventory[index].count) < count:
		return false
	inventory[index].count = int(inventory[index].count) - count
	if int(inventory[index].count) == 0:
		inventory.remove_at(index)
	inventory_changed.emit()
	return true

func buy(id: String, count: int = 1) -> bool:
	if id not in balance.items or count < 1 or count > 99:
		return false
	var item: Dictionary = balance.items[id]
	var cost := int(item.price) * count
	var is_cash := bool(item.get("cash", false))
	if (cash if is_cash else gold) < cost or not add_item(id, count):
		return false
	if is_cash:
		cash -= cost
	else:
		gold -= cost
	return true

func sell(index: int, count: int) -> bool:
	if index < 0 or index >= inventory.size() or count < 1 or count > int(inventory[index].count):
		return false
	var value := int(balance.items[inventory[index].id].sell) * count
	if not remove_item(index, count):
		return false
	gold += value
	return true

func use_item(index: int) -> String:
	if index < 0 or index >= inventory.size():
		return "Invalid item"
	var saved: Dictionary = inventory[index].duplicate(true)
	var item: Dictionary = balance.items[saved.id]
	if hp <= 0 and item.kind not in ["revive", "warp"]:
		return "Revive first"
	match str(item.kind):
		"equipment":
			var slot: String = item.slot
			remove_item(index)
			if slot in equipped:
				inventory.append(equipped[slot])
			equipped[slot] = saved
			appearance_changed.emit()
		"heal":
			hp = mini(max_hp, hp + int(item.value))
			remove_item(index)
		"stamina":
			stamina = minf(max_stamina, stamina + float(item.value))
			remove_item(index)
		"buff":
			buffs[item.buff] = maxf(Time.get_unix_time_from_system(), float(buffs.get(item.buff, 0))) + float(item.duration)
			remove_item(index)
			_recalculate_stats(false)
		"revive":
			if hp > 0:
				return "Already alive"
			hp = max_hp
			remove_item(index)
		"warp":
			remove_item(index)
			return "warp"
		_:
			return "Crafting material"
	inventory_changed.emit()
	return "Used " + str(item.name)

func unequip(slot: String) -> bool:
	if slot not in equipped or inventory.size() >= 200:
		return false
	inventory.append(equipped[slot])
	equipped.erase(slot)
	appearance_changed.emit()
	inventory_changed.emit()
	return true

func enhance(slot: String) -> bool:
	if slot not in equipped or int(equipped[slot].enhancement) >= 10 or gold < 50:
		return false
	for i in range(inventory.size()):
		if inventory[i].id == "ore":
			remove_item(i)
			gold -= 50
			equipped[slot].enhancement = int(equipped[slot].enhancement) + 1
			return true
	return false

func record_kill() -> void:
	if quest_state == "active":
		quest_kills = mini(5, quest_kills + 1)
	pet_exp += 20
	while pet_exp >= pet_level * 50 and pet_level < 100:
		pet_exp -= pet_level * 50
		pet_level += 1
	pet_stage = mini(5, 1 + int((pet_level - 1) / 20.0))

func interact_quest() -> String:
	if quest_state == "available":
		quest_state = "active"
		return "Starter Hunt accepted: defeat 5 monsters"
	if quest_state == "active" and quest_kills >= 5:
		quest_state = "complete"
		gold += 100
		add_exp(300)
		advancement_ready = true
		return "Quest complete: +300 EXP, +100 Gold; advancement unlocked"
	return "Starter Hunt: %d / 5" % quest_kills

func _recalculate_stats(heal: bool = true) -> void:
	max_hp = int((int(balance.hp_base) + (level - 1) * int(balance.hp_per_level) + class_rank * int(balance.hp_per_class)) * (1.2 if buff_active("hp") else 1.0))
	max_stamina = int(balance.stamina_base) + (level - 1) * int(balance.stamina_per_level) + class_rank * int(balance.stamina_per_class)
	hp = max_hp if heal else clampi(hp, 0, max_hp)
	stamina = max_stamina if heal else clampf(stamina, 0, max_stamina)

func save_game() -> bool:
	var data := {"version":1}
	for key in _save_keys():
		data[key] = get(key)
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH) == OK

func _save_keys() -> Array:
	return ["class_rank","level","exp","gold","cash","selected_element","selected_path","selected_job","faction","gender","hp","stamina","inventory","equipped","pet_level","pet_exp","pet_stage","pet_enabled","quest_state","quest_kills","advancement_ready","map_index","location","settings","buffs","skill_mode","skill_loadout"]

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or data.get("version") != 1:
		return false
	# Offline data only; clamp corrupt saves, never upload as online truth.
	for key in _save_keys():
		if key in data and key != "inventory":
			set(key, data[key])
	inventory.clear()
	for item in data.get("inventory", []):
		if item is Dictionary and item.get("id", "") in balance.items and inventory.size() < 200:
			item.count = clampi(int(item.get("count", 1)), 1, int(balance.items[item.id].stack))
			inventory.append(item)
	class_rank = clampi(class_rank, 0, 10)
	level = clampi(level, 1, 100)
	map_index = clampi(map_index, 0, 4)
	return true

func job_definition(id: String = selected_job) -> Dictionary:
	for job in balance.professions:
		if job.id == id:
			return job
	return {}

func set_skill_slot(slot: int, source: int) -> bool:
	if class_rank < 3 or class_rank >= 5 or selected_element.is_empty() or slot < 0 or slot > 2 or source < 0 or source > 2:
		return false
	skill_loadout[slot] = source
	return true

func skill_definition(index: int) -> Dictionary:
	if index == 0 or selected_element.is_empty() or class_rank < 3:
		return balance.skills[index]
	var source: int = index - 1 if class_rank >= 5 else int(skill_loadout[index - 1])
	return balance.element_skills[selected_element][source]
