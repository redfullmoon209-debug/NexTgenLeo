extends Node3D
## Real Godot 4.4.1 3D prototype. The original Work/Three.js game is not modified.
const TOUCH_HUD = preload("res://godot_src/touch_hud.gd")
const SAVE_PATH = "user://nextgenleo_godot_playtest_v1.json"
const HUMAN_M = "res://assets/models/mini-dungeon/character-human.glb"
const HUMAN_F = "res://assets/models/mini-forest/character-archer.glb"
const ORC = "res://assets/models/mini-dungeon/character-orc.glb"
const FOX = "res://assets/models/fox.glb"
const TREE = "res://assets/models/mini-forest/tree.glb"
const TREE_HIGH = "res://assets/models/mini-forest/tree-high.glb"
const ROCK = "res://assets/models/mini-forest/rocks-low.glb"

var player: CharacterBody3D
var camera: Camera3D
var fox: Node3D
var monsters: Array[Node3D] = []
var drops: Array[Node3D] = []
var target: Node3D = null
var target_marker: Node3D
var target_health_label: Label3D
var auto_attack := false
var attack_timer := 0.0
var combo_step := 0
var combo_window := 0.0
var skill_cooldowns := [0.0, 0.0, 0.0]
const SKILL_COSTS = [18.0, 25.0, 35.0]
const SKILL_DELAYS = [6.0, 9.0, 14.0]
var skill_feedback_timer := 0.0
var dash_timer := 0.0
var dash_direction := Vector3(0, 0, -1)
var attack_lock := 0.0
var jump_queued := false
var player_level := 1
var player_xp := 0
var stamina := 100.0
var active_gender := "male"
var player_visual: Node3D
var camera_yaw := 0.0
var camera_pitch := 0.42
var camera_distance := 9.0
var gold := 0
var inventory: Array = []
var equipment: Dictionary = {}
var bag_panel: PanelContainer
var bag_grid: GridContainer
var bag_info: Label
var character_status_label: Label
var character_equipment_label: Label
var bag_page := 0
const ITEM_NAMES = {"hp_potion": "HP Potion", "life_trace": "Life Trace", "forest_helm": "Forest Helm", "forest_sword": "Forest Sword"}
const ITEM_SLOTS = {"forest_helm": "Hat", "forest_sword": "Weapon"}
var kills := 0
var hp := 100
var status := "Starter Forest • Godot 4.4.1 • เลือกเป้าหมายด้วย Tab"
var stats_label: Label
var help_label: Label
var hud: Control
var joystick_id := -1
var joystick_origin := Vector2.ZERO
var joystick_axis := Vector2.ZERO
var keyboard_axis := Vector2.ZERO
var held_keys: Dictionary = {}
var mouse_joystick := false
var mouse_joystick_origin := Vector2.ZERO
var input_debug_timer := 0.0
var pc_attack_was_down := false
var pc_lock_was_down := false
var pc_dash_was_down := false
var look_id := -1
var last_look := Vector2.ZERO
var touches: Dictionary = {}
var action_touches: Dictionary = {}
var pinch_distance := -1.0
var fox_animation: AnimationPlayer
var player_animation: AnimationPlayer

func _ready() -> void:
    _install_movement_actions()
    _build_world()
    _build_player()
    _load_progress()
    _build_monsters()
    _build_target_marker()
    _build_fox()
    _build_ui()
    _refresh_bag()
    _update_camera(1.0)
    _set_status("Starter Forest • Tab ล็อก • F ตี • 1/2/3 ใช้สกิล")

func _install_movement_actions() -> void:
    # Web builds need explicit actions and physical-key support, independent of keyboard layout.
    var bindings := {
        "leo_left": [KEY_A, KEY_LEFT],
        "leo_right": [KEY_D, KEY_RIGHT],
        "leo_forward": [KEY_W, KEY_UP],
        "leo_back": [KEY_S, KEY_DOWN]
    }
    bindings["leo_attack"] = [KEY_F, KEY_ENTER, KEY_KP_ENTER]
    bindings["leo_lock"] = [KEY_TAB]
    bindings["leo_skill1"] = [KEY_1]
    bindings["leo_skill2"] = [KEY_2]
    bindings["leo_skill3"] = [KEY_3]
    bindings["leo_dash"] = [KEY_SHIFT, KEY_Q]
    for action_name in bindings:
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)
        for code in bindings[action_name]:
            var key := InputEventKey.new()
            key.physical_keycode = code
            InputMap.action_add_event(action_name, key)
            var logical_key := InputEventKey.new()
            logical_key.keycode = code
            InputMap.action_add_event(action_name, logical_key)

func _update_key_state(event: InputEventKey) -> void:
    var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
    if code in [KEY_A, KEY_D, KEY_W, KEY_S, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
        held_keys[code] = event.pressed
    keyboard_axis = Vector2.ZERO
    if held_keys.get(KEY_A, false) or held_keys.get(KEY_LEFT, false):
        keyboard_axis.x -= 1.0
    if held_keys.get(KEY_D, false) or held_keys.get(KEY_RIGHT, false):
        keyboard_axis.x += 1.0
    if held_keys.get(KEY_W, false) or held_keys.get(KEY_UP, false):
        keyboard_axis.y += 1.0
    if held_keys.get(KEY_S, false) or held_keys.get(KEY_DOWN, false):
        keyboard_axis.y -= 1.0

func _set_mouse_stick(point: Vector2) -> void:
    var delta := (point - mouse_joystick_origin) / 65.0
    joystick_axis = Vector2(clampf(delta.x, -1.0, 1.0), clampf(-delta.y, -1.0, 1.0)).limit_length(1.0)
    if hud != null:
        hud.call("set_joystick", joystick_axis)

func _load_progress() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    if not (data is Dictionary) or data.get("version") != 1:
        return
    player_level = clampi(int(data.get("level", 1)), 1, 100)
    player_xp = clampi(int(data.get("xp", 0)), 0, player_level * 100 - 1)
    gold = clampi(int(data.get("gold", 0)), 0, 100000000)
    if data.get("inventory", []) is Array:
        inventory = data.get("inventory", []).slice(0, 200)
    if data.get("equipment", {}) is Dictionary:
        equipment = data.get("equipment", {})
    kills = clampi(int(data.get("kills", 0)), 0, 100000000)
    _apply_level_scale()

func _save_progress() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({"version": 1, "level": player_level, "xp": player_xp, "gold": gold, "kills": kills, "inventory": inventory, "equipment": equipment}))

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.85
    return mat

func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    mesh.mesh = shape
    mesh.material_override = _material(color)
    mesh.position = pos
    parent.add_child(mesh)
    return mesh

func _sphere(parent: Node3D, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var shape := SphereMesh.new()
    shape.radius = radius
    shape.height = radius * 2.0
    mesh.mesh = shape
    mesh.material_override = _material(color)
    mesh.position = pos
    parent.add_child(mesh)
    return mesh

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.56, 0.76, 0.91)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.75, 0.82, 0.92)
    environment.ambient_light_energy = 0.9
    env.environment = environment
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -35, 0)
    sun.light_energy = 1.8
    sun.shadow_enabled = true
    add_child(sun)
    var ground := StaticBody3D.new()
    ground.name = "ForestGround"
    add_child(ground)
    _box(ground, Vector3(120, 0.3, 120), Vector3(0, -0.15, 0), Color(0.26, 0.47, 0.26))
    var collision := CollisionShape3D.new()
    var ground_shape := BoxShape3D.new()
    ground_shape.size = Vector3(120, 0.3, 120)
    collision.shape = ground_shape
    collision.position.y = -0.15
    ground.add_child(collision)
    _box(self, Vector3(4.0, 0.04, 72.0), Vector3(0, 0.025, -9), Color(0.55, 0.46, 0.30))
    var rng := RandomNumberGenerator.new()
    rng.seed = 2092026
    for i in range(42):
        var x := rng.randf_range(-43.0, 43.0)
        var z := rng.randf_range(-43.0, 43.0)
        if absf(x) < 5.0 and z > -35.0 and z < 22.0:
            x += 8.0 if x >= 0.0 else -8.0
        var tree := Node3D.new()
        tree.name = "ForestTree_%d" % i
        tree.position = Vector3(x, 0, z)
        tree.rotation.y = rng.randf_range(-PI, PI)
        add_child(tree)
        if not _attach_model(tree, TREE_HIGH if i % 4 == 0 else TREE, rng.randf_range(4.0, 7.0)):
            _box(tree, Vector3(0.45, 3.5, 0.45), Vector3(0, 1.75, 0), Color(0.34, 0.23, 0.12))
            _sphere(tree, 2.0, Vector3(0, 4.0, 0), Color(0.13, 0.35, 0.16))
    for i in range(22):
        var rock := Node3D.new()
        rock.position = Vector3(rng.randf_range(-36.0, 36.0), 0, rng.randf_range(-36.0, 36.0))
        add_child(rock)
        if not _attach_model(rock, ROCK, rng.randf_range(0.6, 1.5)):
            _box(rock, Vector3(1.3, 0.65, 1.1), Vector3(0, 0.32, 0), Color(0.43, 0.47, 0.44))
    camera = Camera3D.new()
    camera.name = "ThirdPersonCamera"
    camera.current = true
    camera.fov = 58.0
    camera.near = 0.08
    camera.far = 170.0
    add_child(camera)

func _first_mesh(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D and node.mesh != null:
        return node as MeshInstance3D
    for child in node.get_children():
        var found := _first_mesh(child)
        if found != null:
            return found
    return null

func _find_animation(node: Node) -> AnimationPlayer:
    if node is AnimationPlayer:
        return node as AnimationPlayer
    for child in node.get_children():
        var found := _find_animation(child)
        if found != null:
            return found
    return null

func _attach_model(parent: Node3D, path: String, target_height: float) -> bool:
    if not ResourceLoader.exists(path):
        return false
    var packed := load(path) as PackedScene
    if packed == null:
        return false
    var visual := packed.instantiate() as Node3D
    if visual == null:
        return false
    parent.add_child(visual)
    var mesh := _first_mesh(visual)
    if mesh != null:
        var size_y := maxf(mesh.get_aabb().size.y, 0.05)
        visual.scale = Vector3.ONE * clampf(target_height / size_y, 0.02, 10.0)
    return true

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "PlayerMalePlaceholder"
    player.position = Vector3(0, 0.2, 6)
    add_child(player)
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.8
    shape.shape = capsule
    shape.position.y = 0.9
    player.add_child(shape)
    var body := Node3D.new()
    player_visual = body
    body.name = "CharacterVisual"
    player.add_child(body)
    if not _attach_model(body, HUMAN_M, 1.8):
        _box(body, Vector3(0.75, 1.2, 0.4), Vector3(0, 1.05, 0), Color(0.26, 0.44, 0.86))
        _sphere(body, 0.32, Vector3(0, 1.85, 0), Color(0.96, 0.77, 0.59))
    player_animation = _find_animation(body)
    _apply_level_scale()
    _box(body, Vector3(0.11, 1.0, 0.12), Vector3(0.43, 1.05, 0.15), Color(0.84, 0.86, 0.91))

func _build_monsters() -> void:
    for i in range(12):
        var mob := Node3D.new()
        mob.name = "ForestOrc_%02d" % i
        var angle := float(i) * TAU / 12.0
        var radius := 9.0 + float(i % 4) * 3.5
        mob.position = Vector3(sin(angle) * radius, 0, -8.0 + cos(angle) * radius)
        mob.set_meta("hp", 50)
        mob.set_meta("spawn", mob.position)
        mob.set_meta("respawn_at", -1.0)
        add_child(mob)
        if not _attach_model(mob, ORC, 1.7):
            _box(mob, Vector3(0.9, 1.4, 0.65), Vector3(0, 0.8, 0), Color(0.50, 0.22, 0.19))
            _sphere(mob, 0.34, Vector3(0, 1.7, 0), Color(0.41, 0.62, 0.27))
        monsters.append(mob)

func _build_target_marker() -> void:
    target_marker = Node3D.new()
    target_marker.name = "TargetIndicator"
    add_child(target_marker)
    var ring := MeshInstance3D.new()
    var ring_mesh := CylinderMesh.new()
    ring_mesh.top_radius = 0.82
    ring_mesh.bottom_radius = 0.82
    ring_mesh.height = 0.035
    ring.mesh = ring_mesh
    ring.material_override = _material(Color(0.9, 0.24, 0.15, 0.65))
    ring.position.y = 0.045
    target_marker.add_child(ring)
    target_health_label = Label3D.new()
    target_health_label.position.y = 2.2
    target_health_label.font_size = 38
    target_health_label.pixel_size = 0.008
    target_health_label.modulate = Color(1.0, 0.92, 0.8)
    target_health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    target_marker.add_child(target_health_label)
    target_marker.visible = false

func _update_target_marker() -> void:
    if not is_instance_valid(target) or not target.visible:
        target_marker.visible = false
        return
    target_marker.visible = true
    target_marker.position = target.position
    target_health_label.text = "%s • HP %d/50" % [target.name, max(0, int(target.get_meta("hp")))]

func _build_fox() -> void:
    fox = Node3D.new()
    fox.name = "SpiritFoxAutoLootPlaceholder"
    fox.position = player.position + Vector3(1.4, 0, 1.4)
    add_child(fox)
    if not _attach_model(fox, FOX, 0.7):
        _box(fox, Vector3(0.65, 0.35, 0.9), Vector3(0, 0.36, 0), Color(0.86, 0.94, 1.0))
        _sphere(fox, 0.26, Vector3(0, 0.65, -0.32), Color(0.94, 0.97, 1.0))
    fox_animation = _find_animation(fox)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)
    stats_label = Label.new()
    stats_label.position = Vector2(18, 12)
    stats_label.add_theme_font_size_override("font_size", 20)
    stats_label.add_theme_color_override("font_color", Color(1, 1, 1))
    stats_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
    stats_label.add_theme_constant_override("shadow_offset_x", 2)
    stats_label.add_theme_constant_override("shadow_offset_y", 2)
    root.add_child(stats_label)
    help_label = Label.new()
    help_label.position = Vector2(18, 47)
    help_label.add_theme_font_size_override("font_size", 16)
    help_label.add_theme_color_override("font_color", Color(1, 0.94, 0.74))
    root.add_child(help_label)
    hud = TOUCH_HUD.new()
    hud.set_anchors_preset(Control.PRESET_FULL_RECT)
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root.add_child(hud)
    hud.call("set_skills", skill_cooldowns, stamina)
    _build_bag(root)
    _refresh_ui()

func _set_status(message: String) -> void:
    status = message
    _refresh_ui()

func _refresh_ui() -> void:
    if stats_label == null:
        return
    if bag_panel != null and bag_panel.visible:
        _refresh_character_status()
    stats_label.text = "NexTgenLeo • GODOT 3D   Lv.%d   EXP %d/%d   HP %d   SP %d   Gold %d   Kills %d" % [player_level, player_xp, player_level * 100, hp, int(stamina), gold, kills]
    var target_name: String = str(target.name) if is_instance_valid(target) and target.visible else "ไม่มี"
    help_label.text = "%s  |  เป้า: %s" % [status, target_name]

func _apply_level_scale() -> void:
    # Level 1 = 70% of adult height; Level 100 = 100%, preserving original game design.
    if is_instance_valid(player_visual):
        player_visual.scale = Vector3.ONE * (0.7 + 0.3 * float(player_level - 1) / 99.0)

func _gain_xp(amount: int) -> void:
    if player_level >= 100:
        return
    player_xp += amount
    while player_level < 100 and player_xp >= player_level * 100:
        player_xp -= player_level * 100
        player_level += 1
        _apply_level_scale()
        hp = 100
        _set_status("LEVEL UP! • Lv.%d" % player_level)
    if player_level >= 100:
        player_xp = 0

func _update_camera(delta: float) -> void:
    if not is_instance_valid(player):
        return
    var focus := player.global_position + Vector3(0, 1.45, 0)
    var forward := Vector3(sin(camera_yaw), 0, -cos(camera_yaw))
    var desired := focus - forward * cos(camera_pitch) * camera_distance + Vector3.UP * sin(camera_pitch) * camera_distance
    # Keep the third-person camera in front of level geometry instead of clipping through it.
    var ray := PhysicsRayQueryParameters3D.create(focus, desired)
    ray.exclude = [player.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(ray)
    if not hit.is_empty():
        desired = hit.position + (focus - desired).normalized() * 0.35
    camera.global_position = camera.global_position.lerp(desired, minf(1.0, delta * 10.0))
    camera.look_at(focus, Vector3.UP)

func _move_input() -> Vector2:
    var actions := Input.get_vector("leo_left", "leo_right", "leo_back", "leo_forward")
    var axis := actions + keyboard_axis
    # Keep polling as a fallback for browsers that do not deliver key-up consistently.
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        axis.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        axis.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        axis.y += 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        axis.y -= 1.0
    return (axis + joystick_axis).limit_length(1.0)

func _physics_process(delta: float) -> void:
    # Poll keyboard actions as well as events: web and non-English layouts can differ.
    var attack_down := Input.is_action_pressed("leo_attack") or Input.is_physical_key_pressed(KEY_F) or Input.is_key_pressed(KEY_F)
    if attack_down and not pc_attack_was_down:
        _attack()
    pc_attack_was_down = attack_down
    var lock_down := Input.is_action_pressed("leo_lock") or Input.is_physical_key_pressed(KEY_TAB)
    if lock_down and not pc_lock_was_down:
        _select_nearest()
    pc_lock_was_down = lock_down
    combo_window = maxf(0.0, combo_window - delta)
    for skill_index in range(3):
        skill_cooldowns[skill_index] = maxf(0.0, float(skill_cooldowns[skill_index]) - delta)
    if hud != null:
        hud.call("set_skills", skill_cooldowns, stamina)
    var dash_down := Input.is_action_pressed("leo_dash") or Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_Q)
    if dash_down and not pc_dash_was_down:
        _dash()
    pc_dash_was_down = dash_down
    attack_timer = maxf(0.0, attack_timer - delta)
    attack_lock = maxf(0.0, attack_lock - delta)
    dash_timer = maxf(0.0, dash_timer - delta)
    stamina = minf(100.0, stamina + delta * 5.0)
    if jump_queued and attack_lock <= 0.0:
        jump_queued = false
        _jump()
    var axis := _move_input()
    input_debug_timer -= delta
    if axis.length_squared() > 0.02 and input_debug_timer <= 0.0:
        input_debug_timer = 0.45
        _set_status("MOVE INPUT %.2f %.2f • Position %.1f %.1f" % [axis.x, axis.y, player.position.x, player.position.z])
    var forward := Vector3(sin(camera_yaw), 0, -cos(camera_yaw))
    var right := Vector3(cos(camera_yaw), 0, sin(camera_yaw))
    var direction := (right * axis.x + forward * axis.y).normalized()
    if dash_timer > 0.0:
        direction = dash_direction
    elif attack_lock > 0.0:
        direction = Vector3.ZERO
    elif auto_attack and is_instance_valid(target) and target.visible:
        var toward := target.global_position - player.global_position
        toward.y = 0
        if toward.length() > 2.7:
            direction = toward.normalized()
        else:
            direction = Vector3.ZERO
            _perform_hit()
    elif auto_attack:
        auto_attack = false
    var speed := 5.0
    if dash_timer > 0.0:
        speed = 11.0
    player.velocity.x = direction.x * speed
    player.velocity.z = direction.z * speed
    player.velocity.y -= 19.0 * delta
    player.move_and_slide()
    if direction.length_squared() > 0.001:
        player.rotation.y = atan2(direction.x, direction.z)
    if attack_lock > 0.0 and dash_timer <= 0.0:
        _play_clip(player_animation, "attack")
    elif not player.is_on_floor():
        _play_clip(player_animation, "jump")
    else:
        _play_clip(player_animation, "run" if direction.length_squared() > 0.001 else "idle")
    for mob in monsters:
        if not mob.visible:
            if Time.get_ticks_msec() / 1000.0 >= float(mob.get_meta("respawn_at")):
                mob.visible = true
                mob.set_meta("hp", 50)
                mob.position = mob.get_meta("spawn")
            continue
        var toward := player.position - mob.position
        toward.y = 0
        if toward.length() < 8.0 and toward.length() > 2.0:
            mob.position += toward.normalized() * delta * 0.85
            mob.rotation.y = atan2(toward.x, toward.z)
    _update_fox(delta)
    _update_target_marker()
    _update_camera(delta)

func _play_clip(anim: AnimationPlayer, hint: String) -> void:
    if anim == null:
        return
    for clip in anim.get_animation_list():
        if hint in String(clip).to_lower():
            if anim.current_animation != clip:
                anim.play(clip)
            return

func _update_fox(delta: float) -> void:
    var destination := player.position + Vector3(1.1, 0, 1.2)
    var pickup: Node3D = null
    var best := 11.0
    for drop in drops:
        var dist := player.position.distance_to(drop.position)
        if dist < best:
            best = dist
            pickup = drop
    if pickup != null:
        destination = pickup.position
    var diff := destination - fox.position
    diff.y = 0
    if diff.length() > 0.45:
        fox.position += diff.normalized() * minf(diff.length(), delta * 6.0)
        fox.rotation.y = atan2(diff.x, diff.z)
        _play_clip(fox_animation, "run")
    else:
        _play_clip(fox_animation, "survey")
    if pickup != null and fox.position.distance_to(pickup.position) < 0.75:
        drops.erase(pickup)
        pickup.queue_free()
        var item_id := str(pickup.get_meta("item_id", "gold"))
        if item_id == "gold":
            gold += 10
        else:
            _add_item(item_id, 1)
        _save_progress()
        _refresh_bag()
        _set_status("จิ้งจอก Auto Loot เก็บ %s" % item_id)
    if fox.position.distance_to(player.position) > 30:
        fox.position = player.position + Vector3(1, 0, 1)

func _select_nearest() -> void:
    var nearest := 30.0
    target = null
    for mob in monsters:
        if mob.visible:
            var dist := mob.position.distance_to(player.position)
            if dist < nearest:
                nearest = dist
                target = mob
    _set_status("ล็อกเป้าแล้ว" if target != null else "ไม่มีมอนสเตอร์ในระยะ")

func _select_at_screen(point: Vector2) -> void:
    var nearest := 65.0
    var selected: Node3D = null
    for mob in monsters:
        if not mob.visible or camera.is_position_behind(mob.global_position + Vector3.UP):
            continue
        var projected := camera.unproject_position(mob.global_position + Vector3.UP)
        var dist := projected.distance_to(point)
        if dist < nearest:
            nearest = dist
            selected = mob
    if selected != null:
        target = selected
        _set_status("แตะเลือกเป้าหมายแล้ว")

func _attack() -> void:
    if target == null or not is_instance_valid(target) or not target.visible:
        auto_attack = false
        _set_status("ATK รับคำสั่งแล้ว แต่ต้องล็อกเป้าหมายก่อน (Tab)")
        return
    auto_attack = true
    _set_status("ATK รับคำสั่ง • กำลังเข้าหา %s" % target.name)
    if player.position.distance_to(target.position) > 2.8:
        _set_status("วิ่งเข้าระยะโจมตีอัตโนมัติ")
        return
    _perform_hit()

func _perform_hit() -> void:
    if not is_instance_valid(target) or not target.visible or attack_timer > 0.0 or dash_timer > 0.0:
        return
    if player.position.distance_to(target.position) > 2.8:
        return
    combo_step = (combo_step % 3) + 1 if combo_window > 0.0 else 1
    combo_window = 2.0
    attack_timer = 0.62
    attack_lock = 0.38
    _damage_monster(target, 24, false)
    if is_instance_valid(target) and target.visible:
        _set_status("Basic Combo %d/3 • มอนสเตอร์ HP %d" % [combo_step, int(target.get_meta("hp"))])

func _damage_monster(mob: Node3D, damage: int, critical: bool = false) -> void:
    if not is_instance_valid(mob) or not mob.visible:
        return
    var remaining := int(mob.get_meta("hp")) - damage
    mob.set_meta("hp", remaining)
    _show_damage(mob, damage, critical)
    if remaining > 0:
        return
    var drop := Node3D.new()
    drop.name = "GoldDrop"
    drop.position = mob.position + Vector3(0, 0.4, 0)
    add_child(drop)
    _sphere(drop, 0.28, Vector3.ZERO, Color(1.0, 0.8, 0.15))
    drop.set_meta("item_id", ["gold", "hp_potion", "life_trace", "forest_helm", "forest_sword"][kills % 5])
    drops.append(drop)
    mob.visible = false
    mob.set_meta("respawn_at", Time.get_ticks_msec() / 1000.0 + 8.0)
    if mob == target:
        target = null
        auto_attack = false
    kills += 1
    _gain_xp(35)
    _save_progress()
    _set_status("กำจัดมอนสเตอร์แล้ว • จิ้งจอกกำลังเก็บของ")

func _show_damage(mob: Node3D, damage: int, critical: bool) -> void:
    var popup := Label3D.new()
    popup.name = "DamagePopup"
    popup.text = ("CRIT " if critical else "-") + str(damage)
    popup.font_size = 52
    popup.pixel_size = 0.008
    popup.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    popup.modulate = Color(1.0, 0.77, 0.2) if critical else Color(1.0, 0.94, 0.85)
    popup.position = mob.global_position + Vector3(0, 2.1, 0)
    add_child(popup)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(popup, "position:y", popup.position.y + 1.3, 0.75)
    tween.tween_property(popup, "modulate:a", 0.0, 0.75)
    tween.set_parallel(false)
    tween.tween_callback(popup.queue_free)

func _use_skill(index: int) -> void:
    if index < 0 or index >= 3:
        return
    if not is_instance_valid(target) or not target.visible:
        _set_status("ต้องล็อกมอนสเตอร์ก่อนใช้สกิล (Tab / LOCK)")
        return
    if float(skill_cooldowns[index]) > 0.0:
        _set_status("Skill %d คูลดาวน์อีก %.1f วินาที" % [index + 1, float(skill_cooldowns[index])])
        return
    if stamina < float(SKILL_COSTS[index]):
        _set_status("Stamina ไม่เพียงพอสำหรับ Skill %d" % [index + 1])
        return
    var max_range := 5.0 if index == 0 else (9.0 if index == 1 else 11.0)
    if player.global_position.distance_to(target.global_position) > max_range:
        _set_status("Skill %d: เป้าหมายอยู่นอกระยะ %.0f เมตร" % [index + 1, max_range])
        return
    stamina -= float(SKILL_COSTS[index])
    skill_cooldowns[index] = float(SKILL_DELAYS[index])
    attack_lock = 0.5
    attack_timer = maxf(attack_timer, 0.5)
    var main_target := target
    if index == 0:
        # Skill 1: circular area attack centered on selected enemy.
        var center := main_target.global_position
        for mob in monsters:
            if mob.visible and mob.global_position.distance_to(center) <= 4.0:
                _damage_monster(mob, 30)
    elif index == 1:
        # Skill 2: line strike, up to nine meters in the selected direction.
        var origin := player.global_position
        var forward := (main_target.global_position - origin).normalized()
        for mob in monsters:
            if not mob.visible:
                continue
            var offset := mob.global_position - origin
            var along := offset.dot(forward)
            if along >= 0.0 and along <= 9.0 and (offset - forward * along).length() <= 1.7:
                _damage_monster(mob, 38)
    else:
        # Skill 3: single-target focused critical strike.
        _damage_monster(main_target, 55, true)
    if hud != null:
        hud.call("set_skills", skill_cooldowns, stamina)
    _set_status("Skill %d ใช้สำเร็จ • SP -%d" % [index + 1, int(SKILL_COSTS[index])])

func _jump() -> void:
    if attack_lock > 0.0:
        jump_queued = true
        return
    if player.is_on_floor():
        player.velocity.y = 7.5

func _dash() -> void:
    if stamina < 15.0:
        _set_status("SP ไม่เพียงพอสำหรับ Dash")
        return
    stamina -= 15.0
    # Dash in the chosen movement direction, or forward when standing still.
    var axis := _move_input()
    var forward := Vector3(sin(camera_yaw), 0, -cos(camera_yaw))
    var right := Vector3(cos(camera_yaw), 0, sin(camera_yaw))
    dash_direction = (right * axis.x + forward * axis.y).normalized() if axis.length_squared() > 0.01 else Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
    if dash_direction.length_squared() < 0.01:
        dash_direction = forward
    attack_lock = 0.0
    auto_attack = false
    dash_timer = 0.32
    _set_status("DASH! • SP -15")

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        _update_key_state(event)
        if not event.pressed or event.echo:
            return
        # Physical keys keep PC controls working when the OS keyboard layout is Thai.
        var action_code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
        if event.keycode == KEY_F or event.physical_keycode == KEY_F or event.unicode == 102 or event.unicode == 70:
            _attack()
            return
        match action_code:
            KEY_TAB:
                _select_nearest()
            KEY_F, KEY_ENTER, KEY_KP_ENTER:
                _attack()
            KEY_1, KEY_KP_1:
                _use_skill(0)
            KEY_2, KEY_KP_2:
                _use_skill(1)
            KEY_3, KEY_KP_3:
                _use_skill(2)
            KEY_B, KEY_I:
                _toggle_bag()
            KEY_SPACE:
                # Space is reserved for Jump. Clear UI focus so it never activates BAG.
                get_viewport().gui_release_focus()
                _jump()
            KEY_SHIFT, KEY_Q:
                pc_dash_was_down = true
                _dash()
            KEY_ESCAPE:
                target = null
                auto_attack = false
                jump_queued = false
                _set_status("ยกเลิกเป้าหมาย")
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and mouse_joystick and not event.pressed:
            mouse_joystick = false
            joystick_axis = Vector2.ZERO
            if hud != null:
                hud.call("set_joystick", joystick_axis)
            return
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            var size := get_viewport().get_visible_rect().size
            if event.position.x < size.x * 0.43 and event.position.y > size.y * 0.38:
                mouse_joystick = true
                mouse_joystick_origin = event.position
                _set_mouse_stick(event.position)
                return
            if _handle_action_touch(event.position, size):
                return
        if event.pressed:
            if event.button_index == MOUSE_BUTTON_WHEEL_UP:
                camera_distance = maxf(3.0, camera_distance - 0.8)
            elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
                camera_distance = minf(19.0, camera_distance + 0.8)
            elif event.button_index == MOUSE_BUTTON_LEFT:
                _select_at_screen(event.position)
    elif event is InputEventMouseMotion:
        if mouse_joystick:
            _set_mouse_stick(event.position)
        elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
            camera_yaw -= event.relative.x * 0.006
            camera_pitch = clampf(camera_pitch + event.relative.y * 0.004, 0.1, 1.2)
    elif event is InputEventScreenTouch:
        _handle_touch(event)
    elif event is InputEventScreenDrag:
        _handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
    var size := get_viewport().get_visible_rect().size
    if event.pressed:
        touches[event.index] = event.position
        if event.position.x < size.x * 0.43 and event.position.y > size.y * 0.38 and joystick_id == -1:
            joystick_id = event.index
            joystick_origin = event.position
        elif _handle_action_touch(event.position, size):
            action_touches[event.index] = true
        elif look_id == -1:
            look_id = event.index
            last_look = event.position
        _reset_pinch()
    else:
        touches.erase(event.index)
        action_touches.erase(event.index)
        if event.index == joystick_id:
            joystick_id = -1
            joystick_axis = Vector2.ZERO
        if event.index == look_id:
            look_id = -1
        _reset_pinch()
    if hud != null:
        hud.call("set_joystick", joystick_axis)

func _handle_action_touch(point: Vector2, size: Vector2) -> bool:
    var actions := [
        [Vector2(size.x * 0.92, size.y * 0.13), 42.0, "bag"],
        [Vector2(size.x * 0.60, size.y * 0.48), 38.0, "skill1"],
        [Vector2(size.x * 0.75, size.y * 0.48), 38.0, "skill2"],
        [Vector2(size.x * 0.90, size.y * 0.48), 38.0, "skill3"],
        [Vector2(size.x * 0.76, size.y * 0.68), 46.0, "lock"],
        [Vector2(size.x * 0.76, size.y * 0.83), 54.0, "attack"],
        [Vector2(size.x * 0.91, size.y * 0.68), 46.0, "jump"],
        [Vector2(size.x * 0.91, size.y * 0.90), 46.0, "dash"]
    ]
    for action in actions:
        if point.distance_to(action[0]) <= float(action[1]):
            match String(action[2]):
                "bag": _toggle_bag()
                "skill1": _use_skill(0)
                "skill2": _use_skill(1)
                "skill3": _use_skill(2)
                "lock": _select_nearest()
                "attack": _attack()
                "jump": _jump()
                "dash": _dash()
            return true
    return false

func _reset_pinch() -> void:
    pinch_distance = -1.0
    if joystick_id != -1 or not action_touches.is_empty() or touches.size() != 2:
        return
    var points := touches.values()
    pinch_distance = (points[0] as Vector2).distance_to(points[1] as Vector2)

func _handle_drag(event: InputEventScreenDrag) -> void:
    touches[event.index] = event.position
    if event.index == joystick_id:
        var drag := (event.position - joystick_origin) / 65.0
        joystick_axis = Vector2(clampf(drag.x, -1, 1), clampf(-drag.y, -1, 1)).limit_length(1.0)
        if hud != null:
            hud.call("set_joystick", joystick_axis)
    elif action_touches.has(event.index):
        return
    elif touches.size() == 2 and joystick_id == -1 and action_touches.is_empty():
        var points := touches.values()
        var dist := (points[0] as Vector2).distance_to(points[1] as Vector2)
        if pinch_distance > 0.0:
            camera_distance = clampf(camera_distance - (dist - pinch_distance) * 0.025, 3.0, 19.0)
        pinch_distance = dist
    elif event.index == look_id:
        camera_yaw -= event.relative.x * 0.007
        camera_pitch = clampf(camera_pitch + event.relative.y * 0.005, 0.1, 1.2)

func _add_item(item_id: String, amount: int) -> bool:
    if not ITEM_NAMES.has(item_id):
        return false
    var stackable := not ITEM_SLOTS.has(item_id)
    if stackable:
        for item in inventory:
            if str(item.get("id", "")) == item_id and int(item.get("count", 0)) < 99:
                var added := mini(amount, 99 - int(item["count"]))
                item["count"] = int(item["count"]) + added
                amount -= added
                if amount == 0:
                    return true
    while amount > 0:
        if inventory.size() >= 200:
            return false
        var count := mini(amount, 99) if stackable else 1
        inventory.append({"id": item_id, "count": count})
        amount -= count
    return true

func _use_inventory_item(index: int) -> void:
    if index < 0 or index >= inventory.size():
        return
    var item: Dictionary = inventory[index]
    var item_id := str(item.get("id", ""))
    if item_id == "hp_potion":
        if hp >= 100:
            _set_status("HP เต็มแล้ว")
            return
        hp = mini(100, hp + 50)
        item["count"] = int(item.get("count", 1)) - 1
        if int(item["count"]) <= 0:
            inventory.remove_at(index)
    elif ITEM_SLOTS.has(item_id):
        equipment[str(ITEM_SLOTS[item_id])] = item_id
    _save_progress()
    _refresh_bag()
    _refresh_ui()

func _toggle_bag() -> void:
    if bag_panel == null:
        return
    bag_panel.visible = not bag_panel.visible
    if bag_panel.visible:
        _refresh_bag()

func _build_bag(root: Control) -> void:
    var bag_button := Button.new()
    bag_button.text = "🎒 BAG"
    bag_button.focus_mode = Control.FOCUS_NONE
    _style_bag_button(bag_button, Color(0.12, 0.34, 0.62))
    bag_button.anchor_left = 1.0
    bag_button.anchor_right = 1.0
    bag_button.anchor_top = 0.0
    bag_button.anchor_bottom = 0.0
    bag_button.offset_left = -112.0
    bag_button.offset_right = -28.0
    bag_button.offset_top = 22.0
    bag_button.offset_bottom = 62.0
    bag_button.mouse_filter = Control.MOUSE_FILTER_STOP
    bag_button.custom_minimum_size = Vector2(84, 40)
    bag_button.pressed.connect(_toggle_bag)
    root.add_child(bag_button)
    bag_panel = PanelContainer.new()
    bag_panel.custom_minimum_size = Vector2(800, 550)
    bag_panel.set_meta("responsive_inventory", true)
    get_viewport().size_changed.connect(_fit_bag_to_screen)
    bag_panel.visible = false
    bag_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    _style_bag_panel(bag_panel)
    root.add_child(bag_panel)
    var layout := HBoxContainer.new()
    layout.add_theme_constant_override("separation", 14)
    bag_panel.add_child(layout)
    var status_column := VBoxContainer.new()
    status_column.custom_minimum_size = Vector2(330, 430)
    layout.add_child(status_column)
    var status_title := Label.new()
    status_title.text = "✦ CHARACTER STATUS"
    status_title.add_theme_color_override("font_color", Color(0.76, 0.91, 1.0))
    status_title.add_theme_font_size_override("font_size", 19)
    status_column.add_child(status_title)
    var separator := HSeparator.new()
    status_column.add_child(separator)
    character_status_label = Label.new()
    character_status_label.add_theme_font_size_override("font_size", 14)
    status_column.add_child(character_status_label)
    _build_character_preview(status_column)
    var equip_title := Label.new()
    equip_title.text = "✦ EQUIPMENT"
    equip_title.add_theme_color_override("font_color", Color(0.76, 0.91, 1.0))
    equip_title.add_theme_font_size_override("font_size", 18)
    status_column.add_child(equip_title)
    character_equipment_label = Label.new()
    character_equipment_label.add_theme_font_size_override("font_size", 15)
    status_column.add_child(character_equipment_label)
    var vertical_divider := VSeparator.new()
    layout.add_child(vertical_divider)
    var content := VBoxContainer.new()
    layout.add_child(content)
    var title := Label.new()
    title.text = "✦ INVENTORY"
    title.add_theme_color_override("font_color", Color(0.76, 0.91, 1.0))
    title.add_theme_font_size_override("font_size", 20)
    content.add_child(title)
    bag_info = Label.new()
    content.add_child(bag_info)
    var paging := HBoxContainer.new()
    content.add_child(paging)
    for page in range(2):
        var button := Button.new()
        button.text = "PAGE %d" % (page + 1)
        button.focus_mode = Control.FOCUS_NONE
        _style_bag_button(button, Color(0.11, 0.33, 0.58))
        button.pressed.connect(_change_bag_page.bind(page))
        paging.add_child(button)
    var close_button := Button.new()
    close_button.text = "X"
    close_button.focus_mode = Control.FOCUS_NONE
    _style_bag_button(close_button, Color(0.65, 0.17, 0.25))
    close_button.pressed.connect(_toggle_bag)
    paging.add_child(close_button)
    var scrolling := ScrollContainer.new()
    scrolling.custom_minimum_size = Vector2(420, 355)
    scrolling.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    content.add_child(scrolling)
    bag_grid = GridContainer.new()
    bag_grid.columns = 10
    bag_grid.add_theme_constant_override("h_separation", 3)
    bag_grid.add_theme_constant_override("v_separation", 3)
    scrolling.add_child(bag_grid)
    call_deferred("_fit_bag_to_screen")

func _change_bag_page(page: int) -> void:
    bag_page = page
    _refresh_bag()

func _refresh_bag() -> void:
    if bag_grid == null or bag_info == null:
        return
    bag_info.text = "Page %d / 2    •    %d / 200 Slots    •    Gold %d" % [bag_page + 1, inventory.size(), gold]
    bag_info.add_theme_color_override("font_color", Color(1.0, 0.81, 0.42))
    if character_status_label != null:
        character_status_label.text = "Gender: %s\nClass: 0 • Novice\nLevel: %d / 100\nEXP: %d / %d\nHP: %d / 100\nStamina: %d / 100\nGold: %d\nKills: %d" % [active_gender.capitalize(), player_level, player_xp, player_level * 100, hp, int(stamina), gold, kills]
    if character_equipment_label != null:
        var equip_text := ""
        for slot_name in ["Hat", "Shirt", "Gloves", "Pants", "Shoes", "Weapon"]:
            equip_text += "%s: %s\n" % [slot_name, str(ITEM_NAMES.get(str(equipment.get(slot_name, "")), "-"))]
        character_equipment_label.text = equip_text
    for child in bag_grid.get_children():
        bag_grid.remove_child(child)
        child.queue_free()
    for slot_index in range(100):
        var index := bag_page * 100 + slot_index
        var cell := Button.new()
        cell.custom_minimum_size = Vector2(39, 39)
        cell.focus_mode = Control.FOCUS_NONE
        cell.add_theme_font_size_override("font_size", 11)
        _style_inventory_cell(cell, index < inventory.size())
        if index < inventory.size():
            var item: Dictionary = inventory[index]
            var item_id := str(item.get("id", ""))
            cell.text = item_id.substr(0, 3).to_upper() + str(item.get("count", 1))
            cell.tooltip_text = str(ITEM_NAMES.get(item_id, item_id))
            cell.pressed.connect(_use_inventory_item.bind(index))
        else:
            cell.text = ""
            cell.disabled = true
        bag_grid.add_child(cell)

func _refresh_character_status() -> void:
    if character_status_label == null:
        return
    character_status_label.text = "Gender: %s\nClass: 0 • Novice\nLevel: %d / 100\nEXP: %d / %d\nHP: %d / 100\nStamina: %d / 100\nGold: %d\nKills: %d" % [active_gender.capitalize(), player_level, player_xp, player_level * 100, hp, int(stamina), gold, kills]

func _build_character_preview(status_column: VBoxContainer) -> void:
    var preview_area := Control.new()
    preview_area.custom_minimum_size = Vector2(330, 326)
    status_column.add_child(preview_area)
    # Center: live 3D preview from the same player mesh resource, not a drawn silhouette.
    var viewport_box := SubViewportContainer.new()
    viewport_box.clip_contents = true
    viewport_box.position = Vector2(72, 5)
    viewport_box.custom_minimum_size = Vector2(180, 275)
    viewport_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    preview_area.add_child(viewport_box)
    var preview_viewport := SubViewport.new()
    preview_viewport.size = Vector2i(180, 275)
    preview_viewport.transparent_bg = true
    preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport_box.add_child(preview_viewport)
    var preview_world := Node3D.new()
    preview_viewport.add_child(preview_world)
    if player_visual != null:
        var model_copy := player_visual.duplicate()
        preview_world.add_child(model_copy)
        model_copy.position = Vector3.ZERO
        model_copy.rotation = Vector3.ZERO
        model_copy.scale = Vector3.ONE
    var preview_camera := Camera3D.new()
    preview_camera.position = Vector3(0, 1.0, 3.6)
    preview_world.add_child(preview_camera)
    preview_camera.look_at(Vector3(0, 0.95, 0), Vector3.UP)
    preview_camera.current = true
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-35, -30, 0)
    light.light_energy = 2.0
    preview_world.add_child(light)
    # Color positions from the provided mockup; buttons are slot placeholders.
    _preview_slot(preview_area, Vector2(8, 8), Color(0.25, 0.75, 0.30), "HAIR")
    _preview_slot(preview_area, Vector2(6, 77), Color(1.0, 0.47, 0.13), "WEAPON R")
    _preview_slot(preview_area, Vector2(6, 146), Color(1.0, 0.47, 0.13), "WEAPON L")
    _preview_slot(preview_area, Vector2(6, 215), Color(1.0, 0.65, 0.77), "FASHION")
    _preview_slot(preview_area, Vector2(267, 8), Color(0.94, 0.13, 0.19), "HAT")
    _preview_slot(preview_area, Vector2(267, 63), Color(0.94, 0.13, 0.19), "SHIRT")
    _preview_slot(preview_area, Vector2(267, 118), Color(0.94, 0.13, 0.19), "GLOVES")
    _preview_slot(preview_area, Vector2(267, 173), Color(0.94, 0.13, 0.19), "PANTS")
    _preview_slot(preview_area, Vector2(267, 228), Color(0.94, 0.13, 0.19), "SHOES")
    _preview_slot(preview_area, Vector2(6, 270), Color(1.0, 0.65, 0.77), "PET")

func _preview_slot(parent: Control, point: Vector2, tint: Color, slot_name: String) -> void:
    var slot := Button.new()
    slot.position = point
    slot.custom_minimum_size = Vector2(51, 51)
    slot.tooltip_text = slot_name
    slot.text = ""
    slot.disabled = true
    slot.focus_mode = Control.FOCUS_NONE
    var style := StyleBoxFlat.new()
    style.bg_color = tint
    style.set_corner_radius_all(25)
    slot.add_theme_stylebox_override("disabled", style)
    parent.add_child(slot)

func _style_bag_panel(panel: PanelContainer) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.035, 0.095, 0.18, 0.96)
    style.border_color = Color(0.25, 0.69, 1.0, 0.98)
    style.set_border_width_all(3)
    style.set_corner_radius_all(12)
    style.set_content_margin_all(12)
    style.shadow_color = Color(0.01, 0.03, 0.08, 0.65)
    style.shadow_size = 12
    panel.add_theme_stylebox_override("panel", style)

func _style_bag_button(button: Button, tint: Color) -> void:
    for state in ["normal", "hover", "pressed", "disabled"]:
        var style := StyleBoxFlat.new()
        style.bg_color = tint.lightened(0.16) if state == "hover" else (tint.darkened(0.20) if state == "pressed" else tint)
        style.border_color = Color(0.44, 0.81, 1.0, 0.95)
        style.set_border_width_all(2)
        style.set_corner_radius_all(7)
        style.set_content_margin_all(5)
        button.add_theme_stylebox_override(state, style)
    button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
    button.add_theme_color_override("font_hover_color", Color.WHITE)

func _style_inventory_cell(button: Button, filled: bool) -> void:
    for state in ["normal", "hover", "pressed", "disabled"]:
        var style := StyleBoxFlat.new()
        style.bg_color = Color(0.14, 0.30, 0.48, 0.97) if filled else Color(0.08, 0.19, 0.32, 0.94)
        if state == "hover":
            style.bg_color = Color(0.21, 0.43, 0.66)
        style.border_color = Color(0.36, 0.69, 0.92, 0.9)
        style.set_border_width_all(1)
        style.set_corner_radius_all(4)
        button.add_theme_stylebox_override(state, style)
    button.add_theme_color_override("font_color", Color(1.0, 0.91, 0.65))

func _fit_bag_to_screen() -> void:
    if bag_panel == null:
        return
    # Measure the actual content after Godot's containers have laid it out.
    # Scale from the real minimum size rather than assuming the panel is 800x550.
    var viewport_size := get_viewport().get_visible_rect().size
    var margin := 12.0
    var top_reserved := minf(74.0, viewport_size.y * 0.09)
    var available := Vector2(maxf(1.0, viewport_size.x - margin * 2.0), maxf(1.0, viewport_size.y - top_reserved - margin))
    var natural_size := bag_panel.get_combined_minimum_size()
    natural_size.x = maxf(natural_size.x, 800.0)
    natural_size.y = maxf(natural_size.y, 550.0)
    var factor := minf(1.0, minf(available.x / natural_size.x, available.y / natural_size.y))
    bag_panel.scale = Vector2.ONE * factor
    var rendered := natural_size * factor
    bag_panel.position = Vector2(maxf(margin, (viewport_size.x - rendered.x) * 0.5), top_reserved + maxf(0.0, (available.y - rendered.y) * 0.5))
