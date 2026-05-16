extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

var player: Node = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		if player.has_signal("xp_changed"):
			player.xp_changed.connect(_on_xp_changed)
		
		# Set initial values
		if "xp" in player and "xp_to_next_level" in player:
			_on_xp_changed(player.xp, player.xp_to_next_level)

func _on_xp_changed(current: int, needed: int) -> void:
	progress_bar.max_value = needed
	progress_bar.value = current
	label.text = "%d / %d XP" % [current, needed]