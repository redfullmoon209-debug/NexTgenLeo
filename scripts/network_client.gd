extends Node
## Optional development WebSocket client. No client save is uploaded.
var game: Node
var socket := WebSocketPeer.new()
var active := false
var connecting := false
var is_gm := false
var id := ""
var url := ""
var request_sequence := 0
var move_timer := 0.0
var action_timer := 0.0
var peers: Dictionary = {}
var offline_backup: Dictionary = {}
var server_position := Vector3.ZERO
var have_snapshot := false
var connection_timer := 0.0
func connect_server(address: String) -> void:
	if not address.begins_with("wss://") and not address.begins_with("ws://127.0.0.1") and not address.begins_with("ws://localhost"):
		game._tell("Use wss:// for remote servers, or ws://localhost for local tests")
		return
	url = address
	offline_backup.clear()
	for key in GameState._save_keys():
		var value = GameState.get(key)
		offline_backup[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	var error := socket.connect_to_url(address)
	if error != OK:
		game._tell("Connection failed: " + str(error))
		return
	connecting = true
	is_gm = false
	game._set_gm_authorized(false)
	connection_timer = 0
	have_snapshot = false
	game._tell("Connecting to development server...")
func authenticate_owner(secret: String) -> void:
	if not active:
		game._tell("ต้องเชื่อมต่อเซิร์ฟเวอร์ก่อนยืนยันสิทธิ์เจ้าของ")
		return
	if secret.length() < 24:
		game._tell("รหัสเจ้าของต้องมีอย่างน้อย 24 ตัวอักษร")
		return
	# Only send credentials to a TLS-protected remote server or localhost.
	if not url.begins_with("wss://") and not url.begins_with("ws://127.0.0.1") and not url.begins_with("ws://localhost"):
		game._tell("ต้องเชื่อมต่อผ่าน WSS")
		return
	command("gm_auth", {"owner_secret":secret})

func command(op: String, fields: Dictionary = {}) -> void:
	if not active: return
	request_sequence += 1
	fields = fields.duplicate()
	fields.op = op
	fields.request = id + ":" + str(Time.get_unix_time_from_system()) + ":" + str(request_sequence)
	socket.send_text(JSON.stringify(fields))
func _process(delta: float) -> void:
	if not active and not connecting: return
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED:
		disconnect_server()
		return
	if connecting:
		connection_timer += delta
		if connection_timer > 15:
			disconnect_server()
			game._tell("Server connection timed out")
			return
	if state != WebSocketPeer.STATE_OPEN: return
	if connecting:
		connecting = false
		active = true
		var session_path := "user://session_" + url.sha256_text().substr(0,16) + ".txt"
		var token := FileAccess.get_file_as_string(session_path) if FileAccess.file_exists(session_path) else ""
		socket.send_text(JSON.stringify({"op":"hello","token":token}))
	while socket.get_available_packet_count() > 0:
		var data = JSON.parse_string(socket.get_packet().get_string_from_utf8())
		if not data is Dictionary: continue
		match str(data.get("type","")):
			"welcome":
				id = data.id
				var file := FileAccess.open("user://session_" + url.sha256_text().substr(0,16) + ".txt", FileAccess.WRITE)
				if file: file.store_string(data.token)
				game._tell("Connected · SERVER AUTHORITY · guest " + id.substr(0,6))
			"snapshot": _snapshot(data)
			"gm_role":
				is_gm = bool(data.get("authorized", false))
				game._set_gm_authorized(is_gm)
				if is_gm: game._tell("ยืนยันสิทธิ์เจ้าของแล้ว: เปิดเมนู GM สีแดงได้")
			"error": game._tell("Server: " + str(data.message))
			"chat": game._tell(str(data.id).substr(0,6) + ": " + str(data.text))
			"result":
				if str(data.message) != "OK": game._tell(str(data.message))
	if not have_snapshot: return
	move_timer += delta
	action_timer = maxf(0,action_timer-delta)
	if move_timer >= 0.1:
		move_timer = 0
		command("move", {"x":game.world.player.position.x,"z":game.world.player.position.z})
func _snapshot(data: Dictionary) -> void:
	var state: Dictionary = data.self
	for key in ["hp","stamina","level","class_rank","exp","gold","cash","quest_state","quest_kills","selected_element","selected_job","faction","pet_level","pet_exp","skill_loadout"]:
		if key in state: GameState.set(key,state[key])
	GameState.inventory.clear()
	for item in state.inventory: GameState.inventory.append(item)
	var previous: String = JSON.stringify(GameState.equipped)
	GameState.equipped = state.equipped
	GameState._recalculate_stats(false)
	if previous != JSON.stringify(state.equipped):game._build_avatar()
	server_position = Vector3(float(state.x),game.world.player.position.y,float(state.z))
	if not have_snapshot or Vector2(game.world.player.position.x-server_position.x,game.world.player.position.z-server_position.z).length()>1.2:
		game.world.player.position = server_position
	have_snapshot = true
	for i in range(mini(data.mobs.size(),game.mobs.size())):
		var mob: Dictionary = data.mobs[i]
		game.mobs[i].hp = int(mob.hp)
		game.mobs[i].max_hp = int(mob.max_hp)
		game.mobs[i].node.position = Vector3(float(mob.x),0,float(mob.z))
		game.mobs[i].node.visible = int(mob.hp)>0
		game.mobs[i].label.text = "Online Mossling Lv.%d\n%d / %d" % [int(mob.level),int(mob.hp),int(mob.max_hp)]
	var seen: Array = []
	for player in data.players:
		if str(player.id) == id: continue
		seen.append(player.id)
		if player.id not in peers:
			var node := Node3D.new()
			game.world.add_child(node)
			game._mesh(node,Vector3(0,0.9,0),Vector3(0.6,1.8,0.6),Color("70b1cc"),"sphere")
			game._tag(node,"Player " + str(player.id).substr(0,6),2.3)
			peers[player.id] = node
		peers[player.id].position = Vector3(float(player.x),0,float(player.z))
	for key in peers.keys():
		if key not in seen:
			peers[key].queue_free()
			peers.erase(key)
func disconnect_server() -> void:
	socket.close()
	active = false
	is_gm = false
	game._set_gm_authorized(false)
	connecting = false
	have_snapshot = false
	for node in peers.values():node.queue_free()
	peers.clear()
	for key in offline_backup:
		GameState.set(key,offline_backup[key])
	GameState._recalculate_stats(false)
	game._build_avatar()
	game._build_zone()
	game.world.player.position = Vector3(0,1,0)
	game._tell("Disconnected. Offline sandbox restored.")
