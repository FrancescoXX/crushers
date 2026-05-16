extends StaticBody3D
class_name CorruptedBug

## Simple static enemy for first combat iteration
## "Corrupted Memory Bug" - looks glitchy and dangerous

signal died
signal health_changed(current: float, maximum: float)
signal target_state_changed(is_targeted: bool)

@export var display_name: String = "Corrupted Bug"
@export var max_health: float = 40.0

var current_health: float = max_health
var is_targeted: bool = false

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")


func take_damage(amount: float) -> void:
	if current_health <= 0:
		return
	
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	
	# Visual feedback when hit (flash)
	_flash_hit()
	
	if current_health <= 0:
		die()


func _flash_hit() -> void:
	if mesh_instance and mesh_instance.material_override:
		var mat := mesh_instance.material_override as StandardMaterial3D
		if mat:
			mat.emission = Color(1.0, 1.0, 1.0)
			await get_tree().create_timer(0.08).timeout
			if is_instance_valid(self) and mat:
				mat.emission = Color(0.9, 0.15, 0.1)   # back to angry red


func set_targeted(targeted: bool) -> void:
	is_targeted = targeted
	target_state_changed.emit(targeted)
	
	# Simple visual: make the light brighter when targeted
	if light:
		light.light_energy = 1.8 if targeted else 1.0


func die() -> void:
	died.emit()
	
	# Simple death effect - could be improved later
	if mesh_instance:
		mesh_instance.visible = false
	if light:
		light.visible = false
	
	await get_tree().create_timer(0.15).timeout
	queue_free()


func get_display_name() -> String:
	return display_name
