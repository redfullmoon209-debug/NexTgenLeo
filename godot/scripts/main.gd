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

func _ready() -> void:
    _setup_input()
    _make_world()
    _make_player()
    _load_thailand()
    _make_hud()

func _setup_input() -> void:
    for item in [{"action":"move_forward","key":KEY_W},{"action":"move_back","key":KEY_S},{"action":"move_left","key":KEY_A},{"action":"move_right","key":KEY_D}]:
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
    player.position = Vector3(0, 2, 0)
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
    material.albedo_color = Color(0.2, 0.4, 0.9)
    mesh.material_override = material
    player.add_child(mesh)
    camera_pivot = Node3D.new()
    camera_pivot.position.y = 1.4
    player.add_child(camera_pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0, 3.2, 8)
    camera.current = true
    camera_pivot.add_child(camera)
    camera_pivot.rotation.x = pitch

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
    label.text = "NexTgenLeo Thailand 3D | WASD move | Drag to rotate | Mouse wheel zoom"
    label.position = Vector2(16, 14)
    layer.add_child(label)
    var note := Label.new()
    note.text = "Mobile: left thumb move, right thumb camera"
    note.position = Vector2(16, 42)
    layer.add_child(note)

func _physics_process(delta: float) -> void:
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
    if not player.is_on_floor():
        player.velocity.y -= 20.0 * delta
    else:
        player.velocity.y = 0.0
    player.move_and_slide()
    if direction.length() > 0.1:
        player.rotation.y = lerp_angle(player.rotation.y, atan2(-direction.x, -direction.z), min(delta * 12.0, 1.0))

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        _rotate_camera(event.relative)
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera.position.z = max(2.5, camera.position.z - 1.0)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera.position.z = min(25.0, camera.position.z + 1.0)
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
    pitch = clamp(pitch - relative.y * LOOK_SENSITIVITY, -1.15, 0.25)
    camera_pivot.rotation.x = pitch
