extends RefCounted
class_name LeoGameState

const SAVE_PATH := "user://nexTgenLeo_save.json"
const ELEMENTS := ["Earth", "Water", "Wind", "Fire", "Thunder", "Nature"]
const ELEMENT_COLORS := {"Earth": Color(0.65, 0.42, 0.23), "Water": Color(0.22, 0.62, 0.92), "Wind": Color(0.52, 0.84, 0.72), "Fire": Color(0.95, 0.3, 0.12), "Thunder": Color(0.96, 0.79, 0.2), "Nature": Color(0.28, 0.65, 0.3)}
const PATHS := [
    {"name":"Warrior","jobs":["earth_fighter","mountain_fist"]},
    {"name":"Spellcaster","jobs":["water_mage","ocean_lord"]},
    {"name":"Scout","jobs":["wind_assassin","wind_fan"]},
    {"name":"Blademaster","jobs":["flame_swords","inferno_blade"]},
    {"name":"Gunner","jobs":["thunder_gunner","lightning_dual"]},
    {"name":"Warden","jobs":["vine_guardian","forest_lord"]}
]
const NOVICE_SKILLS := ["Novice Strike", "Quickstep", "Guard Break"]
const WEAPON_PROFILES := {
    "Training Blade":{"range":5.0,"power":1.0,"cooldown":2.7,"style":"balanced"},
    "Gauntlets":{"range":4.5,"power":1.14,"cooldown":2.1,"style":"rapid fists"},
    "Fist":{"range":4.2,"power":1.25,"cooldown":2.5,"style":"heavy fists"},
    "Staff":{"range":12.5,"power":1.1,"cooldown":3.1,"style":"ranged magic"},
    "Trident":{"range":8.0,"power":1.12,"cooldown":2.8,"style":"reach and sweep"},
    "Kunai":{"range":5.5,"power":1.02,"cooldown":1.8,"style":"fast combo"},
    "War Fan":{"range":8.0,"power":1.0,"cooldown":2.3,"style":"wide arcs"},
    "Twin Swords":{"range":5.0,"power":1.08,"cooldown":1.9,"style":"dual combo"},
    "Greatsword":{"range":5.2,"power":1.35,"cooldown":3.3,"style":"heavy cleave"},
    "Pistol":{"range":14.0,"power":1.0,"cooldown":2.4,"style":"precision shots"},
    "Dual Pistols":{"range":12.0,"power":1.04,"cooldown":1.9,"style":"rapid volleys"},
    "Vine Whip":{"range":8.0,"power":1.04,"cooldown":2.4,"style":"sweeping reach"},
    "Wood Staff":{"range":11.5,"power":1.12,"cooldown":2.8,"style":"nature magic"}
}
const SKILL_NAMES := {"earth_fighter":["Stone Fist","Faultline","Boulder Rush","Stonebound Will","Granite Wave","Seismic Palm","Earthen Spikes","Granite Guard","Landslide","Obsidian Break","Titan's Blow","Ancient Resolve","Colossus Rise","Titan's Legacy"],"mountain_fist":["Boulder Punch","Iron Knuckle","Crushing Palm","Iron Discipline","Avalanche Fist","Monolith Slam","Mountain Roar","Stonewall Guard","Summit Strike","Quarry Crusher","Titan Knuckle","Mountain Focus","Stoneheart Rush","Unshakable Core"],"water_mage":["Water Bolt","Ice Shard","Tidal Wave","Flowing Wisdom","Aqua Sphere","Glacier Fall","Rushing Current","Mana Reservoir","Frozen Nova","Rainstorm","Abyssal Surge","Tidal Barrier","Leviathan's Call","Oceanborn"],"ocean_lord":["Trident Thrust","Riptide","Tidebreaker","Trident Mastery","Undertow","Maelstrom","Deep Current","Current Guard","Reef Splitter","Tempest Trident","Abyssal Spiral","Ocean's Patience","Oceanic Rupture","Poseidon's Legacy"],"wind_assassin":["Gale Cut","Silent Gust","Crosswind","Silent Footwork","Phantom Step","Cyclone Edge","Whispering Blades","Shadow Veil","Tempest Fang","Vortex Strike","Windshadow Rush","Assassin's Focus","Hurricane Dance","Gale Instinct"],"wind_fan":["Fan Blade","Petal Gust","Cyclone Fan","Wind Choreography","Whirling Leaves","Jade Tempest","Breeze Cutter","Breeze Step","Cloudburst Fan","Monsoon Dance","Wind Garden","Open Air Guard","Heavenly Zephyr","Zephyr's Grace"],"flame_swords":["Twin Ember","Flame Arc","Scorching Cross","Twinblade Technique","Cinder Rush","Phoenix Pair","Inferno Spiral","Cinder Guard","Solar Flurry","Magma Waltz","Dragonfire Cross","Dueling Rhythm","Phoenix Rebirth","Phoenix Spirit"],"inferno_blade":["Cinder Cleave","Inferno Cleave","Blazing Ground","Molten Core","Dragon's Descent","Ashfall","Magma Breaker","Inferno Guard","Solar Rupture","Pyre Cyclone","Volcanic Wrath","Pyre's Focus","World on Fire","Phoenix Heart"],"thunder_gunner":["Thunder Shot","Static Burst","Chain Lightning","Steady Aim","Storm Round","Arc Cannon","Skybreaker Shot","Static Guard","Thunderclap","Railstorm","Tempest Barrage","Ballistic Focus","Supercell Blast","Storm Sight"],"lightning_dual":["Double Spark","Storm Volley","Flash Barrage","Quickdraw","Arc Cascade","Lightning Waltz","Rapid Thunder","Arc Guard","Flashpoint","Skyfire Salvo","Tempest Twins","Rapid Focus","Overcharge Storm","Twin Storm"],"vine_guardian":["Thorn Lash","Root Snare","Briar Sweep","Thorned Hide","Bramble Cage","Thicket Crash","Green Reaper","Rooted Stance","Thornstorm","Ancient Briars","Forest's Grasp","Verdant Focus","Worldroot Strike","Wildwood Heart"],"forest_lord":["Forest Bolt","Ancient Roots","Leafstorm","Elder Wisdom","Wild Growth","Sylvan Burst","Canopy Crash","Canopy Guard","Thorned Tempest","Heartwood Pulse","Primal Bloom","Nature's Focus","Elder Dragonwood","Forest Heart"]}
const JOBS := [
    {"id":"earth_fighter","role":"tank","name":"Vanguard","weapon":"Gauntlets","color":Color(0.72,0.42,0.22),"str":8,"sta":8,"dex":4,"int":2},
    {"id":"mountain_fist","role":"damage","name":"Brawler","weapon":"Fist","color":Color(0.55,0.38,0.25),"str":10,"sta":7,"dex":3,"int":2},
    {"id":"water_mage","role":"support","name":"Arcanist","weapon":"Staff","color":Color(0.25,0.65,0.92),"str":2,"sta":4,"dex":4,"int":12},
    {"id":"ocean_lord","role":"support","name":"Spearcaller","weapon":"Trident","color":Color(0.2,0.54,0.8),"str":7,"sta":7,"dex":4,"int":5},
    {"id":"wind_assassin","role":"damage","name":"Shadowblade","weapon":"Kunai","color":Color(0.55,0.8,0.7),"str":5,"sta":4,"dex":12,"int":3},
    {"id":"wind_fan","role":"support","name":"Winddancer","weapon":"War Fan","color":Color(0.6,0.88,0.72),"str":3,"sta":5,"dex":8,"int":8},
    {"id":"flame_swords","role":"damage","name":"Twinblade","weapon":"Twin Swords","color":Color(0.95,0.37,0.15),"str":9,"sta":5,"dex":7,"int":3},
    {"id":"inferno_blade","role":"damage","name":"Greatsword","weapon":"Greatsword","color":Color(0.8,0.2,0.12),"str":12,"sta":7,"dex":3,"int":2},
    {"id":"thunder_gunner","role":"damage","name":"Marksman","weapon":"Pistol","color":Color(0.9,0.78,0.25),"str":3,"sta":4,"dex":9,"int":7},
    {"id":"lightning_dual","role":"damage","name":"Gunslinger","weapon":"Dual Pistols","color":Color(0.98,0.85,0.32),"str":4,"sta":4,"dex":10,"int":5},
    {"id":"vine_guardian","role":"support","name":"Thornwarden","weapon":"Vine Whip","color":Color(0.34,0.66,0.3),"str":6,"sta":10,"dex":4,"int":4},
    {"id":"forest_lord","role":"support","name":"Grove Sage","weapon":"Wood Staff","color":Color(0.35,0.6,0.28),"str":4,"sta":7,"dex":4,"int":9}
]
var character_name := "Novice"
var gender := "Male"
var level := 1
var character_class := 0
var element := ""
var branch := -1
var job := "novice"
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
    if job == "novice":
        var novice := {"id":"novice", "name":"Novice", "weapon":"Training Blade", "color":Color(0.35, 0.55, 0.85), "str":5, "sta":5, "dex":5, "int":5}
        if not element.is_empty():
            novice["color"] = ELEMENT_COLORS.get(element, novice["color"])
            novice["name"] = "%s Novice" % element
        return novice
    for spec in JOBS:
        if str(spec["id"]) == job:
            var result: Dictionary = spec.duplicate()
            if not element.is_empty():
                result["color"] = ELEMENT_COLORS.get(element, result["color"])
                result["name"] = "%s %s" % [element, str(spec["name"])]
            return result
    job = "novice"
    return current_job_data()

func element_choices() -> Array:
    return ELEMENTS.duplicate()

func path_choices() -> Array:
    var result: Array = []
    for path in PATHS:
        result.append(str(path["name"]))
    return result

func specialization_choices() -> Array:
    if branch < 0 or branch >= PATHS.size():
        return []
    var result: Array = []
    for job_id in PATHS[branch]["jobs"]:
        for spec in JOBS:
            if str(spec["id"]) == str(job_id):
                result.append(str(spec["name"]))
    return result

func choose_element(index: int) -> bool:
    if level < 10 or not element.is_empty() or index < 0 or index >= ELEMENTS.size():
        return false
    element = ELEMENTS[index]
    return true

func choose_path(index: int) -> bool:
    if level < 15 or element.is_empty() or branch >= 0 or index < 0 or index >= PATHS.size():
        return false
    branch = index
    return true

func choose_specialization(index: int) -> bool:
    if level < 30 or branch < 0 or job != "novice":
        return false
    var choices: Array = PATHS[branch]["jobs"]
    if index < 0 or index >= choices.size():
        return false
    job = str(choices[index])
    equipped_skills = [0, 1, 2]
    return true

func element_damage_multiplier() -> float:
    return 1.06 if not element.is_empty() else 1.0

func weapon_profile() -> Dictionary:
    var weapon := str(current_job_data()["weapon"])
    return WEAPON_PROFILES.get(weapon, WEAPON_PROFILES["Training Blade"])

func max_skill_rank() -> int:
    return clampi(1 + int((level - 1) / 10), 1, 10)

func skill_effect_for(index: int, role: String) -> String:
    if [3, 7, 11, 13].has(index):
        if role == "support":
            return {3:"passive_support", 7:"passive_attack", 11:"passive_speed", 13:"passive_team"}.get(index, "passive_attack")
        if role == "tank":
            return {3:"passive_attack", 7:"passive_guard", 11:"passive_speed", 13:"passive_team"}.get(index, "passive_attack")
        return {3:"passive_attack", 7:"passive_speed", 11:"passive_guard", 13:"passive_attack"}.get(index, "passive_attack")
    if role == "support":
        return {0:"damage", 1:"area", 2:"party_attack", 4:"heal", 5:"party_speed", 6:"area", 8:"armor_break", 9:"party_attack", 10:"party_guard", 12:"ultimate"}.get(index, "damage")
    if role == "tank":
        return {0:"damage", 1:"area", 2:"buff_attack", 4:"damage", 5:"party_guard", 6:"area", 8:"armor_break", 9:"damage", 10:"buff_speed", 12:"party_attack"}.get(index, "damage")
    return {0:"damage", 1:"area", 2:"buff_attack", 4:"damage", 5:"buff_speed", 6:"area", 8:"armor_break", 9:"damage", 10:"buff_attack", 12:"ultimate"}.get(index, "damage")

func skills_for_job() -> Array[Dictionary]:
    var names: Array = NOVICE_SKILLS if job == "novice" else SKILL_NAMES.get(job, SKILL_NAMES["earth_fighter"])
    var result: Array[Dictionary] = []
    for i in range(names.size()):
        var unlock := 1 if job == "novice" or i < 3 else 30 + (i - 2) * 4
        var key := "%s:%d" % [job, i]
        var rank := clampi(int(skill_levels.get(key, 1)), 1, max_skill_rank())
        var profile := weapon_profile()
        var effect := "damage" if job == "novice" else skill_effect_for(i, str(current_job_data()["role"]))
        if effect.begins_with("passive_"):
            rank = max_skill_rank()
        var kind := "area" if ["area", "ultimate"].has(effect) else "single"
        var base_power := 1.15 + float(i % 4) * 0.2 + float(i / 4) * 0.12
        var level_bonus := float(maxi(0, level - unlock)) * 0.012
        result.append({"id": i, "name": str(names[i]), "kind": kind, "effect": effect, "style": profile["style"], "weapon": current_job_data()["weapon"], "power": (base_power + float(rank - 1) * 0.2 + level_bonus) * float(profile["power"]), "rank": rank, "rank_limit": max_skill_rank(), "unlock_level": unlock, "cost": 10 + i * 2 + rank * 2, "cooldown": maxf(1.3, float(profile["cooldown"]) - float(i % 4) * 0.2), "range": float(profile["range"])})
    return result

func skill_upgrade_gold_cost(skill_id: int) -> int:
    var current := int(skill_levels.get("%s:%d" % [job, skill_id], 1))
    return 75 + skill_id * 12 + current * 65

func upgrade_skill(skill_id: int) -> bool:
    var skill := skill_by_id(skill_id)
    if skill.is_empty() or int(skill["unlock_level"]) > level or str(skill["effect"]).begins_with("passive_"):
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
        if int(skill["unlock_level"]) <= level and not str(skill["effect"]).begins_with("passive_"):
            result.append(skill)
    return result

func passive_skills() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for skill in skills_for_job():
        if int(skill["unlock_level"]) <= level and str(skill["effect"]).begins_with("passive_"):
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
    var data := {"character_name": character_name, "gender": gender, "level": level, "character_class": character_class, "element": element, "branch": branch, "job": job, "faction": faction, "hp": hp, "stamina": stamina, "exp": exp, "gold": gold, "cash": cash, "quest_kills": quest_kills, "quest_accepted": quest_accepted, "inventory": inventory, "weapon_enhancement": weapon_enhancement, "armor_enhancement": armor_enhancement, "equipped_skills": equipped_skills, "skill_points": skill_points, "skill_levels": skill_levels, "position": [player_position.x, player_position.y, player_position.z]}
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
    element = str(data.get("element", element))
    if not ELEMENTS.has(element):
        element = ""
    branch = clampi(int(data.get("branch", branch)), -1, PATHS.size() - 1)
    job = str(data.get("job", job))
    current_job_data()
    if job != "novice" and branch < 0:
        job = "novice"
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
        equipped_skills = equipped.duplicate()
        for i in range(3):
            var candidate := int(equipped_skills[i])
            var usable := false
            for skill in unlocked:
                if int(skill["id"]) == candidate:
                    usable = true
                    break
            if not usable:
                equipped_skills[i] = int(unlocked[mini(i, unlocked.size() - 1)]["id"])
        if int(equipped_skills[0]) == int(equipped_skills[1]):
            equipped_skills[1] = int(unlocked[mini(1, unlocked.size() - 1)]["id"])
        if int(equipped_skills[2]) == int(equipped_skills[0]) or int(equipped_skills[2]) == int(equipped_skills[1]):
            equipped_skills[2] = int(unlocked[mini(2, unlocked.size() - 1)]["id"])
    var stored: Variant = data.get("inventory", inventory)
    if stored is Dictionary:
        inventory = stored
    var pos: Variant = data.get("position", [])
    if pos is Array and pos.size() == 3:
        player_position = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
    return true
