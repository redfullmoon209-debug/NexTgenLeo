extends Node3D

func _ready() -> void:
    var camera := Camera3D.new()
    camera.position = Vector3(0, 8, 16)
    camera.look_at(Vector3.ZERO, Vector3.UP)
    camera.current = true
    add_child(camera)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, -30, 0)
    add_child(light)

    var ground := MeshInstance3D.new()
    ground.name = "TemporaryGround"
    var mesh := PlaneMesh.new()
    mesh.size = Vector2(20, 20)
    ground.mesh = mesh
    add_child(ground)
