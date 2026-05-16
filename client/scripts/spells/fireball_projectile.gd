extends Area3D

@export var speed: float = 18.0
@export var damage: float = 22.0

var target: Node3D = null
var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	$Timer.timeout.connect(queue_free)
	
	if target:
		direction = (target.global_position - global_position).normalized()
	else:
		direction = -global_transform.basis.z


func set_target(new_target: Node3D) -> void:
	target = new_target
	if target:
		direction = (target.global_position - global_position).normalized()
		look_at(target.global_position, Vector3.UP)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage") and body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()