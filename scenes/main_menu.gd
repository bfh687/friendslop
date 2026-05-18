extends Control

const lobby_scene = "res://scenes/game.tscn"

func _ready() -> void:
	SteamManager.lobby_created.connect(_on_lobby_created)
	SteamManager.lobby_joined.connect(_on_lobby_joined)

func _on_host_button_pressed() -> void:
	%StatusLabel.text = "Creating lobby..."
	SteamManager.create_lobby()

func _on_join_button_pressed() -> void:
	var id := int(%LobbyInput.text)
	if id == 0:
		%StatusLabel.text = "Enter a valid lobby ID"
		return
	%StatusLabel.text = "Joining..."
	SteamManager.join_lobby(id)

func _on_lobby_created(lobby_id: int) -> void:
	%StatusLabel.text = "Lobby ID: " + str(lobby_id) 
	# may not want to automatically swap scenes
	Engine.get_main_loop().change_scene_to_file(lobby_scene)

func _on_lobby_joined(_lobby_id: int) -> void:
	Engine.get_main_loop().change_scene_to_file(lobby_scene)
