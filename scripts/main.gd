extends Node3D

const SPEED := 5.0
const RUN_SPEED := 8.0
const JUMP_SPEED := 6.5
const GRAVITY := 18.0

var player: CharacterBody3D
var camera_pivot: Node3D
var camera: Camera3D
var joystick_vector := Vector2.ZERO
var joystick_finger := -1
var look_finger := -1
var joystick_origin := Vector2.ZERO
var look_previous := Vector2.ZERO
var jump_requested := false
var run_enabled := false
var yaw := 0.0
var pitch := -0.28
var hud: Control
var joystick_base: ColorRect
var joystick_knob: ColorRect
var jump_button: Button
var run_button: Button
var gameplay: Node
var auto_destination := Vector3.INF
var touches: Dictionary = {}
var pinch_distance := 0.0
var visual: Node3D
var dash_time := 0.0
var fly_enabled := false
var mouse_look_button := 0

func _ready() -> void:
	_make_world()
	_make_player()
	_make_hud()
	get_viewport().size_changed.connect(_layout_touch_ui)
	gameplay = load("res://scripts/gameplay.gd").new()
	gameplay.world = self
	add_child(gameplay)
	var fantasy_skin: Node = load("res://scripts/fantasy_ui_theme.gd").new()
	add_child(fantasy_skin)
	# Isolated Settings Rich Menu; other HUD and gameplay systems remain unchanged.
	var settings_menu: Node = load("res://scripts/settings_rich_menu.gd").new()
	settings_menu.set("gameplay", gameplay)
	add_child(settings_menu)
	# Buttons 3-8: reusable isolated gold menus; GM and Settings retain their original systems.
	var primary_navigation: Node = load("res://scripts/main_rich_navigation.gd").new()
	primary_navigation.gameplay = gameplay
	add_child(primary_navigation)

func _make_world() -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.shadow_enabled = GameState.settings.quality == "High"
	add_child(light)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.66, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.8, 0.9)
	env.ambient_light_energy = 0.7
	environment.environment = env
	add_child(environment)
	_add_box(Vector3(0, -0.5, 0), Vector3(80, 1, 80), Color(0.24, 0.48, 0.28), true)
	for i in range(28):
		var angle := float(i) * TAU / 28.0
		var radius := 12.0 + float(i % 4) * 3.5
		var pos := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		_add_box(pos + Vector3(0, 1.2, 0), Vector3(0.55, 2.4, 0.55), Color(0.38, 0.25, 0.14), false)
		_add_sphere(pos + Vector3(0, 3, 0), 1.5, Color(0.12, 0.37 + 0.03 * float(i % 3), 0.17))

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material

func _add_box(pos: Vector3, size: Vector3, color: Color, solid: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	mesh_instance.position = pos
	add_child(mesh_instance)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.position = pos
		body.add_child(shape)
		add_child(body)

func _add_sphere(pos: Vector3, radius: float, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	mesh_instance.position = pos
	add_child(mesh_instance)

func _make_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 1.2, 0)
	add_child(player)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collider.shape = capsule
	player.add_child(collider)
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.38
	body_mesh.height = 1.8
	body.mesh = body_mesh
	body.material_override = _material(Color(0.25, 0.48, 0.95))
	player.add_child(body)
	var face := MeshInstance3D.new()
	var face_mesh := BoxMesh.new()
	face_mesh.size = Vector3(0.28, 0.16, 0.12)
	face.mesh = face_mesh
	face.position = Vector3(0, 0.35, -0.37)
	face.material_override = _material(Color(0.95, 0.85, 0.55))
	player.add_child(face)
	camera_pivot = Node3D.new()
	add_child(camera_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0, 6.5)
	camera.current = true
	camera_pivot.add_child(camera)

func _make_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	# In-game HUD now owns the top-left area. Keep keyboard help in README,
	# not overlapping the 3D player status and quest panels.
	joystick_base = ColorRect.new()
	joystick_base.color = Color(0.08, 0.12, 0.18, 0.0)
	joystick_base.size = Vector2(128, 128)
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_shader := Shader.new()
	base_shader.code = "shader_type canvas_item;\nvoid fragment() { vec2 p = UV * 2.0 - vec2(1.0); float r = length(p); float ring = smoothstep(0.74, 0.82, r) * (1.0 - smoothstep(0.92, 1.0, r)); COLOR = vec4(COLOR.rgb, COLOR.a * ring); }"
	var base_material := ShaderMaterial.new()
	base_material.shader = base_shader
	joystick_base.material = base_material
	hud.add_child(joystick_base)
	joystick_knob = ColorRect.new()
	joystick_knob.color = Color(0.6, 0.8, 1.0, 0.7)
	joystick_knob.size = Vector2(52, 52)
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var thumb_shader := Shader.new()
	thumb_shader.code = "shader_type canvas_item;\nvoid fragment() { vec2 p = UV * 2.0 - vec2(1.0); float r = length(p); float alpha = 1.0 - smoothstep(0.84, 1.0, r); vec3 tint = mix(vec3(0.20, 0.42, 0.68), vec3(0.84, 0.94, 1.0), 1.0 - UV.y); float rim = smoothstep(0.63, 0.82, r) * (1.0 - smoothstep(0.92, 0.99, r)); COLOR = vec4(tint + vec3(rim * 0.12), alpha * 0.94); }"
	var thumb_material := ShaderMaterial.new()
	thumb_material.shader = thumb_shader
	joystick_knob.material = thumb_material
	hud.add_child(joystick_knob)
	jump_button = Button.new()
	jump_button.text = "กระโดด"
	jump_button.size = Vector2(100, 72)
	jump_button.button_down.connect(func(): jump_requested = true)
	hud.add_child(jump_button)
	run_button = Button.new()
	run_button.text = "วิ่ง: ปิด"
	run_button.size = Vector2(100, 55)
	run_button.pressed.connect(_toggle_run)
	hud.add_child(run_button)
	var steel = load("res://scripts/celestial_steel.gd")
	for item in [[jump_button, "jump"], [run_button, "run"]]:
		var button: Button = item[0]
		var kind: String = item[1]
		button.set_meta("leo_fantasy_skin", true)
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, steel.movement_style(kind, state))
		button.add_theme_color_override("font_color", Color("#F1F7FF"))
		button.add_theme_font_size_override("font_size", 14)
	_layout_touch_ui()

func _layout_touch_ui() -> void:
	if hud == null:
		return
	var responsive = load("res://scripts/responsive_ui.gd")
	var bounds: Rect2 = responsive.safe_bounds(get_viewport())
	var portrait: bool = responsive.is_portrait(bounds.size)
	var scale: float = responsive.input_scale(bounds, float(GameState.settings.get("ui_scale", 1.0)))
	joystick_base.size = Vector2.ONE * (128.0 * scale)
	joystick_knob.size = Vector2.ONE * (52.0 * scale)
	joystick_origin = Vector2(bounds.position.x + 78.0 * scale, bounds.end.y - 98.0 * scale)
	joystick_base.position = joystick_origin - joystick_base.size / 2.0
	_update_knob()
	jump_button.size = (Vector2(88.0, 66.0) if portrait else Vector2(100.0, 72.0)) * scale
	run_button.size = (Vector2(84.0, 50.0) if portrait else Vector2(100.0, 55.0)) * scale
	if portrait:
		jump_button.position = Vector2(bounds.end.x - jump_button.size.x, bounds.end.y - 330.0 * scale)
		run_button.position = Vector2(bounds.position.x + 145.0 * scale, bounds.end.y - run_button.size.y)
	else:
		jump_button.position = Vector2(bounds.end.x - jump_button.size.x - 13.0 * scale, bounds.end.y - jump_button.size.y - 1.0 * scale)
		run_button.position = Vector2(bounds.position.x + 163.0 * scale, bounds.end.y - run_button.size.y - 3.0 * scale)
	jump_button.position = responsive.keep_inside(Rect2(jump_button.position, jump_button.size), bounds).position
	run_button.position = responsive.keep_inside(Rect2(run_button.position, run_button.size), bounds).position

func _update_knob() -> void:
	joystick_knob.position = joystick_origin + joystick_vector * joystick_base.size.x * 0.33 - joystick_knob.size / 2.0

func _toggle_run() -> void:
	run_enabled = not run_enabled
	run_button.text = "วิ่ง: เปิด" if run_enabled else "วิ่ง: ปิด"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
		else:
			touches.erase(event.index)
			pinch_distance = 0.0
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.45 and joystick_finger == -1:
				joystick_finger = event.index
				_set_joystick(event.position)
			elif look_finger == -1 and event.position.y < get_viewport().get_visible_rect().size.y * 0.7:
				look_finger = event.index
				look_previous = event.position
		else:
			if event.index == joystick_finger:
				joystick_finger = -1
				joystick_vector = Vector2.ZERO
				_update_knob()
			if event.index == look_finger:
				look_finger = -1
	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
		var camera_touches: Array = []
		for finger in touches:
			if finger != joystick_finger:
				camera_touches.append(touches[finger])
		if camera_touches.size() == 2:
			var distance: float = camera_touches[0].distance_to(camera_touches[1])
			if pinch_distance > 0:
				camera.position.z = clampf(camera.position.z - (distance - pinch_distance) * 0.025, 2.5, 16.0)
			pinch_distance = distance
			return
		if event.index == joystick_finger:
			_set_joystick(event.position)
		elif event.index == look_finger:
			_rotate_camera(event.position - look_previous)
			look_previous = event.position

func _set_joystick(position: Vector2) -> void:
	joystick_vector = ((position - joystick_origin) / maxf(32.0, joystick_base.size.x * 0.43)).limit_length(1.0)
	_update_knob()

func _rotate_camera(delta: Vector2) -> void:
	yaw -= delta.x * 0.005
	pitch = clampf(pitch - delta.y * 0.004, -0.85, -0.08)

func _physics_process(delta: float) -> void:
	var keyboard := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	var movement := joystick_vector if joystick_vector.length_squared() > 0.001 else keyboard.normalized()
	camera_pivot.rotation = Vector3(pitch, yaw, 0)
	var forward := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var direction := (right * movement.x + forward * -movement.y).normalized()
	if movement.length() > 0.05:
		auto_destination = Vector3.INF
	if auto_destination != Vector3.INF:
		var offset := auto_destination - player.position
		offset.y = 0
		direction = offset.normalized() if offset.length() > 1.8 else Vector3.ZERO
	if GameState.hp <= 0:
		direction = Vector3.ZERO
	dash_time = maxf(0, dash_time - delta)
	var speed := RUN_SPEED if run_enabled or Input.is_key_pressed(KEY_SHIFT) else SPEED
	if GameState.buff_active("speed"):
		speed *= 1.25
	if dash_time > 0:
		speed = 20.0
		if direction.is_zero_approx():
			direction = -player.basis.z
	player.velocity.x = direction.x * speed
	player.velocity.z = direction.z * speed
	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	elif jump_requested or Input.is_key_pressed(KEY_SPACE):
		player.velocity.y = JUMP_SPEED
	jump_requested = false
	if fly_enabled:
		player.velocity.y = 5.0 if Input.is_key_pressed(KEY_SPACE) or jump_requested else -1.0
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -38, 38)
	player.position.z = clampf(player.position.z, -38, 38)
	if player.position.y < -10:
		player.position = Vector3(0, 2, 0)
	if direction.length_squared() > 0.001:
		player.rotation.y = atan2(-direction.x, -direction.z)
	camera_pivot.global_position = player.global_position

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
		if not event.pressed:
			if event.button_index == mouse_look_button: mouse_look_button = 0
		elif is_instance_valid(gameplay) and not gameplay.pointer_over_ui(event.position) and not gameplay.layout_edit:
			mouse_look_button = event.button_index
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and mouse_look_button != 0:
		if is_instance_valid(gameplay) and (gameplay.panel.visible or (is_instance_valid(gameplay.silver_workspace) and gameplay.silver_workspace.visible) or gameplay.layout_edit):
			mouse_look_button = 0
		else:
			_rotate_camera(event.relative)
			get_viewport().set_input_as_handled()
		return
	# Camera wheel belongs to the world when menus are closed, independent of GUI focus.
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		if is_instance_valid(gameplay) and not gameplay.panel.visible and not (is_instance_valid(gameplay.silver_workspace) and gameplay.silver_workspace.visible):
			camera.position.z = clampf(camera.position.z + (-0.6 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.6),2.5,16.0)
			get_viewport().set_input_as_handled()
			return
	# Release must work even when a finger ends over a GUI control.
	if event is InputEventScreenTouch and not event.pressed:
		touches.erase(event.index)
		pinch_distance = 0.0
		if event.index == joystick_finger:
			joystick_finger = -1
			joystick_vector = Vector2.ZERO
			_update_knob()
		if event.index == look_finger: look_finger = -1

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		mouse_look_button = 0
		joystick_finger = -1
		look_finger = -1
		joystick_vector = Vector2.ZERO
		touches.clear()
		if is_instance_valid(joystick_knob): _update_knob()
