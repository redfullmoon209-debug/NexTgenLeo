extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, name: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + name)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var state = root.get_node("GameState")
	state.class_rank = 0
	state.level = 1
	state.selected_job = ""
	state.faction = ""
	state.inventory.clear()
	state.equipped = {"weapon":{"id":"sword","count":1,"enhancement":4}}
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var game = scene.gameplay
	check(game.owner_gm_button.visible, "Offline Sandbox restores red GM button for local testing")
	check(game._can_use_gm(), "local offline GM is enabled without an online owner role")
	game._show_panel("GM")
	check(game.panel.visible, "Offline Sandbox GM panel is accessible")
	check(not game.network.is_gm, "offline GM does not imply online/server GM privilege")
	check(game.gm_choosers.size() == 3,"GM exposes all three selectors")
	check(game.gm_choosers.job.item_count == 13,"Novice plus twelve professions")
	check(not game.pointer_over_ui(Vector2(650,680)),"world space outside panel remains available")
	game.gm_choosers.job.get_popup().show()
	check(game.pointer_over_ui(Vector2(650,680)),"open dropdown reserves pointer outside parent panel")
	game.gm_choosers.job.get_popup().hide()
	check(game._gm_select("gender","Female",false) and state.gender == "Female","select Female")
	check(game._gm_select("gender","Male",false) and state.gender == "Male","select Male")
	for definition in state.balance.professions:
		check(game._gm_select("job",definition.id,false),"GM selects " + str(definition.id))
		check(state.selected_element == definition.element and state.equipped.weapon.id == definition.weapon,"matching element and weapon")
	check(state.class_rank == 5,"profession test raises class minimum to five")
	check(state.inventory.size() == 1 and state.inventory[0].enhancement == 4,"original weapon preserved exactly once")
	check(game._gm_select("faction","Dark",false) and state.class_rank == 7,"Dark unlocked for GM")
	check(game._gm_select("faction","Light",false) and state.faction == "Light","switch Light")
	check(game._gm_select("faction","",false) and state.faction == "" and scene.joystick_base.color.a == 0,"clear faction removes faction ring")
	check(game._gm_select("job","",false) and state.selected_job == "" and state.equipped.weapon.id == "sword","Novice restores starter test weapon")
	check(not game._gm_select("gender","invalid",false),"invalid gender rejected")
	check(not game._gm_select("job","invalid",false),"invalid job rejected")
	check(not game._gm_select("faction","invalid",false),"invalid faction rejected")
	game.network.active = true
	game._set_gm_authorized(false)
	check(not game.owner_gm_button.visible and not game.panel.visible, "unverified online client cannot see or open GM")
	check(not game._gm_select("gender","Female",false) and state.gender == "Male","online GM mutations blocked")
	game.network.active = false
	game._set_gm_authorized(false)
	check(game.owner_gm_button.visible, "disconnect restores local GM button for sandbox testing")
	check(not game.network.is_gm, "disconnect does not grant server privilege")
	scene.queue_free()
	await process_frame
	print("GM TESTS: %d checks; %d failures" % [checks,failures])
	quit(1 if failures else 0)
