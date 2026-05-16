extends Control

@onready var name_label: Label = $NameLabel
@onready var health_bar: ProgressBar = $HealthBar

var current_target: Node3D = null


func _ready() -> void:
	visible = false


func set_target(target: Node3D) -> void:
	if current_target and current_target.has_signal("health_changed"):
		current_target.health_changed.disconnect(_on_health_changed)
	if current_target and current_target.has_signal("died"):
		current_target.died.disconnect(_on_target_died)
	
	current_target = target
	
	if not current_target:
		visible = false
		return
	
	visible = true
	var bug2 := current_target as CorruptedBug
	name_label.text = bug2.get_display_name() if bug2 else "Enemy"
	
	if current_target.has_signal("health_changed"):
		current_target.health_changed.connect(_on_health_changed)
	if current_target.has_signal("died"):
		current_target.died.connect(_on_target_died)
	
	_update_health()


func _on_health_changed(current: float, maximum: float) -> void:
	_update_health(current, maximum)


func _on_target_died() -> void:
	visible = false


func _update_health(current: float = -1, maximum: float = -1) -> void:
	if not current_target:
		return
	
	var bug := current_target as CorruptedBug
	if not bug:
		return
	
	var cur := current if current >= 0 else bug.current_health
	var maxv := maximum if maximum >= 0 else bug.max_health
	
	health_bar.max_value = maxv
	health_bar.value = cur
