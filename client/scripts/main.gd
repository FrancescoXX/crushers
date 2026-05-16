extends Node3D

@onready var player := $Player
@onready var target_frame := $CanvasLayer/TargetFrame

var network_manager = null


func _ready() -> void:
	network_manager = get_node_or_null("/root/NetworkManager")
	if network_manager:
		network_manager.hosting_started.connect(_on_network_identity_changed)
		network_manager.connected_to_server.connect(_on_network_identity_changed)
		network_manager.multiplayer_stopped.connect(_on_network_identity_changed)
	
	_register_local_player()
	
	if player and target_frame:
		player.target_changed.connect(target_frame.set_target)


func _register_local_player() -> void:
	if not player:
		return
	
	var local_peer_id: int = 1
	if network_manager and network_manager.has_method("get_local_peer_id"):
		local_peer_id = network_manager.get_local_peer_id()
	
	player.set_multiplayer_authority(local_peer_id)
	player.name = "Player_%d" % local_peer_id


func _on_network_identity_changed(_unused = null) -> void:
	_register_local_player()
