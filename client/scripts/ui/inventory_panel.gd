extends Control

func _ready() -> void:
	visible = false  # Start hidden

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		visible = !visible
		# Optional: pause the game when inventory is open
		# get_tree().paused = visible