extends Node3D

const PlayerScene := preload("res://player/player.tscn")

@onready var players := $Players

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	if multiplayer.is_server():
		# host is already connected, don't delay spawn
		request_spawn.rpc_id(1, multiplayer.get_unique_id())
	else:
		multiplayer.connected_to_server.connect(_on_connected_to_server)

@rpc("any_peer", "call_local", "reliable")
func request_spawn(peer_id: int) -> void:
	# only server handles spawning
	if multiplayer.is_server():
		spawn_player(peer_id)

func spawn_player(peer_id: int) -> void:
	var player := PlayerScene.instantiate()
	player.name = str(peer_id)
	player.position = Vector3(randf_range(-5, 5), 1, randf_range(-5, 5))
	players.add_child(player, true)  # true = use node name as sync ID

func _on_peer_connected(_peer_id: int) -> void:
	pass

func _on_peer_disconnected(peer_id: int) -> void:
	var player := players.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
		
func _on_connected_to_server() -> void:
	request_spawn.rpc_id(1, multiplayer.get_unique_id())
