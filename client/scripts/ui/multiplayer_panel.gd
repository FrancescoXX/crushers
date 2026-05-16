extends Control

const DEFAULT_ADDRESS: String = "127.0.0.1"

@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var address_edit: LineEdit = $Panel/MarginContainer/VBoxContainer/AddressRow/AddressEdit
@onready var port_spin: SpinBox = $Panel/MarginContainer/VBoxContainer/PortRow/PortSpinBox
@onready var host_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonRow/HostButton
@onready var join_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonRow/JoinButton
@onready var leave_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonRow/LeaveButton

var network_manager = null


func _ready() -> void:
	network_manager = get_node_or_null("/root/NetworkManager")
	
	address_edit.text = DEFAULT_ADDRESS
	port_spin.value = 7777
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	
	if network_manager:
		network_manager.hosting_started.connect(_on_hosting_started)
		network_manager.join_started.connect(_on_join_started)
		network_manager.connected_to_server.connect(_on_connected_to_server)
		network_manager.connection_failed.connect(_on_connection_failed)
		network_manager.server_disconnected.connect(_on_server_disconnected)
		network_manager.peer_joined.connect(_on_peer_joined)
		network_manager.peer_left.connect(_on_peer_left)
		network_manager.multiplayer_stopped.connect(_on_multiplayer_stopped)
	else:
		status_label.text = "Network manager missing"
	
	_update_buttons()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_L:
		visible = not visible


func _on_host_pressed() -> void:
	if not network_manager:
		return
	
	var error: int = network_manager.host_game(int(port_spin.value))
	if error != OK:
		status_label.text = "Host failed: %s" % error_string(error)
	
	_update_buttons()


func _on_join_pressed() -> void:
	if not network_manager:
		return
	
	var address: String = address_edit.text.strip_edges()
	if address.is_empty():
		address = DEFAULT_ADDRESS
	
	var error: int = network_manager.join_game(address, int(port_spin.value))
	if error != OK:
		status_label.text = "Join failed: %s" % error_string(error)
	
	_update_buttons()


func _on_leave_pressed() -> void:
	if network_manager:
		network_manager.stop_multiplayer()
	_update_buttons()


func _on_hosting_started(port: int) -> void:
	status_label.text = "Hosting on port %d" % port
	_update_buttons()


func _on_join_started(address: String, port: int) -> void:
	status_label.text = "Joining %s:%d..." % [address, port]
	_update_buttons()


func _on_connected_to_server() -> void:
	status_label.text = "Connected as peer %d" % multiplayer.get_unique_id()
	_update_buttons()


func _on_connection_failed() -> void:
	status_label.text = "Connection failed"
	_update_buttons()


func _on_server_disconnected() -> void:
	status_label.text = "Server disconnected"
	_update_buttons()


func _on_peer_joined(peer_id: int) -> void:
	if multiplayer.is_server():
		status_label.text = "Peer %d joined" % peer_id


func _on_peer_left(peer_id: int) -> void:
	if multiplayer.is_server():
		status_label.text = "Peer %d left" % peer_id


func _on_multiplayer_stopped() -> void:
	if not network_manager or not network_manager.has_active_peer():
		status_label.text = "Offline"
	_update_buttons()


func _update_buttons() -> void:
	var connected: bool = network_manager != null and network_manager.has_active_peer()
	host_button.disabled = connected
	join_button.disabled = connected
	leave_button.disabled = not connected
	
	if connected and status_label.text == "Offline":
		if multiplayer.is_server():
			status_label.text = "Hosting on port %d" % int(port_spin.value)
		else:
			status_label.text = "Connected as peer %d" % multiplayer.get_unique_id()
