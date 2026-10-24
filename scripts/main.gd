extends Node3D

const ITEM_DATA = preload("res://scripts/item_catalog.gd")
var catalog := ITEM_DATA.new()
var player: CharacterBody3D
var pet: Node3D
var drops: Array[Area3D] = []
var inventory: Dictionary = {"exp_2x_1h": 1, "sword_basic": 1, "pet_food": 2}
var gold := 100
var cash := 100
var exp_multiplier := 1.0
var exp_seconds := 0.0
var pet_enabled := true
var ui: CanvasLayer
var info: Label
var detail: Label
var move_input := Vector2.ZERO
var touch_id := -1
var touch_start := Vector2.ZERO
var camera_pivot: Node3D

func _ready() -> void:
    _make_world()
    _make_player()
    _make_pet()
    _make_ui()
    _spawn_loot()

func _make_world() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.36, 0.58, 0.83)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.8, 0.86, 1.0)
    env.ambient_light_energy = 0.65
    environment.environment = env
    add_child(environment)
    var light := DirectionalLight3D.new()
    add_child(light)
    light.rotation_degrees = Vector3(-50, -25, 0)
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    add_child(ground)
    var mesh := MeshInstance3D.new()
    var plane := BoxMesh.new()
    plane.size = Vector3(70, 1, 70)
    mesh.mesh = plane
    mesh.position.y = -0.5
    mesh.material_override = _material(Color(0.19, 0.37, 0.27))
    ground.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(70, 1, 70)
    collision.shape = shape
    collision.position.y = -0.5
    ground.add_child(collision)

func _material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    return m

func _make_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 1.2, 0)
    add_child(player)
    var collider := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.38
    shape.height = 1.8
    collider.shape = shape
    collider.position.y = 0.9
    player.add_child(collider)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    body.mesh = capsule
    body.position.y = 0.9
    body.material_override = _material(Color(0.23, 0.48, 0.88))
    player.add_child(body)
    var weapon := MeshInstance3D.new()
    weapon.name = "EquippedWeapon"
    var blade := BoxMesh.new()
    blade.size = Vector3(0.12, 1.3, 0.18)
    weapon.mesh = blade
    weapon.position = Vector3(0.55, 1.2, 0)
    weapon.material_override = _material(Color(0.86, 0.83, 0.68))
    player.add_child(weapon)
    camera_pivot = Node3D.new()
    add_child(camera_pivot)
    var camera := Camera3D.new()
    camera.position = Vector3(0, 3.0, 9)
    camera.current = true
    camera_pivot.add_child(camera)
    camera_pivot.rotation.x = -0.23

func _make_pet() -> void:
    pet = Node3D.new()
    pet.name = "AutoLootPet"
    add_child(pet)
    var body := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.43
    sphere.height = 0.75
    body.mesh = sphere
    body.material_override = _material(Color(0.96, 0.72, 0.28))
    pet.add_child(body)
    pet.position = Vector3(-2, 0.55, 1)

func _spawn_loot() -> void:
    for i in range(8):
        var area := Area3D.new()
        area.name = "Loot_%d" % i
        area.position = Vector3(cos(i * TAU / 8.0) * 9, 0.45, sin(i * TAU / 8.0) * 9)
        var collision := CollisionShape3D.new()
        var sphere := SphereShape3D.new()
        sphere.radius = 0.55
        collision.shape = sphere
        area.add_child(collision)
        var mesh := MeshInstance3D.new()
        var visual := SphereMesh.new()
        visual.radius = 0.24
        visual.height = 0.45
        mesh.mesh = visual
        mesh.material_override = _material(Color(0.35, 0.95, 0.8))
        area.add_child(mesh)
        add_child(area)
        drops.append(area)

func _make_ui() -> void:
    ui = CanvasLayer.new()
    add_child(ui)
    info = Label.new()
    info.position = Vector2(18, 12)
    ui.add_child(info)
    detail = Label.new()
    detail.position = Vector2(18, 60)
    detail.text = "NexTgenLeo | Phase 1+ assets prototype"
    ui.add_child(detail)
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_top = -160
    ui.add_child(panel)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(0, 155)
    panel.add_child(scroll)
    var row := HBoxContainer.new()
    scroll.add_child(row)
    for id in catalog.ids():
        var data: Dictionary = catalog.get_item(id)
        var button := Button.new()
        button.custom_minimum_size = Vector2(100, 110)
        button.text = str(data.get("glyph", "?")) + "\n" + str(data.get("name", id)) + "\n" + str(data.get("cost", 0)) + " Cash"
        button.pressed.connect(_select_item.bind(id))
        row.add_child(button)
    var buy := Button.new()
    buy.text = "Buy selected"
    buy.position = Vector2(18, 95)
    ui.add_child(buy)
    buy.pressed.connect(_buy_selected)
    var use := Button.new()
    use.text = "Use selected"
    use.position = Vector2(135, 95)
    ui.add_child(use)
    use.pressed.connect(_use_selected)
    var pet_button := Button.new()
    pet_button.text = "Pet ON/OFF"
    pet_button.position = Vector2(250, 95)
    ui.add_child(pet_button)
    pet_button.pressed.connect(func(): pet_enabled = not pet_enabled)
    _select_item("exp_2x_1h")

var selected_id := ""
func _select_item(id: String) -> void:
    selected_id = id
    var item: Dictionary = catalog.get_item(id)
    detail.text = "%s | %s | owned: %d" % [str(item.get("name", id)), str(item.get("description", "")), int(inventory.get(id, 0))]

func _buy_selected() -> void:
    var item: Dictionary = catalog.get_item(selected_id)
    var price := int(item.get("cost", 0))
    if cash < price:
        detail.text = "Not enough Cash"
        return
    cash -= price
    inventory[selected_id] = int(inventory.get(selected_id, 0)) + 1
    _select_item(selected_id)

func _use_selected() -> void:
    if int(inventory.get(selected_id, 0)) <= 0:
        detail.text = "Item not owned"
        return
    var item: Dictionary = catalog.get_item(selected_id)
    var kind := str(item.get("kind", ""))
    if kind == "exp":
        exp_multiplier = 2.0
        exp_seconds = float(item.get("hours", 1)) * 3600.0
    elif kind == "pet":
        pet_enabled = true
    elif kind == "weapon":
        var weapon := player.get_node("EquippedWeapon") as MeshInstance3D
        weapon.visible = true
    elif kind == "consumable":
        pass
    else:
        detail.text = "Preview only: gameplay effect not implemented"
        return
    inventory[selected_id] = int(inventory[selected_id]) - 1
    _select_item(selected_id)

func _physics_process(delta: float) -> void:
    var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if move_input.length() > 0.1:
        move = move_input
    player.velocity.x = move.x * 5.0
    player.velocity.z = move.y * 5.0
    if not player.is_on_floor():
        player.velocity.y -= 20.0 * delta
    else:
        player.velocity.y = 0
    player.move_and_slide()
    camera_pivot.global_position = player.global_position + Vector3.UP * 1.2
    if pet_enabled:
        var destination := player.global_position + Vector3(-1.5, -0.65, 1.5)
        for drop in drops:
            if is_instance_valid(drop) and pet.global_position.distance_to(drop.global_position) < 6.0:
                destination = drop.global_position
                break
        pet.global_position = pet.global_position.move_toward(destination, delta * 4.0)
        pet.position.y = 0.5 + sin(Time.get_ticks_msec() / 230.0) * 0.12
        for drop in drops.duplicate():
            if is_instance_valid(drop) and pet.global_position.distance_to(drop.global_position) < 0.75:
                drops.erase(drop)
                drop.queue_free()
                inventory["upgrade_stone"] = int(inventory.get("upgrade_stone", 0)) + 1
    pet.visible = pet_enabled
    exp_seconds = maxf(0.0, exp_seconds - delta)
    if exp_seconds == 0:
        exp_multiplier = 1.0
    info.text = "Cash: %d | Gold: %d | EXP x%.0f (%.0fs) | Loot: %d | Pet: %s" % [cash, gold, exp_multiplier, exp_seconds, int(inventory.get("upgrade_stone", 0)), "ON" if pet_enabled else "OFF"]

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and event.position.x < get_viewport().get_visible_rect().size.x * 0.45 and touch_id == -1:
            touch_id = event.index
            touch_start = event.position
        elif not event.pressed and event.index == touch_id:
            touch_id = -1
            move_input = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == touch_id:
        move_input = ((event.position - touch_start) / 80.0).limit_length(1.0)
