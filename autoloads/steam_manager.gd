extends Node

signal lobby_created(lobby_id)
signal lobby_joined(lobby_id)

var steam_id: int = 0
var lobby_id: int  = 0
var use_steam: bool = true

func _ready() -> void:
	var init = Steam.steamInitEx(480, true)
	if init.status != Steam.STEAM_API_INIT_RESULT_OK:
		push_error("Steam failed to init: " + str(init))
		return
		
	steam_id = Steam.getSteamID()
	
	# init signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_join_requested)

func create_lobby() -> void:
	if use_steam:
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 4)
	else:
		var peer := ENetMultiplayerPeer.new()
		peer.create_server(7777)
		multiplayer.multiplayer_peer = peer
		lobby_created.emit(0);

func _on_lobby_created(result, new_lobby_id) -> void:
	if result != 1:
		push_error("Failed to create lobby: " + str(result))
		return

	Steam.allowP2PPacketRelay(true)
	var peer := SteamMultiplayerPeer.new()
	peer.create_host()
	multiplayer.multiplayer_peer = peer
	
	lobby_id = new_lobby_id
	lobby_joined.emit(lobby_id)
	
func join_lobby(id: int) -> void:
	if use_steam:
		Steam.joinLobby(id)
	else:
		var peer := ENetMultiplayerPeer.new()
		peer.create_client("localhost", 7777)
		multiplayer.multiplayer_peer = peer
		
		lobby_joined.emit(0)

func _on_lobby_joined(new_lobby_id, _permissions, _locked, response) -> void:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		push_error("Failed to join lobby: " + str(response))
		return

	lobby_id = new_lobby_id
	var owner_id := Steam.getLobbyOwner(lobby_id)
	
	if owner_id == steam_id:
		return

	Steam.allowP2PPacketRelay(true)
	var peer := SteamMultiplayerPeer.new()
	peer.create_client(owner_id)
	multiplayer.multiplayer_peer = peer

	lobby_joined.emit(lobby_id)

func _on_lobby_join_requested(requested_lobby_id, _friend_id) -> void:
	join_lobby(requested_lobby_id)
