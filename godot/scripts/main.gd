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
var gear_root: Node3D
var ground_attack_enabled := false

func _ready() -> void:
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
    add_child(layer)
    var label := Label.new()
    label.text = "NexTgenLeo | WASD / touch move | drag to look"
    label.position = Vector2(16, 12)
    layer.add_child(label)
    var note := Label.new()
    note.text = "Tap JOB to change class; bosses and gear are temporary prototypes"
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
    _button(layer, "JOB", Vector2(276, 132), _cycle_job)
    var spec := state.current_job_data()
    var skills: Array = spec["skills"]
    for i in range(3):
        var skill_button := _button(layer, str(skills[i]["name"]), Vector2(18 + i * 112, 180), func(): _cast_skill(i))
        skill_buttons.append(skill_button)
    _button(layer, "WEAPON +", Vector2(18, 228), _upgrade_weapon)
    _button(layer, "ARMOR +", Vector2(145, 228), _upgrade_armor)
    _button(layer, "SAVE", Vector2(260, 228), _save)

func _physics_process(delta: float) -> void:
    attack_timer = maxf(0.0, attack_timer - delta)
    for i in range(skill_timers.size()):
        skill_timers[i] = maxf(0.0, skill_timers[i] - delta)
    var spec := state.current_job_data()
    var stats := state.stats()
    status.text = "%s | Lv.%d HP %d/%d SP %d EXP %d/%d G %d Ore %d\nSTR %d STA %d DEX %d INT %d | Weapon +%d Armor +%d" % [spec["name"], state.level, state.hp, state.max_hp(), state.stamina, state.exp, state.exp_needed(), state.gold, int(state.inventory.get("Ore", 0)), stats["STR"], stats["STA"], stats["DEX"], stats["INT"], state.weapon_enhancement, state.armor_enhancement]
    for i in range(skill_buttons.size()):
        var skills: Array = spec["skills"]
        skill_buttons[i].text = "%s (%d SP)" % [skills[i]["name"], int(skills[i]["cost"])]
        skill_buttons[i].disabled = skill_timers[i] > 0.0 or state.stamina < int(skills[i]["cost"])
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
    player.velocity.x = direction.x * SPEED
    player.velocity.z = direction.z * SPEED
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
        add_child(mob)

func _mob_defeated(mob: LeoMob) -> void:
    state.gain_exp(30)
    state.gold += 10
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
    target = _nearest_mob(3.2)
    if is_instance_valid(target):
        var stats := state.stats()
        target.take_damage(20 + int(stats["STR"]) * 3 + state.weapon_enhancement * 8)
        attack_timer = 0.6
        _notify("Hit %s" % state.current_job_data()["weapon"])
    else:
        _notify("No monster in range")

func _cast_skill(slot: int) -> void:
    if slot < 0 or slot > 2:
        return
    if skill_timers[slot] > 0.0:
        return
    var spec := state.current_job_data()
    var skills: Array = spec["skills"]
    var skill: Dictionary = skills[slot]
    var cost := int(skill["cost"])
    if state.stamina < cost:
        _notify("Not enough SP")
        return
    var mob := _nearest_mob(float(skill["range"]))
    if not is_instance_valid(mob):
        _notify("No target in skill range")
        return
    var stats := state.stats()
    state.stamina -= cost
    var damage := maxi(1, int(18 + int(stats["STR"]) * 2 + int(stats["INT"]) * 2 + float(skill["power"]) * 20 + state.weapon_enhancement * 8))
    mob.take_damage(damage)
    skill_timers[slot] = float(skill["cooldown"])
    _notify("%s: %d damage" % [skill["name"], damage])

func _potion() -> void:
    if state.use_potion():
        _notify("Potion used")
    else:
        _notify("No potion needed or available")

func _quest() -> void:
    state.quest_accepted = true
    state.quest_kills = 0
    _notify("Hunt accepted: defeat 5 monsters")

func _cycle_job() -> void:
    state.cycle_job()
    var mesh := player.get_node_or_null("MeshInstance3D") as MeshInstance3D
    if mesh and mesh.material_override is StandardMaterial3D:
        (mesh.material_override as StandardMaterial3D).albedo_color = state.current_job_data()["color"]
    _refresh_player_gear()
    var skills: Array = state.current_job_data()["skills"]
    for i in range(skill_buttons.size()):
        skill_buttons[i].text = str(skills[i]["name"])
    _notify("Job changed: %s" % state.current_job_data()["name"])
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
