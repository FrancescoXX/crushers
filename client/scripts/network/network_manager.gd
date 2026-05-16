extends Node

signal hosting_started(port: int)
signal join_started(address: String, port: int)
signal connected_to_server
signal connection_failed
signal server_disconnected
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal multiplayer_stopped

const DEFAULT_PORT: int = 7777
const MAX_CLIENTS: int = 8

var peer: ENetMultiplayerPeer = null
var is_hosting: bool = false
var current_address: String = ""
var current_port: int = DEFAULT_PORT


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game(port: int = DEFAULT_PORT) -> int:
	_close_peer()
	
	peer = ENetMultiplayerPeer.new()
	var error: int = peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		peer = null
		return error
	
	multiplayer.multiplayer_peer = peer
	is_hosting = true
	current_address = "localhost"
	current_port = port
	hosting_started.emit(port)
	return OK


func join_game(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> int:
	_close_peer()
	
	peer = ENetMultiplayerPeer.new()
	var error: int = peer.create_client(address, port)
	if error != OK:
		peer = null
		return error
	
	multiplayer.multiplayer_peer = peer
	is_hosting = false
	current_address = address
	current_port = port
	join_started.emit(address, port)
	return OK


func stop_multiplayer() -> void:
	_close_peer()
	multiplayer_stopped.emit()


func _close_peer() -> void:
	if peer:
		peer.close()
	
	multiplayer.multiplayer_peer = null
	peer = null
	is_hosting = false
	current_address = ""
	current_port = DEFAULT_PORT


func has_active_peer() -> bool:
	return multiplayer.multiplayer_peer != null


func get_local_peer_id() -> int:
	if not multiplayer.multiplayer_peer:
		return 1
	return multiplayer.get_unique_id()


func _on_peer_connected(peer_id: int) -> void:
	peer_joined.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	peer_left.emit(peer_id)


func _on_connected_to_server() -> void:
	connected_to_server.emit()


func _on_connection_failed() -> void:
	connection_failed.emit()
	_close_peer()


func _on_server_disconnected() -> void:
	server_disconnected.emit()
	_close_peer()
