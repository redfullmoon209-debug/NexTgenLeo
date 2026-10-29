extends SceneTree

class FakeGame extends Node:
	var messages: Array[String] = []
	var gm_authorized := true
	func _tell(message: String) -> void:
		messages.append(message)
	func _set_gm_authorized(value: bool) -> void:
		gm_authorized = value

var checks := 0
var failures := 0

func check(value: bool, name: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + name)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var client = load("res://scripts/network_client.gd").new()
	var game := FakeGame.new()
	root.add_child(game)
	root.add_child(client)
	client.game = game
	client.url = "wss://example.invalid"
	client.reconnect_enabled = true
	client.is_gm = true
	client.active = true
	var delays := [1.0, 2.0, 4.0, 8.0, 15.0]
	for i in range(delays.size()):
		client._handle_connection_loss("test")
		check(client.reconnect_enabled, "retry %d remains enabled" % (i + 1))
		check(client.reconnect_attempt == i + 1, "retry counter increments to %d" % (i + 1))
		check(is_equal_approx(client.reconnect_timer, delays[i]), "retry %d uses bounded backoff" % (i + 1))
		check(not client.is_gm and not game.gm_authorized, "connection loss revokes owner role")
	client._handle_connection_loss("test")
	check(not client.reconnect_enabled and client.reconnect_timer == 0.0, "retry limit stops automatic reconnect")
	check(client.reconnect_attempt == 5, "retry counter stays at maximum")
	client.reconnect_enabled = true
	client.reconnect_attempt = 0
	client._handle_connection_loss("test")
	client.disconnect_server()
	check(not client.reconnect_enabled and client.reconnect_timer == 0.0, "manual disconnect cancels pending retry")
	check(client.reconnect_attempt == 0, "manual disconnect clears retry count")
	client.queue_free()
	game.queue_free()
	await process_frame
	print("NETWORK RECONNECT TESTS: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
