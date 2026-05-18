extends Node3D

const PlayerScene := preload("res://player/player.tscn")

@onready var players := $Players

@onready var ready_button := $CanvasLayer/Control/VBoxContainer/ReadyButton
@onready var status_label := $CanvasLayer/Control/VBoxContainer/StatusLabel

var ready_players: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	status_label.text = "0 / 0 ready"
	request_spawn_player()
	
func request_spawn_player() -> void:
	if multiplayer.is_server():
		# host already connected, so do immediately
		request_spawn(multiplayer.get_unique_id())
	else:
		if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			request_spawn.rpc_id(1, multiplayer.get_unique_id())
		else:
			multiplayer.connected_to_server.connect(_on_connected_to_server)

@rpc("any_peer", "call_local", "reliable")
func request_spawn(peer_id: int) -> void:
	# only server handles spawning
	if multiplayer.is_server():
		ready_players[peer_id] = false
		spawn_player(peer_id)
		sync_status()
		

func spawn_player(peer_id: int) -> void:
	var player := PlayerScene.instantiate()
	player.name = str(peer_id)
	player.position = Vector3(randf_range(-5, 5), 1, randf_range(-5, 5))
	players.add_child(player, true)  # true = use node name as sync ID

func _on_peer_connected(_peer_id: int) -> void:
	pass

func _on_peer_disconnected(peer_id: int) -> void:
	ready_players.erase(peer_id)
	
	var player := players.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	sync_status()
		
func _on_connected_to_server() -> void:
	request_spawn.rpc_id(1, multiplayer.get_unique_id())

func _on_ready_button_pressed() -> void:
	ready_button.disabled = true
	if multiplayer.is_server(): 
		set_ready(multiplayer.get_unique_id())
	else:
		set_ready.rpc_id(1, multiplayer.get_unique_id())
	
@rpc("any_peer", "reliable")
func set_ready(peer_id: int) -> void:
	ready_players[peer_id] = true
	sync_status()
	check_all_ready()
	
func sync_status() -> void:
	var ready_count := ready_players.values().count(true)
	var total := ready_players.size()
	update_status.rpc(ready_count, total)

@rpc("authority", "call_local", "reliable")
func update_status(ready_count: int, total: int) -> void:
	status_label.text = str(ready_count) + " / " + str(total) + " ready"
	
func check_all_ready() -> void:
	if ready_players.is_empty():
		return
	for is_ready in ready_players.values():
		if not is_ready:
			return
	start_game.rpc()

@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
