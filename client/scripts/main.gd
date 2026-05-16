extends Node3D

@onready var player := $Player
@onready var target_frame := $CanvasLayer/TargetFrame


func _ready() -> void:
	if player and target_frame:
		player.target_changed.connect(target_frame.set_target)
