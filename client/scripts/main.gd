extends Node3D

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const NETWORK_SYNC_INTERVAL: float = 0.05

@onready var player := $Player
@onready var target_frame := $CanvasLayer/TargetFrame

var network_manager = null
var remote_players: Dictionary = {}
var network_sync_timer: float = 0.0


func _ready() -> void:
	network_manager = get_node_or_null("/root/NetworkManager")
	if network_manager:
		network_manager.hosting_started.connect(_on_network_identity_changed)
		network_manager.connected_to_server.connect(_on_network_identity_changed)
		network_manager.multiplayer_stopped.connect(_on_network_identity_changed)
		network_manager.peer_joined.connect(_on_peer_joined)
		network_manager.peer_left.connect(_on_peer_left)
	
	_register_local_player()
	
	if player and target_frame:
		player.target_changed.connect(target_frame.set_target)


func _process(delta: float) -> void:
	if not network_manager or not network_manager.has_active_peer():
		return
	
	network_sync_timer -= delta
	if network_sync_timer > 0.0:
		return
	
	network_sync_timer = NETWORK_SYNC_INTERVAL
	var local_peer_id: int = network_manager.get_local_peer_id()
	rpc("_sync_player_transform", local_peer_id, player.global_position, player.global_rotation.y)


func _register_local_player() -> void:
	if not player:
		return
	
	var local_peer_id: int = 1
	if network_manager and network_manager.has_method("get_local_peer_id"):
		local_peer_id = network_manager.get_local_peer_id()
	
	player.set_multiplayer_authority(local_peer_id)
	player.name = "Player_%d" % local_peer_id
	player.is_remote_player = false


func _on_network_identity_changed(_unused = null) -> void:
	_register_local_player()
	
	if network_manager and network_manager.has_active_peer() and not multiplayer.is_server():
		_spawn_remote_player(1, Vector3(2.5, 2.0, 0.0), 0.0)
	
	if not network_manager or not network_manager.has_active_peer():
		_clear_remote_players()


func _on_peer_joined(peer_id: int) -> void:
	if peer_id == network_manager.get_local_peer_id():
		return
	
	_spawn_remote_player(peer_id, Vector3(2.5, 2.0, 0.0), 0.0)
	
	if multiplayer.is_server():
		rpc("_spawn_remote_player", peer_id, Vector3(2.5, 2.0, 0.0), 0.0)
		rpc_id(peer_id, "_spawn_remote_player", 1, player.global_position, player.global_rotation.y)


func _on_peer_left(peer_id: int) -> void:
	_remove_remote_player(peer_id)
	if multiplayer.is_server():
		rpc("_remove_remote_player", peer_id)


@rpc("authority", "call_remote", "reliable")
func _spawn_remote_player(peer_id: int, spawn_position: Vector3, rotation_y: float) -> void:
	if not network_manager or peer_id == network_manager.get_local_peer_id():
		return
	
	if remote_players.has(peer_id):
		var existing_player: Node3D = remote_players[peer_id]
		if existing_player and is_instance_valid(existing_player):
			existing_player.global_position = spawn_position
			existing_player.global_rotation.y = rotation_y
		return
	
	var remote_player: Node3D = PLAYER_SCENE.instantiate()
	remote_player.name = "RemotePlayer_%d" % peer_id
	remote_player.set("is_remote_player", true)
	remote_player.set_multiplayer_authority(peer_id)
	add_child(remote_player)
	remote_player.global_position = spawn_position
	remote_player.global_rotation.y = rotation_y
	remote_players[peer_id] = remote_player


@rpc("authority", "call_remote", "reliable")
func _remove_remote_player(peer_id: int) -> void:
	if not remote_players.has(peer_id):
		return
	
	var remote_player: Node = remote_players[peer_id]
	remote_players.erase(peer_id)
	if remote_player and is_instance_valid(remote_player):
		remote_player.queue_free()


@rpc("any_peer", "call_remote", "unreliable")
func _sync_player_transform(peer_id: int, synced_position: Vector3, synced_rotation_y: float) -> void:
	if network_manager and peer_id == network_manager.get_local_peer_id():
		return
	
	if not remote_players.has(peer_id):
		_spawn_remote_player(peer_id, synced_position, synced_rotation_y)
		return
	
	var remote_player: Node3D = remote_players[peer_id]
	if not remote_player or not is_instance_valid(remote_player):
		remote_players.erase(peer_id)
		return
	
	remote_player.global_position = remote_player.global_position.lerp(synced_position, 0.45)
	remote_player.global_rotation.y = synced_rotation_y


func _clear_remote_players() -> void:
	for remote_player in remote_players.values():
		if remote_player and is_instance_valid(remote_player):
			remote_player.queue_free()
	remote_players.clear()
