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
    var mobs: Array = []
    var loaded_mobs = game.get("monsters")
    if loaded_mobs is Array:
        mobs = loaded_mobs
    else:
        _check(false, "gameplay script loaded and monsters array exists")
        game.queue_free()
        quit(1)
        return
    _check(actor != null, "CharacterBody3D player created")
    _check(cam != null and cam.current, "third-person camera created")
    _check(fox != null, "Auto Loot fox created")
    _check(mobs.size() == 12, "12 3D forest monsters spawned")
    _check(game.get("player_level") == 1, "starts at level one")
    if actor != null:
        var start_z := actor.position.z
        Input.action_press("leo_forward")
        for tick in range(12):
            await physics_frame
        Input.action_release("leo_forward")
        _check(actor.position.z < start_z - 0.05, "WASD action moves character in live physics")
        var start_x := actor.position.x
        game.set("joystick_axis", Vector2(1.0, 0.0))
        for tick in range(12):
            await physics_frame
        game.set("joystick_axis", Vector2.ZERO)
        _check(actor.position.x > start_x + 0.05, "virtual joystick moves character in live physics")
    game.call("_gain_xp", 100)
    _check(game.get("player_level") == 2, "XP advances player level")
    var visual := game.get("player_visual") as Node3D
    _check(visual != null and visual.scale.x > 0.7, "level increases model height")
    if actor != null and mobs.size() > 0:
        var mob := mobs[0] as Node3D
        actor.position = mob.position + Vector3(0, 0, 2.0)
        game.set("target", mob)
        var physical_attack := InputEventKey.new()
        physical_attack.pressed = true
        physical_attack.physical_keycode = KEY_F
        physical_attack.keycode = 0
        game.call("_input", physical_attack)
        _check(int(mob.get_meta("hp")) == 26, "physical F attacks despite non-English keyboard layout")
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
    if actor != null and mobs.size() > 1:
        var second_mob := mobs[1] as Node3D
        actor.position = second_mob.position + Vector3(0, 0, 2.0)
        game.set("target", second_mob)
        game.set("stamina", 100.0)
        game.call("_use_skill", 0)
        _check(int(second_mob.get_meta("hp")) == 20, "skill 1 deals area damage")
        _check(float(game.get("stamina")) == 82.0, "skill 1 consumes stamina")
        var cooldowns: Array = game.get("skill_cooldowns")
        _check(float(cooldowns[0]) > 5.0, "skill 1 starts cooldown")
        game.call("_use_skill", 0)
        _check(int(second_mob.get_meta("hp")) == 20, "skill cooldown prevents repeat hit")
        game.set("attack_lock", 0.0)
        game.call("_use_skill", 2)
        _check(not second_mob.visible, "skill 3 critical strike defeats monster")
        _check(float(game.get("stamina")) == 47.0, "skill 3 consumes stamina")
    game.queue_free()
    await process_frame
    if failures > 0:
        printerr("GODOT SMOKE: ", failures, " failure(s)")
        quit(1)
    else:
        print("GODOT SMOKE: PASS")
        quit(0)
