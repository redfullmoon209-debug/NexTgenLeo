extends RefCounted
class_name LeoGameState

const SAVE_PATH := "user://nexTgenLeo_save.json"
var character_name := "Novice"
var gender := "Male"
var level := 1
var character_class := 0
var job := "Novice"
var faction := "None"
var hp := 100
var stamina := 100
var exp := 0
var gold := 0
var cash := 0
var quest_kills := 0
var quest_accepted := false
var inventory: Dictionary = {"Potion": 5}
var player_position := Vector3(0, 2, 0)

func max_hp() -> int:
    return 100 + (level - 1) * 12

func max_stamina() -> int:
    return 100 + (level - 1) * 5

func exp_needed() -> int:
    return 100 + (level - 1) * 45

func gain_exp(amount: int) -> void:
    exp += amount
    while level < 100 and exp >= exp_needed():
        exp -= exp_needed()
        level += 1
        hp = max_hp()
        stamina = max_stamina()

func add_item(item: String, amount: int = 1) -> void:
    inventory[item] = int(inventory.get(item, 0)) + amount

func use_potion() -> bool:
    if int(inventory.get("Potion", 0)) < 1 or hp >= max_hp():
        return false
    inventory["Potion"] = int(inventory["Potion"]) - 1
    hp = mini(max_hp(), hp + 50)
    return true

func save_game() -> bool:
    var data := {
        "character_name": character_name, "gender": gender, "level": level,
        "character_class": character_class, "job": job, "faction": faction,
        "hp": hp, "stamina": stamina, "exp": exp, "gold": gold, "cash": cash,
        "quest_kills": quest_kills, "quest_accepted": quest_accepted,
        "inventory": inventory,
        "position": [player_position.x, player_position.y, player_position.z]
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data))
    return true

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        return false
    var data: Dictionary = parsed
    character_name = str(data.get("character_name", character_name))
    gender = str(data.get("gender", gender))
    level = clampi(int(data.get("level", level)), 1, 100)
    character_class = clampi(int(data.get("character_class", character_class)), 0, 10)
    job = str(data.get("job", job))
    faction = str(data.get("faction", faction))
    hp = clampi(int(data.get("hp", hp)), 0, max_hp())
    stamina = clampi(int(data.get("stamina", stamina)), 0, max_stamina())
    exp = maxi(0, int(data.get("exp", exp)))
    gold = maxi(0, int(data.get("gold", gold)))
    cash = maxi(0, int(data.get("cash", cash)))
    quest_kills = maxi(0, int(data.get("quest_kills", quest_kills)))
    quest_accepted = bool(data.get("quest_accepted", quest_accepted))
    var stored: Variant = data.get("inventory", inventory)
    if stored is Dictionary:
        inventory = stored
    var pos: Variant = data.get("position", [])
    if pos is Array and pos.size() == 3:
        player_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
    return true
