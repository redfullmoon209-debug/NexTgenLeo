extends CharacterBody3D
class_name LeoMob

signal defeated(mob: LeoMob)
var health := 60
var speed := 2.0
var target: Node3D
var attack_timer := 0.0
var alive := true

func _ready() -> void:
    add_to_group("monsters")
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.height = 1.4
    capsule.radius = 0.45
    shape.shape = capsule
    shape.position.y = 0.7
    add_child(shape)
    var mesh := MeshInstance3D.new()
    var body := CapsuleMesh.new()
    body.height = 1.4
    body.radius = 0.45
    mesh.mesh = body
    mesh.position.y = 0.7
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.75, 0.24, 0.18)
    mesh.material_override = mat
    add_child(mesh)

func _physics_process(delta: float) -> void:
    if not alive or not is_instance_valid(target):
        return
    var difference := target.global_position - global_position
    difference.y = 0
    if difference.length() > 3.0 and difference.length() < 14.0:
        var direction := difference.normalized()
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = 0
        velocity.z = 0
    velocity.y -= 20.0 * delta
    move_and_slide()
    attack_timer = maxf(0.0, attack_timer - delta)

func take_damage(amount: int) -> void:
    if not alive:
        return
    health -= amount
    if health <= 0:
        alive = false
        defeated.emit(self)
        queue_free()
