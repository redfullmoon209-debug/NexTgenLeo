extends SceneTree
## Runs under Godot itself, not a JS mock. Checks scene load and core gameplay.
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error("SMOKE FAILED: " + message)
    else:
        print("SMOKE OK: " + message)

func _run() -> void:
    var packed := load("res://godot_src/main.tscn") as PackedScene
    _check(packed != null, "main scene can load")
    if packed == null:
        quit(1)
        return
    var game := packed.instantiate()
    root.add_child(game)
    await process_frame
    var actor := game.get("player") as CharacterBody3D
    var cam := game.get("camera") as Camera3D
    var fox := game.get("fox") as Node3D
    var mobs: Array = game.get("monsters")
    _check(actor != null, "CharacterBody3D player created")
    _check(cam != null and cam.current, "third-person camera created")
    _check(fox != null, "Auto Loot fox created")
    _check(mobs.size() == 12, "12 3D forest monsters spawned")
    _check(game.get("player_level") == 1, "starts at level one")
    game.call("_gain_xp", 100)
    _check(game.get("player_level") == 2, "XP advances player level")
    _check(game.get("player_visual").scale.x > 0.7, "level increases model height")
    if actor != null and mobs.size() > 0:
        var mob := mobs[0] as Node3D
        actor.position = mob.position + Vector3(0, 0, 2.0)
        game.set("target", mob)
        game.call("_attack")
        _check(int(mob.get_meta("hp")) == 26, "basic attack deals damage")
        _check(game.get("auto_attack") == true, "auto-attack continues after first hit")
        game.set("attack_timer", 0.0)
        game.set("attack_lock", 0.0)
        game.call("_perform_hit")
        game.set("attack_timer", 0.0)
        game.set("attack_lock", 0.0)
        game.call("_perform_hit")
        _check(not mob.visible, "monster dies after third hit")
        _check((game.get("drops") as Array).size() == 1, "monster creates loot")
        _check(game.get("auto_attack") == false, "auto-attack stops when target dies")
        var before_gold := int(game.get("gold"))
        for i in range(40):
            game.call("_update_fox", 0.2)
        _check(int(game.get("gold")) > before_gold, "fox collects dropped gold")
    game.queue_free()
    await process_frame
    if failures > 0:
        printerr("GODOT SMOKE: ", failures, " failure(s)")
        quit(1)
    else:
        print("GODOT SMOKE: PASS")
        quit(0)
