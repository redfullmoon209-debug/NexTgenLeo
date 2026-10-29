extends Node3D

const SPEED := 7.0
const LOOK_SENSITIVITY := 0.004
var player: CharacterBody3D
var camera_pivot: Node3D
var camera: Camera3D
var touch_origin := Vector2.ZERO
var move_touch := -1
var look_touch := -1
var touch_move := Vector2.ZERO
var pitch := -0.35
var state := LeoGameState.new()
var target: LeoMob
var attack_timer := 0.0
var skill_timers := [0.0, 0.0, 0.0]
var status: Label
var notice: Label
var skill_buttons: Array[Button] = []
var skill_change_buttons: Array[Button] = []
var skill_upgrade_buttons: Array[Button] = []
var hud_layer: CanvasLayer
var progression_button: Button
var progression_panel: Panel
var gear_root: Node3D
var ground_attack_enabled := false
var attack_buff_multiplier := 1.0
var attack_buff_timer := 0.0
var speed_buff_multiplier := 1.0
var speed_buff_timer := 0.0
var guard_buff_multiplier := 1.0
var guard_buff_timer := 0.0

func _ready() -> void:
    add_to_group("party_members")
    state.load_game()
    _setup_input()
    _make_world()
    _make_player()
    _load_thailand()
    _make_hud()
    _spawn_mobs()

func _setup_input() -> void:
    for item in [{"action":"move_forward","key":KEY_W},{"action":"move_back","key":KEY_S},{"action":"move_left","key":KEY_A},{"action":"move_right","key":KEY_D},{"action":"jump","key":KEY_SPACE},{"action":"attack","key":KEY_J},{"action":"potion","key":KEY_H},{"action":"skill_one","key":KEY_1},{"action":"skill_two","key":KEY_2},{"action":"skill_three","key":KEY_3}]:
        if not InputMap.has_action(item.action):
            InputMap.add_action(item.action)
        var key := InputEventKey.new()
        key.physical_keycode = item.key
        InputMap.action_add_event(item.action, key)

func _make_world() -> void:
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -30, 0)
    sun.light_energy = 1.2
    add_child(sun)
    var env := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color(0.55, 0.73, 0.92)
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color(0.85, 0.9, 1.0)
    settings.ambient_light_energy = 0.6
    env.environment = settings
    add_child(env)
    var ground := StaticBody3D.new()
    ground.name = "TemporaryGround"
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(250, 1, 250)
    collision.shape = shape
    collision.position.y = -0.5
    ground.add_child(collision)
    var mesh := MeshInstance3D.new()
    var plane := BoxMesh.new()
    plane.size = Vector3(250, 1, 250)
    mesh.mesh = plane
    mesh.position.y = -0.5
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.25, 0.48, 0.25)
    mesh.material_override = mat
    ground.add_child(mesh)
    add_child(ground)

func _make_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = state.player_position
    add_child(player)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    player.add_child(collision)
    var mesh := MeshInstance3D.new()
    var body := CapsuleMesh.new()
    body.radius = 0.35
    body.height = 1.8
    mesh.mesh = body
    mesh.position.y = 0.9
    var material := StandardMaterial3D.new()
    material.albedo_color = state.current_job_data()["color"]
    mesh.material_override = material
    player.add_child(mesh)
    gear_root = Node3D.new()
    gear_root.name = "TemporaryGear"
    player.add_child(gear_root)
    _refresh_player_gear()
    camera_pivot = Node3D.new()
    camera_pivot.position.y = 1.4
    add_child(camera_pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0, 3.2, 8)
    camera.current = true
    camera_pivot.add_child(camera)
    camera_pivot.rotation.x = pitch

func _refresh_player_gear() -> void:
    if not is_instance_valid(gear_root):
        return
    for child in gear_root.get_children():
        child.queue_free()
    var spec := state.current_job_data()
    var color: Color = spec["color"]
    var armor_color := Color(0.12, 0.16, 0.23).lightened(minf(0.35, float(state.armor_enhancement) * 0.025))
    _gear_box("Chest Armor", Vector3(0.0, 1.02, 0.0), Vector3(0.64, 0.58, 0.38), armor_color)
    _gear_box("Shoulder Left", Vector3(-0.38, 1.28, 0.0), Vector3(0.22, 0.22, 0.28), color.darkened(0.12))
    _gear_box("Shoulder Right", Vector3(0.38, 1.28, 0.0), Vector3(0.22, 0.22, 0.28), color.darkened(0.12))
    var weapon_name := str(spec["weapon"])
    var metal_color := color.lightened(minf(0.45, float(state.weapon_enhancement) * 0.035))
    if weapon_name.contains("Pistol"):
        _gear_box("Pistol Frame", Vector3(0.48, 1.04, -0.05), Vector3(0.32, 0.24, 0.22), metal_color)
        _gear_box("Pistol Barrel", Vector3(0.48, 1.12, -0.28), Vector3(0.13, 0.12, 0.30), Color(0.25, 0.28, 0.34))
        if weapon_name.contains("Dual"):
            _gear_box("Offhand Pistol", Vector3(-0.42, 1.04, -0.05), Vector3(0.30, 0.22, 0.20), metal_color)
    elif weapon_name.contains("Staff"):
        _gear_box("Staff Shaft", Vector3(0.48, 1.13, -0.05), Vector3(0.10, 1.12, 0.10), Color(0.38, 0.25, 0.12))
        _gear_sphere("Staff Crystal", Vector3(0.48, 1.78, -0.05), 0.23, metal_color)
    elif weapon_name.contains("Fan"):
        _gear_box("Fan Handle", Vector3(0.48, 1.04, -0.05), Vector3(0.10, 0.52, 0.10), Color(0.34, 0.2, 0.1))
        _gear_box("Fan Blade", Vector3(0.48, 1.48, -0.05), Vector3(0.72, 0.62, 0.08), metal_color)
    elif weapon_name.contains("Fist") or weapon_name.contains("Gauntlets"):
        _gear_box("Left Gauntlet", Vector3(-0.43, 0.94, -0.12), Vector3(0.32, 0.24, 0.32), metal_color)
        _gear_box("Right Gauntlet", Vector3(0.43, 0.94, -0.12), Vector3(0.32, 0.24, 0.32), metal_color)
    else:
        _gear_box("Weapon Handle", Vector3(0.48, 1.00, -0.05), Vector3(0.10, 0.65, 0.10), Color(0.34, 0.2, 0.1))
        var blade_width := 0.16
        var blade_length := 0.72
        if weapon_name.contains("Greatsword"):
            blade_width = 0.34
            blade_length = 1.0
        elif weapon_name.contains("Trident") or weapon_name.contains("Whip"):
            blade_width = 0.12
            blade_length = 1.12
        _gear_box(weapon_name, Vector3(0.48, 1.42, -0.05), Vector3(blade_width, blade_length, 0.12), metal_color)
        if weapon_name.contains("Trident"):
            _gear_box("Trident Left Prong", Vector3(0.28, 1.82, -0.05), Vector3(0.10, 0.34, 0.10), metal_color)
            _gear_box("Trident Right Prong", Vector3(0.68, 1.82, -0.05), Vector3(0.10, 0.34, 0.10), metal_color)
    if state.weapon_enhancement >= 4:
        _gear_sphere("Weapon Glow", Vector3(0.48, 1.58, -0.05), 0.16, Color(0.4, 0.85, 1.0))
    _gear_sphere("Helmet", Vector3(0.0, 1.68, 0.0), 0.28, color.lightened(0.1))

func _gear_box(label_text: String, local_position: Vector3, size: Vector3, color: Color) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = label_text
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.position = local_position
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    mesh.material_override = material
    gear_root.add_child(mesh)

func _gear_sphere(label_text: String, local_position: Vector3, radius: float, color: Color) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = label_text
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    mesh.mesh = sphere
    mesh.position = local_position
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = 0.45
    mesh.material_override = material
    gear_root.add_child(mesh)

func _load_thailand() -> void:
    var path := "res://assets/maps/thailand.glb"
    if ResourceLoader.exists(path):
        var scene := load(path) as PackedScene
        if scene:
            var map := scene.instantiate()
            map.name = "ThailandMap"
            add_child(map)
            print("Thailand map loaded")
    else:
        print("Map missing: add thailand.glb to assets/maps")

func _make_hud() -> void:
    var layer := CanvasLayer.new()
    hud_layer = layer
    add_child(layer)
    var label := Label.new()
    label.text = "NexTgenLeo | WASD / touch move | drag to look"
    label.position = Vector2(16, 12)
    layer.add_child(label)
    var note := Label.new()
    note.text = "Choose element, then path and specialization as you level"
    note.position = Vector2(16, 38)
    layer.add_child(note)
    status = Label.new()
    status.position = Vector2(16, 64)
    layer.add_child(status)
    notice = Label.new()
    notice.position = Vector2(16, 90)
    layer.add_child(notice)
    _button(layer, "ATK", Vector2(18, 132), _attack)
    _button(layer, "POTION", Vector2(90, 132), _potion)
    _button(layer, "QUEST", Vector2(184, 132), _quest)
    progression_button = _button(layer, "PROGRESS", Vector2(276, 132), _open_progression_menu)
    for i in range(3):
        var slot := i
        var cast_button := _button(layer, "SKILL", Vector2(12 + i * 112, 180), Callable(self, "_cast_skill").bind(slot))
        skill_buttons.append(cast_button)
        var change_button := _button(layer, "CHANGE", Vector2(12 + i * 112, 222), Callable(self, "_cycle_skill_slot").bind(slot))
        skill_change_buttons.append(change_button)
        var upgrade_button := _button(layer, "UP SKILL", Vector2(12 + i * 112, 264), Callable(self, "_upgrade_equipped_skill").bind(slot))
        skill_upgrade_buttons.append(upgrade_button)
    _button(layer, "WEAPON +", Vector2(18, 310), _upgrade_weapon)
    _button(layer, "ARMOR +", Vector2(145, 310), _upgrade_armor)
    _button(layer, "SAVE", Vector2(260, 310), _save)

func _physics_process(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)
    attack_buff_timer = maxf(0.0, attack_buff_timer - delta)
    speed_buff_timer = maxf(0.0, speed_buff_timer - delta)
    guard_buff_timer = maxf(0.0, guard_buff_timer - delta)
    if attack_buff_timer <= 0.0:
        attack_buff_multiplier = 1.0
    if speed_buff_timer <= 0.0:
        speed_buff_multiplier = 1.0
    if guard_buff_timer <= 0.0:
        guard_buff_multiplier = 1.0
    for i in range(skill_timers.size()):
        skill_timers[i] = maxf(0.0, skill_timers[i] - delta)
    var spec := state.current_job_data()
    var stats := state.stats()
    var selected_element: String = state.element if not state.element.is_empty() else "None"
    var selected_path: String = str(state.path_choices()[state.branch]) if state.branch >= 0 else "None"
    var passives := state.passive_skills()
    status.text = "%s Lv.%d HP %d/%d MP %d/%d SkillPts %d EXP %d/%d G %d Ore %d\n%s | %s | %s | Passive %d | W+%d A+%d" % [spec["name"], state.level, state.hp, state.max_hp(), state.stamina, state.max_stamina(), state.skill_points, state.exp, state.exp_needed(), state.gold, int(state.inventory.get("Ore", 0)), selected_element, selected_path, spec["weapon"], passives.size(), state.weapon_enhancement, state.armor_enhancement]
    if state.element.is_empty():
        progression_button.text = "ELEMENT" if state.level >= 10 else "ELEMENT Lv10"
    elif state.branch < 0:
        progression_button.text = "PATH" if state.level >= 15 else "PATH Lv15"
    elif state.job == "novice":
        progression_button.text = "SPECIALIZE" if state.level >= 30 else "SPEC Lv30"
    else:
        progression_button.text = "CLASS"
    for i in range(skill_buttons.size()):
        var skill: Dictionary = state.skill_by_id(int(state.equipped_skills[i]))
        skill_buttons[i].text = "%s R%d" % [skill["name"], skill["rank"]]
        skill_buttons[i].disabled = skill_timers[i] > 0.0 or state.stamina < int(skill["cost"])
        skill_change_buttons[i].text = "CHANGE %d" % (i + 1)
        skill_upgrade_buttons[i].text = "UP %d (%dG)" % [i + 1, state.skill_upgrade_gold_cost(int(state.equipped_skills[i]))]
        skill_upgrade_buttons[i].disabled = int(skill["rank"]) >= int(skill["rank_limit"]) or state.skill_points < 1 or state.gold < state.skill_upgrade_gold_cost(int(skill["id"]))
    camera_pivot.global_position = player.global_position + Vector3.UP * 1.4
    var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if touch_move.length() > 0.1:
        axis = touch_move
    var forward := -camera_pivot.global_basis.z
    forward.y = 0
    forward = forward.normalized()
    var right := camera_pivot.global_basis.x
    right.y = 0
    right = right.normalized()
    var direction := (right * axis.x + forward * axis.y).normalized()
    player.velocity.x = direction.x * SPEED * speed_buff_multiplier * _passive_speed_multiplier()
    player.velocity.z = direction.z * SPEED * speed_buff_multiplier * _passive_speed_multiplier()
    if Input.is_action_just_pressed("jump") and player.is_on_floor():
        player.velocity.y = 7.5
    if not player.is_on_floor():
        player.velocity.y -= 20.0 * delta
    else:
        player.velocity.y = 0.0
    player.move_and_slide()
    if direction.length() > 0.1:
        player.rotation.y = lerp_angle(player.rotation.y, atan2(-direction.x, -direction.z), min(delta * 12.0, 1.0))

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("attack"):
        _attack()
    if event.is_action_pressed("potion"):
        _potion()
    if event.is_action_pressed("skill_one"):
        _cast_skill(0)
    if event.is_action_pressed("skill_two"):
        _cast_skill(1)
    if event.is_action_pressed("skill_three"):
        _cast_skill(2)
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        _rotate_camera(event.relative)
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera.position.z = maxf(2.5, camera.position.z - 1.0)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera.position.z = minf(25.0, camera.position.z + 1.0)
    elif event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < get_viewport().get_visible_rect().size.x * 0.5 and move_touch == -1:
                move_touch = event.index
                touch_origin = event.position
            elif look_touch == -1:
                look_touch = event.index
        else:
            if event.index == move_touch:
                move_touch = -1
                touch_move = Vector2.ZERO
            if event.index == look_touch:
                look_touch = -1
    elif event is InputEventScreenDrag:
        if event.index == move_touch:
            touch_move = ((event.position - touch_origin) / 75.0).limit_length(1.0)
        elif event.index == look_touch:
            _rotate_camera(event.relative)

func _rotate_camera(relative: Vector2) -> void:
    camera_pivot.rotation.y -= relative.x * LOOK_SENSITIVITY
    pitch = clampf(pitch - relative.y * LOOK_SENSITIVITY, -1.15, 0.25)
    camera_pivot.rotation.x = pitch

func _button(layer: CanvasLayer, title: String, pos: Vector2, callback: Callable) -> Button:
    var button := Button.new()
    button.text = title
    button.position = pos
    button.custom_minimum_size = Vector2(86, 38)
    layer.add_child(button)
    button.pressed.connect(callback)
    return button

func _spawn_mobs() -> void:
    for i in range(10):
        var mob := LeoMob.new()
        mob.position = Vector3(cos(i * TAU / 10.0) * 12.0, 1.0, sin(i * TAU / 10.0) * 12.0)
        mob.target = player
        mob.defeated.connect(_mob_defeated)
        mob.player_hit.connect(_player_hit)
        add_child(mob)

func _mob_defeated(mob: LeoMob) -> void:
    var defeated_position := mob.global_position
    state.gain_exp(30)
    state.gold += 10
    _respawn_mob(defeated_position)
    if randi_range(1, 100) <= 35:
        state.add_item("Ore")
    if state.quest_accepted:
        state.quest_kills += 1
        if state.quest_kills >= 5:
            state.quest_accepted = false
            state.quest_kills = 0
            state.gold += 100
            state.gain_exp(100)
            _notify("Hunt complete: +100 Gold +100 EXP")
    target = null
    _save()

func _respawn_mob(spawn_position: Vector3) -> void:
    await get_tree().create_timer(5.0).timeout
    var mob := LeoMob.new()
    mob.position = spawn_position
    mob.target = player
    mob.defeated.connect(_mob_defeated)
    mob.player_hit.connect(_player_hit)
    add_child(mob)

func _player_hit(damage: int) -> void:
    var stats := state.stats()
    var passive_guard := 0.0
    for skill in state.passive_skills():
        if str(skill["effect"]) == "passive_guard":
            passive_guard += 0.02 * int(skill["rank"])
    var reduction := clampf(float(stats["STA"]) * 0.005 + float(state.armor_enhancement) * 0.035 + (guard_buff_multiplier - 1.0) * 0.5 + passive_guard, 0.0, 0.8)
    var actual := maxi(1, int(float(damage) * (1.0 - reduction)))
    state.hp = maxi(0, state.hp - actual)
    if state.hp == 0:
        state.hp = state.max_hp()
        state.gold = maxi(0, state.gold - 25)
        player.global_position = Vector3(0, 2, 0)
        _notify("You were defeated; revived at camp (-25 Gold)")
    else:
        _notify("Monster hit: -%d HP" % actual)
    _save()

func _nearest_mob(max_range: float) -> LeoMob:
    var chosen: LeoMob
    var best := max_range
    for node in get_tree().get_nodes_in_group("monsters"):
        var mob := node as LeoMob
        if not is_instance_valid(mob):
            continue
        var distance := player.global_position.distance_to(mob.global_position)
        if distance < best:
            best = distance
            chosen = mob
    return chosen

func _attack() -> void:
    if attack_timer > 0.0:
        return
    var profile := state.weapon_profile()
    target = _nearest_mob(float(profile["range"]))
    if is_instance_valid(target):
        var stats := state.stats()
        var damage := maxi(1, int((20 + int(stats["STR"]) * 3 + state.weapon_enhancement * 8) * float(profile["power"]) * state.element_damage_multiplier() * attack_buff_multiplier * _passive_damage_multiplier()))
        target.take_damage(damage)
        attack_timer = maxf(0.45, float(profile["cooldown"]) * 0.35)
        _notify("%s hit: %d" % [profile["style"], damage])
    else:
        _notify("No monster in range")

func _cast_skill(slot: int) -> void:
    if slot < 0 or slot > 2 or skill_timers[slot] > 0.0:
        return
    var skill: Dictionary = state.skill_by_id(int(state.equipped_skills[slot]))
    if skill.is_empty() or int(skill["unlock_level"]) > state.level or str(skill["effect"]).begins_with("passive_"):
        _notify("Skill is not available")
        return
    var cost := int(skill["cost"])
    if state.stamina < cost:
        _notify("Not enough MP")
        return
    var effect := str(skill["effect"])
    var rank := int(skill["rank"])
    var stats := state.stats()
    var damage := maxi(1, int((18 + int(stats["STR"]) * 2 + int(stats["INT"]) * 2 + float(skill["power"]) * 20 + state.weapon_enhancement * 8) * state.element_damage_multiplier() * attack_buff_multiplier * _passive_damage_multiplier()))
    var range_value := float(skill["range"])
    var hit_count := 0
    var result_text := ""
    if effect == "heal":
        var healing := 20 + state.level * 2 + rank * 8 + int(stats["INT"]) * 3
        var old_hp := state.hp
        state.hp = mini(state.max_hp(), state.hp + healing)
        hit_count = 1
        result_text = "Restored %d HP" % (state.hp - old_hp)
    elif effect in ["buff_attack", "party_attack"]:
        var attack_bonus := 0.12 + float(rank) * 0.025 + _passive_party_bonus()
        var attack_duration := 7.0 + float(rank)
        if effect == "party_attack":
            _apply_party_combat_buff(attack_bonus, 0.0, 0.0, attack_duration)
            result_text = "Party attack +%d%%" % int(attack_bonus * 100.0)
        else:
            apply_combat_buff(attack_bonus, 0.0, 0.0, attack_duration)
            result_text = "Attack +%d%%" % int(attack_bonus * 100.0)
        hit_count = 1
    elif effect in ["buff_speed", "party_speed"]:
        var speed_bonus := 0.12 + float(rank) * 0.02 + _passive_party_bonus()
        var speed_duration := 7.0 + float(rank)
        if effect == "party_speed":
            _apply_party_combat_buff(0.0, speed_bonus, 0.0, speed_duration)
            result_text = "Party speed +%d%%" % int(speed_bonus * 100.0)
        else:
            apply_combat_buff(0.0, speed_bonus, 0.0, speed_duration)
            result_text = "Move speed +%d%%" % int(speed_bonus * 100.0)
        hit_count = 1
    elif effect == "party_guard":
        var defense_bonus := 0.15 + float(rank) * 0.025 + _passive_party_bonus()
        _apply_party_combat_buff(0.0, 0.0, defense_bonus, 9.0 + float(rank))
        hit_count = 1
        result_text = "Party defense +%d%%" % int(defense_bonus * 100.0)
    elif effect == "armor_break":
        var armor_target := _nearest_mob(range_value)
        if is_instance_valid(armor_target):
            armor_target.apply_armor_break(0.2 + float(rank) * 0.035, 8.0 + float(rank))
            hit_count = 1
            result_text = "Enemy armor reduced"
    elif effect in ["area", "ultimate"]:
        for node in get_tree().get_nodes_in_group("monsters"):
            var mob := node as LeoMob
            if is_instance_valid(mob) and player.global_position.distance_to(mob.global_position) <= range_value:
                mob.take_damage(int(damage * (0.75 if effect == "area" else 1.15)))
                if effect == "ultimate":
                    mob.apply_armor_break(0.15 + float(rank) * 0.025, 6.0 + float(rank))
                hit_count += 1
        result_text = "%d enemies hit" % hit_count
    else:
        var damage_target := _nearest_mob(range_value)
        if is_instance_valid(damage_target):
            damage_target.take_damage(damage)
            hit_count = 1
            result_text = "%d damage" % damage
    if hit_count == 0:
        _notify("No target in range")
        return
    state.stamina -= cost
    skill_timers[slot] = float(skill["cooldown"])
    _notify("%s R%d: %s" % [skill["name"], rank, result_text])
    _save()

func apply_combat_buff(damage_bonus: float, speed_bonus: float, guard_bonus: float, duration: float) -> void:
    if damage_bonus > 0.0:
        attack_buff_multiplier = maxf(attack_buff_multiplier, 1.0 + damage_bonus)
        attack_buff_timer = maxf(attack_buff_timer, duration)
    if speed_bonus > 0.0:
        speed_buff_multiplier = maxf(speed_buff_multiplier, 1.0 + speed_bonus)
        speed_buff_timer = maxf(speed_buff_timer, duration)
    if guard_bonus > 0.0:
        guard_buff_multiplier = maxf(guard_buff_multiplier, 1.0 + guard_bonus)
        guard_buff_timer = maxf(guard_buff_timer, duration)

func _apply_party_combat_buff(damage_bonus: float, speed_bonus: float, guard_bonus: float, duration: float) -> void:
    var members := get_tree().get_nodes_in_group("party_members")
    if members.is_empty():
        apply_combat_buff(damage_bonus, speed_bonus, guard_bonus, duration)
        return
    for member in members:
        if member.has_method("apply_combat_buff"):
            member.apply_combat_buff(damage_bonus, speed_bonus, guard_bonus, duration)

func _passive_damage_multiplier() -> float:
    var bonus := 0.0
    for skill in state.passive_skills():
        if str(skill["effect"]) == "passive_attack":
            bonus += 0.025 * int(skill["rank"])
    return 1.0 + bonus

func _passive_speed_multiplier() -> float:
    var bonus := 0.0
    for skill in state.passive_skills():
        if str(skill["effect"]) == "passive_speed":
            bonus += 0.015 * int(skill["rank"])
    return 1.0 + bonus

func _passive_party_bonus() -> float:
    var bonus := 0.0
    for skill in state.passive_skills():
        if str(skill["effect"]) in ["passive_support", "passive_team"]:
            bonus += 0.02 * int(skill["rank"])
    return bonus

func _cycle_skill_slot(slot: int) -> void:
    var unlocked := state.unlocked_skills()
    if unlocked.size() <= 3:
        _notify("More active skills unlock as you level up")
        return
    var current_id := int(state.equipped_skills[slot])
    var current_position := 0
    for i in range(unlocked.size()):
        if int(unlocked[i]["id"]) == current_id:
            current_position = i
            break
    for offset in range(1, unlocked.size() + 1):
        var candidate_id := int(unlocked[(current_position + offset) % unlocked.size()]["id"])
        var already_equipped := false
        for other_slot in range(3):
            if other_slot != slot and int(state.equipped_skills[other_slot]) == candidate_id:
                already_equipped = true
                break
        if not already_equipped:
            state.equipped_skills[slot] = candidate_id
            _notify("Equipped: %s" % state.skill_by_id(candidate_id)["name"])
            _save()
            return

func _upgrade_equipped_skill(slot: int) -> void:
    var skill_id := int(state.equipped_skills[slot])
    var skill := state.skill_by_id(skill_id)
    if state.upgrade_skill(skill_id):
        _notify("%s upgraded" % skill["name"])
        _save()
    else:
        _notify("Need 1 Skill Point and %d Gold; rank limit %d" % [state.skill_upgrade_gold_cost(skill_id), state.max_skill_rank()])

func _potion() -> void:
    if state.use_potion():
        _notify("Potion used")
    else:
        _notify("No potion needed or available")

func _quest() -> void:
    state.quest_accepted = true
    state.quest_kills = 0
    _notify("Hunt accepted: defeat 5 monsters")

func _open_progression_menu() -> void:
    if is_instance_valid(progression_panel):
        progression_panel.queue_free()
        progression_panel = null
        return
    var title := ""
    var choices: Array = []
    var stage := ""
    if state.element.is_empty():
        if state.level < 10:
            _notify("Choose an element at level 10")
            return
        title = "Choose 1 of 6 Elements"
        choices = state.element_choices()
        stage = "element"
    elif state.branch < 0:
        if state.level < 15:
            _notify("Choose 1 of 6 Paths at level 15")
            return
        title = "Choose 1 of 6 Paths"
        choices = state.path_choices()
        stage = "path"
    elif state.job == "novice":
        if state.level < 30:
            _notify("Choose 1 of 2 Specializations at level 30")
            return
        title = "Choose 1 of 2 Specializations"
        choices = state.specialization_choices()
        stage = "specialization"
    else:
        _notify("Class progression complete")
        return
    progression_panel = Panel.new()
    progression_panel.position = Vector2(12, 164)
    progression_panel.size = Vector2(340, 250)
    hud_layer.add_child(progression_panel)
    var layout := VBoxContainer.new()
    layout.position = Vector2(8, 8)
    layout.size = Vector2(324, 234)
    progression_panel.add_child(layout)
    var heading := Label.new()
    heading.text = title
    layout.add_child(heading)
    var grid := GridContainer.new()
    grid.columns = 2
    layout.add_child(grid)
    for i in range(choices.size()):
        var choice_index := i
        var option := Button.new()
        option.text = str(choices[i])
        option.custom_minimum_size = Vector2(150, 44)
        grid.add_child(option)
        if stage == "element":
            option.pressed.connect(Callable(self, "_select_element").bind(choice_index))
        elif stage == "path":
            option.pressed.connect(Callable(self, "_select_path").bind(choice_index))
        else:
            option.pressed.connect(Callable(self, "_select_specialization").bind(choice_index))
    var close_button := Button.new()
    close_button.text = "CLOSE"
    close_button.custom_minimum_size = Vector2(90, 36)
    close_button.pressed.connect(_close_progression_menu)
    layout.add_child(close_button)

func _close_progression_menu() -> void:
    if is_instance_valid(progression_panel):
        progression_panel.queue_free()
    progression_panel = null

func _apply_player_color() -> void:
    var mesh := player.get_node_or_null("MeshInstance3D") as MeshInstance3D
    if mesh and mesh.material_override is StandardMaterial3D:
        (mesh.material_override as StandardMaterial3D).albedo_color = state.current_job_data()["color"]
    _refresh_player_gear()

func _select_element(index: int) -> void:
    if state.choose_element(index):
        _close_progression_menu()
        _apply_player_color()
        _notify("Element chosen: %s" % state.element)
        _save()

func _select_path(index: int) -> void:
    if state.choose_path(index):
        _close_progression_menu()
        _notify("Path chosen: %s; specialization opens at Lv30" % state.path_choices()[index])
        _save()

func _select_specialization(index: int) -> void:
    if state.choose_specialization(index):
        _close_progression_menu()
        _apply_player_color()
        _notify("Class chosen: %s" % state.current_job_data()["name"])
        _save()

func _upgrade_weapon() -> void:
    if state.upgrade_weapon():
        _refresh_player_gear()
        _notify("Weapon upgraded to +%d" % state.weapon_enhancement)
        _save()
    else:
        _notify("Need 1 Ore and more Gold (max +10)")

func _upgrade_armor() -> void:
    if state.upgrade_armor():
        _refresh_player_gear()
        _notify("Armor upgraded to +%d" % state.armor_enhancement)
        _save()
    else:
        _notify("Need 1 Ore and more Gold (max +10)")

func _notify(message: String) -> void:
    if is_instance_valid(notice):
        notice.text = message

func _save() -> void:
    if is_instance_valid(player):
        state.player_position = player.global_position
        state.save_game()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player):
        _save()
