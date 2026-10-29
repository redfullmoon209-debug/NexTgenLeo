extends RefCounted
class_name LeoGameState

const SAVE_PATH := "user://nexTgenLeo_save.json"
const JOBS := [
    {"id":"earth_fighter","name":"Earth Fighter","weapon":"Gauntlets","color":Color(0.72,0.42,0.22),"str":8,"sta":8,"dex":4,"int":2,"skills":[{"name":"Stone Breaker","power":2.0,"cost":14,"cooldown":3.0,"range":3.5},{"name":"Quake","power":1.4,"cost":24,"cooldown":7.0,"range":5.5},{"name":"Iron Guard","power":0.4,"cost":16,"cooldown":10.0,"range":3.0}]},
    {"id":"mountain_fist","name":"Mountain Fist","weapon":"Fist","color":Color(0.55,0.38,0.25),"str":10,"sta":7,"dex":3,"int":2,"skills":[{"name":"Boulder Punch","power":2.2,"cost":15,"cooldown":3.5,"range":3.5},{"name":"Crushing Palm","power":1.5,"cost":25,"cooldown":7.0,"range":5.0},{"name":"Focus","power":0.5,"cost":15,"cooldown":9.0,"range":3.0}]},
    {"id":"water_mage","name":"Water Mage","weapon":"Staff","color":Color(0.25,0.65,0.92),"str":2,"sta":4,"dex":4,"int":12,"skills":[{"name":"Water Bolt","power":2.1,"cost":16,"cooldown":3.0,"range":11.0},{"name":"Tidal Wave","power":1.6,"cost":27,"cooldown":8.0,"range":7.0},{"name":"Healing Mist","power":0.5,"cost":20,"cooldown":10.0,"range":4.0}]},
    {"id":"ocean_lord","name":"Ocean Lord","weapon":"Trident","color":Color(0.2,0.54,0.8),"str":7,"sta":7,"dex":4,"int":5,"skills":[{"name":"Trident Thrust","power":2.0,"cost":15,"cooldown":3.0,"range":5.0},{"name":"Riptide","power":1.5,"cost":24,"cooldown":7.0,"range":7.0},{"name":"Ocean Shield","power":0.5,"cost":18,"cooldown":10.0,"range":4.0}]},
    {"id":"wind_assassin","name":"Wind Assassin","weapon":"Kunai","color":Color(0.55,0.8,0.7),"str":5,"sta":4,"dex":12,"int":3,"skills":[{"name":"Gale Strike","power":1.9,"cost":13,"cooldown":2.5,"range":4.5},{"name":"Crosswind","power":1.5,"cost":22,"cooldown":6.0,"range":6.0},{"name":"Wind Step","power":0.5,"cost":17,"cooldown":9.0,"range":5.0}]},
    {"id":"wind_fan","name":"Wind Fan","weapon":"War Fan","color":Color(0.6,0.88,0.72),"str":3,"sta":5,"dex":8,"int":8,"skills":[{"name":"Fan Blade","power":1.9,"cost":14,"cooldown":3.0,"range":6.0},{"name":"Cyclone","power":1.5,"cost":24,"cooldown":7.0,"range":7.0},{"name":"Tailwind","power":0.5,"cost":18,"cooldown":9.0,"range":5.0}]},
    {"id":"flame_swords","name":"Flame Swords","weapon":"Twin Swords","color":Color(0.95,0.37,0.15),"str":9,"sta":5,"dex":7,"int":3,"skills":[{"name":"Twin Inferno","power":2.0,"cost":15,"cooldown":3.0,"range":4.0},{"name":"Flame Arc","power":1.6,"cost":25,"cooldown":7.0,"range":6.0},{"name":"Ember Rush","power":0.5,"cost":18,"cooldown":9.0,"range":5.0}]},
    {"id":"inferno_blade","name":"Inferno Blade","weapon":"Greatsword","color":Color(0.8,0.2,0.12),"str":12,"sta":7,"dex":3,"int":2,"skills":[{"name":"Inferno Cleave","power":2.3,"cost":18,"cooldown":4.0,"range":4.5},{"name":"Blazing Ground","power":1.8,"cost":29,"cooldown":8.0,"range":7.0},{"name":"Flame Armor","power":0.5,"cost":21,"cooldown":10.0,"range":4.0}]},
    {"id":"thunder_gunner","name":"Thunder Gunner","weapon":"Pistol","color":Color(0.9,0.78,0.25),"str":3,"sta":4,"dex":9,"int":7,"skills":[{"name":"Thunder Shot","power":2.0,"cost":14,"cooldown":3.0,"range":13.0},{"name":"Chain Lightning","power":1.6,"cost":25,"cooldown":7.0,"range":10.0},{"name":"Static Field","power":0.5,"cost":18,"cooldown":9.0,"range":7.0}]},
    {"id":"lightning_dual","name":"Lightning Dual","weapon":"Dual Pistols","color":Color(0.98,0.85,0.32),"str":4,"sta":4,"dex":10,"int":5,"skills":[{"name":"Double Spark","power":2.0,"cost":14,"cooldown":2.8,"range":12.0},{"name":"Storm Volley","power":1.6,"cost":24,"cooldown":7.0,"range":10.0},{"name":"Flash Step","power":0.5,"cost":18,"cooldown":9.0,"range":6.0}]},
    {"id":"vine_guardian","name":"Vine Guardian","weapon":"Vine Whip","color":Color(0.34,0.66,0.3),"str":6,"sta":10,"dex":4,"int":4,"skills":[{"name":"Thorn Lash","power":1.9,"cost":14,"cooldown":3.0,"range":7.0},{"name":"Root Snare","power":1.5,"cost":24,"cooldown":7.0,"range":8.0},{"name":"Barkskin","power":0.5,"cost":18,"cooldown":10.0,"range":4.0}]},
    {"id":"forest_lord","name":"Forest Lord","weapon":"Wood Staff","color":Color(0.35,0.6,0.28),"str":4,"sta":7,"dex":4,"int":9,"skills":[{"name":"Forest Bolt","power":2.0,"cost":15,"cooldown":3.0,"range":11.0},{"name":"Ancient Roots","power":1.6,"cost":26,"cooldown":8.0,"range":8.0},{"name":"Nature's Blessing","power":0.5,"cost":20,"cooldown":10.0,"range":5.0}]}
]
var character_name := "Novice"
var gender := "Male"
var level := 1
var character_class := 0
var job := "earth_fighter"
var faction := "None"
var hp := 100
var stamina := 100
var exp := 0
var gold := 0
var cash := 0
var quest_kills := 0
var quest_accepted := false
var weapon_enhancement := 0
var armor_enhancement := 0
var inventory: Dictionary = {"Potion": 5, "Ore": 0}
var player_position := Vector3(0, 2, 0)

func current_job_data() -> Dictionary:
    for spec in JOBS:
        if str(spec["id"]) == job:
            return spec
    return JOBS[0]

func cycle_job() -> void:
    var index := 0
    for i in range(JOBS.size()):
        if str(JOBS[i]["id"]) == job:
            index = i
            break
    job = str(JOBS[(index + 1) % JOBS.size()]["id"])

func stats() -> Dictionary:
    var spec := current_job_data()
    return {"STR": int(spec["str"]) + level - 1, "STA": int(spec["sta"]) + int((level - 1) / 2), "DEX": int(spec["dex"]) + int((level - 1) / 2), "INT": int(spec["int"]) + level - 1}

func max_hp() -> int:
    return 100 + (level - 1) * 12 + int(current_job_data()["sta"]) * 5 + armor_enhancement * 8

func max_stamina() -> int:
    return 100 + (level - 1) * 5 + int(current_job_data()["sta"]) * 3

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

func upgrade_weapon() -> bool:
    if weapon_enhancement >= 10 or gold < 50 + weapon_enhancement * 35 or int(inventory.get("Ore", 0)) < 1:
        return false
    gold -= 50 + weapon_enhancement * 35
    inventory["Ore"] = int(inventory["Ore"]) - 1
    weapon_enhancement += 1
    return true

func upgrade_armor() -> bool:
    if armor_enhancement >= 10 or gold < 40 + armor_enhancement * 30 or int(inventory.get("Ore", 0)) < 1:
        return false
    gold -= 40 + armor_enhancement * 30
    inventory["Ore"] = int(inventory["Ore"]) - 1
    armor_enhancement += 1
    hp = mini(hp, max_hp())
    return true

func use_potion() -> bool:
    if int(inventory.get("Potion", 0)) < 1 or hp >= max_hp():
        return false
    inventory["Potion"] = int(inventory["Potion"]) - 1
    hp = mini(max_hp(), hp + 50)
    return true

func save_game() -> bool:
    var data := {"character_name": character_name, "gender": gender, "level": level, "character_class": character_class, "job": job, "faction": faction, "hp": hp, "stamina": stamina, "exp": exp, "gold": gold, "cash": cash, "quest_kills": quest_kills, "quest_accepted": quest_accepted, "inventory": inventory, "weapon_enhancement": weapon_enhancement, "armor_enhancement": armor_enhancement, "position": [player_position.x, player_position.y, player_position.z]}
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
    job = str(data.get("job", job))
    current_job_data()
    faction = str(data.get("faction", faction))
    exp = maxi(0, int(data.get("exp", exp)))
    gold = maxi(0, int(data.get("gold", gold)))
    cash = maxi(0, int(data.get("cash", cash)))
    weapon_enhancement = clampi(int(data.get("weapon_enhancement", 0)), 0, 10)
    armor_enhancement = clampi(int(data.get("armor_enhancement", 0)), 0, 10)
    hp = clampi(int(data.get("hp", hp)), 0, max_hp())
    stamina = clampi(int(data.get("stamina", stamina)), 0, max_stamina())
    quest_kills = maxi(0, int(data.get("quest_kills", quest_kills)))
    quest_accepted = bool(data.get("quest_accepted", quest_accepted))
    var stored: Variant = data.get("inventory", inventory)
    if stored is Dictionary:
        inventory = stored
    var pos: Variant = data.get("position", [])
    if pos is Array and pos.size() == 3:
        player_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
    return true
