extends Node3D
## A small visual-only adapter for artist-owned glTF characters.
## Existing CharacterBody3D, collision, combat, progression and equipment
## data remain owned by gameplay.gd. This scene only supplies rendered art.

@export var source_scene: PackedScene
@export_range(0.5, 3.0, 0.01) var target_height_m: float = 1.72
@export_range(-180.0, 180.0, 1.0) var facing_yaw_degrees: float = 0.0
@export var hidden_mesh_names: PackedStringArray = PackedStringArray()

var visual_loaded: bool = false
var rendered_height_m: float = 0.0
var rendered_mesh_count: int = 0

func _ready() -> void:
	# A duplicate of the displayed avatar already contains its imported mesh.
	# Never instantiate the source a second time inside bag preview SubViewports.
	if has_node("ModelFit"):
		visual_loaded = true
		return
	if source_scene == null:
		push_warning("No source character model assigned; keeping procedural fallback")
		return
	var model: Node = source_scene.instantiate()
	if not (model is Node3D):
		model.queue_free()
		push_warning("Character model root must be Node3D")
		return
	var model_fit := Node3D.new()
	model_fit.name = "ModelFit"
	add_child(model_fit)
	model_fit.add_child(model)

	var bounds := AABB()
	var found := false
	var to_visit: Array[Node] = [model]
	var root_inverse: Transform3D = model_fit.global_transform.affine_inverse()
	while not to_visit.is_empty():
		var current: Node = to_visit.pop_back()
		if current is MeshInstance3D:
			var mesh_node: MeshInstance3D = current as MeshInstance3D
			# Some Blender exports include a helper/collision Cube that is
			# larger than and visually occludes the authored character.
			# Exclude only names explicitly configured in the model scene.
			if mesh_node.name in hidden_mesh_names:
				mesh_node.visible = false
			elif mesh_node.mesh != null:
				var local_bounds: AABB = mesh_node.get_aabb()
				var to_fit: Transform3D = root_inverse * mesh_node.global_transform
				for vertex_index in range(8):
					var point: Vector3 = to_fit * local_bounds.get_endpoint(vertex_index)
					if not found:
						bounds = AABB(point, Vector3.ZERO)
						found = true
					else:
						bounds = bounds.expand(point)
				rendered_mesh_count += 1
		for child in current.get_children():
			to_visit.append(child)

	if not found or bounds.size.y < 0.001:
		model_fit.queue_free()
		push_warning("Imported character has no usable mesh bounds; keeping procedural fallback")
		return
	# Imported files may use centimeters, meters, or arbitrary export units.
	# Fit their standing height and place the feet at local Y=0, without
	# changing the live player's collision capsule or movement speed.
	var uniform_scale := clampf(target_height_m / bounds.size.y, 0.0001, 1000.0)
	model_fit.scale = Vector3.ONE * uniform_scale
	model_fit.position = Vector3(
		-bounds.get_center().x * uniform_scale,
		-bounds.position.y * uniform_scale,
		-bounds.get_center().z * uniform_scale
	)
	model_fit.rotation_degrees.y = facing_yaw_degrees
	rendered_height_m = bounds.size.y * uniform_scale
	visual_loaded = true
