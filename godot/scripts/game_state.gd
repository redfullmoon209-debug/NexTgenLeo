extends RefCounted
class_name LeoGameState

const SAVE_PATH := "user://nexTgenLeo_save.json"
const SKILL_NAMES := {"earth_fighter":["Stone Fist","Faultline","Boulder Rush","Mountain Splitter","Granite Wave","Seismic Palm","Earthen Spikes","Crag Crusher","Landslide","Obsidian Break","Titan's Blow","Worldquake","Colossus Rise","Gaia's Judgment"],"mountain_fist":["Boulder Punch","Iron Knuckle","Crushing Palm","Peakbreaker","Avalanche Fist","Monolith Slam","Mountain Roar","Granite Cyclone","Summit Strike","Quarry Crusher","Titan Knuckle","Rumble Wave","Stoneheart Rush","Mountain's End"],"water_mage":["Water Bolt","Ice Shard","Tidal Wave","Frost Lance","Aqua Sphere","Glacier Fall","Rushing Current","Deep Sea Burst","Frozen Nova","Rainstorm","Abyssal Surge","Crystal Tide","Leviathan's Call","Ocean's Wrath"],"ocean_lord":["Trident Thrust","Riptide","Tidebreaker","Coral Spear","Undertow","Maelstrom","Deep Current","Poseidon's Reach","Reef Splitter","Tempest Trident","Abyssal Spiral","Kraken's Wake","Oceanic Rupture","King Tide"],"wind_assassin":["Gale Cut","Silent Gust","Crosswind","Razor Draft","Phantom Step","Cyclone Edge","Whispering Blades","Skyfall Slash","Tempest Fang","Vortex Strike","Windshadow Rush","Storm Reaver","Hurricane Dance","Eye of the Gale"],"wind_fan":["Fan Blade","Petal Gust","Cyclone Fan","Silkwind Arc","Whirling Leaves","Jade Tempest","Breeze Cutter","Sky Ribbon","Cloudburst Fan","Monsoon Dance","Wind Garden","Emerald Spiral","Heavenly Zephyr","Empress's Storm"],"flame_swords":["Twin Ember","Flame Arc","Scorching Cross","Blazing Waltz","Cinder Rush","Phoenix Pair","Inferno Spiral","Ashen Divide","Solar Flurry","Magma Waltz","Dragonfire Cross","Crimson Tempest","Phoenix Rebirth","Sunfire Finale"],"inferno_blade":["Cinder Cleave","Inferno Cleave","Blazing Ground","Molten Divide","Dragon's Descent","Ashfall","Magma Breaker","Hellfire Arc","Solar Rupture","Pyre Cyclone","Volcanic Wrath","Phoenix Guillotine","World on Fire","Inferno's End"],"thunder_gunner":["Thunder Shot","Static Burst","Chain Lightning","Volt Piercer","Storm Round","Arc Cannon","Skybreaker Shot","Ion Burst","Thunderclap","Railstorm","Tempest Barrage","Lightning Spear","Supercell Blast","Judgment Bolt"],"lightning_dual":["Double Spark","Storm Volley","Flash Barrage","Twin Volt","Arc Cascade","Lightning Waltz","Rapid Thunder","Ion Crossfire","Flashpoint","Skyfire Salvo","Tempest Twins","Thunder Dance","Overcharge Storm","Final Discharge"],"vine_guardian":["Thorn Lash","Root Snare","Briar Sweep","Vine Spear","Bramble Cage","Thicket Crash","Green Reaper","Wildwood Surge","Thornstorm","Ancient Briars","Forest's Grasp","Verdant Rupture","Worldroot Strike","Nature's Wrath"],"forest_lord":["Forest Bolt","Ancient Roots","Leafstorm","Elderwood Spear","Wild Growth","Sylvan Burst","Canopy Crash","Verdant Nova","Thorned Tempest","Heartwood Pulse","Primal Bloom","Emerald Cataclysm","Elder Dragonwood","Forest's Judgment"]}
const JOBS := [
    {"id":"earth_fighter","name":"Earth Fighter","weapon":"Gauntlets","color":Color(0.72,0.42,0.22),"str":8,"sta":8,"dex":4,"int":2},
    {"id":"mountain_fist","name":"Mountain Fist","weapon":"Fist","color":Color(0.55,0.38,0.25),"str":10,"sta":7,"dex":3,"int":2},
    {"id":"water_mage","name":"Water Mage","weapon":"Staff","color":Color(0.25,0.65,0.92),"str":2,"sta":4,"dex":4,"int":12},
    {"id":"ocean_lord","name":"Ocean Lord","weapon":"Trident","color":Color(0.2,0.54,0.8),"str":7,"sta":7,"dex":4,"int":5},
    {"id":"wind_assassin","name":"Wind Assassin","weapon":"Kunai","color":Color(0.55,0.8,0.7),"str":5,"sta":4,"dex":12,"int":3},
    {"id":"wind_fan","name":"Wind Fan","weapon":"War Fan","color":Color(0.6,0.88,0.72),"str":3,"sta":5,"dex":8,"int":8},
    {"id":"flame_swords","name":"Flame Swords","weapon":"Twin Swords","color":Color(0.95,0.37,0.15),"str":9,"sta":5,"dex":7,"int":3},
    {"id":"inferno_blade","name":"Inferno Blade","weapon":"Greatsword","color":Color(0.8,0.2,0.12),"str":12,"sta":7,"dex":3,"int":2},
    {"id":"thunder_gunner","name":"Thunder Gunner","weapon":"Pistol","color":Color(0.9,0.78,0.25),"str":3,"sta":4,"dex":9,"int":7},
    {"id":"lightning_dual","name":"Lightning Dual","weapon":"Dual Pistols","color":Color(0.98,0.85,0.32),"str":4,"sta":4,"dex":10,"int":5},
    {"id":"vine_guardian","name":"Vine Guardian","weapon":"Vine Whip","color":Color(0.34,0.66,0.3),"str":6,"sta":10,"dex":4,"int":4},
    {"id":"forest_lord","name":"Forest Lord","weapon":"Wood Staff","color":Color(0.35,0.6,0.28),"str":4,"sta":7,"dex":4,"int":9}
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
var equipped_skills: Array = [0, 1, 2]
var skill_points := 0
var skill_levels: Dictionary = {}
var player_position := Vector3(0, 2, 0)

func current_job_data() -> Dictionary:
    for spec in JOBS:
        if str(spec["id"]) == job:
            return spec
    return JOBS[0]

func max_skill_rank() -> int:
    return clampi(1 + int((level - 1) / 10), 1, 10)

func skills_for_job() -> Array[Dictionary]:
    var names: Array = SKILL_NAMES.get(job, SKILL_NAMES["earth_fighter"])
    var result: Array[Dictionary] = []
    for i in range(names.size()):
        var unlock := 1 if i < 3 else 1 + (i - 2) * 5
        var key := "%s:%d" % [job, i]
        var rank := clampi(int(skill_levels.get(key, 1)), 1, max_skill_rank())
        var kind := "area" if i % 4 == 1 else "single"
        var base_power := 1.15 + float(i % 4) * 0.2 + float(i / 4) * 0.12
        var level_bonus := float(maxi(0, level - unlock)) * 0.012
        result.append({"id": i, "name": str(names[i]), "kind": kind, "power": base_power + float(rank - 1) * 0.2 + level_bonus, "rank": rank, "rank_limit": max_skill_rank(), "unlock_level": unlock, "cost": 10 + i * 2 + rank * 2, "cooldown": maxf(1.4, 3.7 - float(i % 4) * 0.35), "range": 11.0 if int(current_job_data()["int"]) >= 7 or int(current_job_data()["dex"]) >= 9 else 6.0})
    return result

func skill_upgrade_gold_cost(skill_id: int) -> int:
    var current := int(skill_levels.get("%s:%d" % [job, skill_id], 1))
    return 75 + skill_id * 12 + current * 65

func upgrade_skill(skill_id: int) -> bool:
    var skill := skill_by_id(skill_id)
    if skill.is_empty() or int(skill["unlock_level"]) > level:
        return false
    var key := "%s:%d" % [job, skill_id]
    var rank := int(skill_levels.get(key, 1))
    if rank >= max_skill_rank() or skill_points < 1:
        return false
    var cost := skill_upgrade_gold_cost(skill_id)
    if gold < cost:
        return false
    skill_points -= 1
    gold -= cost
    skill_levels[key] = rank + 1
    return true

func unlocked_skills() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for skill in skills_for_job():
        if int(skill["unlock_level"]) <= level:
            result.append(skill)
    return result

func skill_by_id(skill_id: int) -> Dictionary:
    for skill in skills_for_job():
        if int(skill["id"]) == skill_id:
            return skill
    return {}

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
        skill_points += 1
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
    var data := {"character_name": character_name, "gender": gender, "level": level, "character_class": character_class, "job": job, "faction": faction, "hp": hp, "stamina": stamina, "exp": exp, "gold": gold, "cash": cash, "quest_kills": quest_kills, "quest_accepted": quest_accepted, "inventory": inventory, "weapon_enhancement": weapon_enhancement, "armor_enhancement": armor_enhancement, "equipped_skills": equipped_skills, "skill_points": skill_points, "skill_levels": skill_levels, "position": [player_position.x, player_position.y, player_position.z]}
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
    skill_points = maxi(0, int(data.get("skill_points", skill_points)))
    var stored_skill_levels: Variant = data.get("skill_levels", skill_levels)
    if stored_skill_levels is Dictionary:
        skill_levels = stored_skill_levels
    var equipped: Variant = data.get("equipped_skills", equipped_skills)
    if equipped is Array and equipped.size() == 3:
        var unlocked := unlocked_skills()
        var max_unlocked_id := int(unlocked[unlocked.size() - 1]["id"])
        equipped_skills = equipped.duplicate()
        for i in range(3):
            equipped_skills[i] = clampi(int(equipped_skills[i]), 0, max_unlocked_id)
    var stored: Variant = data.get("inventory", inventory)
    if stored is Dictionary:
        inventory = stored
    var pos: Variant = data.get("position", [])
    if pos is Array and pos.size() == 3:
        player_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
    return true
