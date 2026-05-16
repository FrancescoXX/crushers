extends Control

@onready var name_label: Label = $Bars/NameLabel
@onready var health_bar: ProgressBar = $Bars/HealthBar
@onready var health_value: Label = $Bars/HealthBar/HealthValue
@onready var resource_bar: ProgressBar = $Bars/ResourceBar
@onready var resource_value: Label = $Bars/ResourceBar/ResourceValue

var player: Node3D = null


func _ready() -> void:
	# Try to find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		# Connect signals
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
		if player.has_signal("resource_changed"):
			player.resource_changed.connect(_on_resource_changed)
		
		# Initialize with current values
		if "current_health" in player and "max_health" in player:
			_on_health_changed(player.current_health, player.max_health)
		if "current_resource" in player and "max_resource" in player and "resource_name" in player:
			_on_resource_changed(player.current_resource, player.max_resource, player.resource_name)
	else:
		print("Warning: PlayerFrame could not find player node")


func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_value.text = "%d / %d" % [current, maximum]


func _on_resource_changed(current: float, maximum: float, res_name: String) -> void:
	resource_bar.max_value = maximum
	resource_bar.value = current
	resource_value.text = "%d / %d" % [current, maximum]
	
	# Update resource bar color based on type (WoW style)
	if res_name == "Mana":
		resource_bar.modulate = Color(0.3, 0.5, 1.0)      # Blue
	elif res_name == "Rage":
		resource_bar.modulate = Color(1.0, 0.3, 0.2)      # Red
	elif res_name == "Energy":
		resource_bar.modulate = Color(1.0, 0.9, 0.2)      # Yellow
	else:
		resource_bar.modulate = Color(0.4, 0.8, 0.4)      # Green default
