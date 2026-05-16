extends Node3D

@onready var label: Label3D = $Label3D

func setup(value: float, is_heal: bool = false) -> void:
	var text = str(int(value))
	label.text = ("+" if is_heal else "") + text
	
	if is_heal:
		label.modulate = Color(0.3, 1.0, 0.4)
	else:
		label.modulate = Color(1.0, 0.3, 0.2)
	
	# Simple animation: rise + fade
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Move upward
	tween.tween_property(self, "position:y", position.y + 1.8, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.35)
	
	tween.finished.connect(queue_free)