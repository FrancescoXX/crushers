extends Control

@onready var level_label: Label = $LevelLabel

var player: Node = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		# Connect to level up signal
		if player.has_signal("level_up"):
			player.level_up.connect(_on_level_up)
		
		# Set initial level
		if "level" in player:
			level_label.text = str(player.level)

func _on_level_up(new_level: int) -> void:
	level_label.text = str(new_level)
