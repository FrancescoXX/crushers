extends StaticBody3D
class_name CorruptedBug

## Neutral monster behavior (WoW Classic style)
## - Starts neutral (yellow/orange vibe)
## - Does not attack first
## - When attacked by player → becomes aggressive (turns red) and fights back
## - Stays in place while fighting

signal died
signal health_changed(current: float, maximum: float)
signal target_state_changed(is_targeted: bool)

@export var display_name: String = "Corrupted Bug"
@export var max_health: float = 40.0

@export_group("Aggro Behavior")
@export var aggro_range: float = 6.5
@export var attack_damage: float = 7.0
@export var attack_cooldown: float = 2.6

var current_health: float = max_health
var is_targeted: bool = false
var is_aggroed: bool = false
var attack_timer: float = 0.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var head: MeshInstance3D = $Head
@onready var core: MeshInstance3D = $Core
@onready var light: OmniLight3D = $OmniLight3D

# Store base colors
var neutral_body_emission := Color(0.95, 0.55, 0.1, 1)      # Orange/Yellow
var neutral_head_emission := Color(0.9, 0.85, 0.3, 1)       # Yellowish
var aggressive_body_emission := Color(0.9, 0.15, 0.1, 1)    # Red
var aggressive_head_emission := Color(0.3, 0.65, 0.95, 1)   # Cyan (keep glitch feel)


func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	_make_materials_unique()
	_set_neutral_visuals()


func _process(delta: float) -> void:
	if not is_aggroed:
		return
	
	attack_timer -= delta
	
	if attack_timer <= 0:
		_try_attack_player()
		attack_timer = attack_cooldown


func take_damage(amount: float) -> void:
	if current_health <= 0:
		return
	
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	
	# Show floating damage number
	_spawn_floating_text(amount)
	
	# First time being hit → become aggressive (WoW neutral monster behavior)
	if not is_aggroed:
		become_aggroed()
	
	_flash_hit()
	
	if current_health <= 0:
		die()


func become_aggroed() -> void:
	if is_aggroed:
		return
	
	is_aggroed = true
	_set_aggressive_visuals()
	print(display_name, " has become aggressive!")


func _make_materials_unique() -> void:
	# Make sure each enemy has its own material copy so only the attacked one changes color
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override = mesh_instance.material_override.duplicate()
	if head and head.material_override:
		head.material_override = head.material_override.duplicate()
	if core and core.material_override:
		core.material_override = core.material_override.duplicate()


func _set_neutral_visuals() -> void:
	if mesh_instance and mesh_instance.material_override:
		var mat := mesh_instance.material_override as StandardMaterial3D
		if mat:
			mat.emission = neutral_body_emission
	
	if head and head.material_override:
		var mat := head.material_override as StandardMaterial3D
		if mat:
			mat.emission = neutral_head_emission
	
	if core and core.material_override:
		var mat := core.material_override as StandardMaterial3D
		if mat:
			mat.emission = neutral_head_emission
	
	if light:
		light.light_color = Color(1.0, 0.7, 0.2, 1)  # Warm yellow/orange
		light.light_energy = 1.1


func _set_aggressive_visuals() -> void:
	if mesh_instance and mesh_instance.material_override:
		var mat := mesh_instance.material_override as StandardMaterial3D
		if mat:
			mat.emission = aggressive_body_emission
	
	if head and head.material_override:
		var mat := head.material_override as StandardMaterial3D
		if mat:
			mat.emission = aggressive_head_emission
	
	if core and core.material_override:
		var mat := core.material_override as StandardMaterial3D
		if mat:
			mat.emission = aggressive_head_emission
	
	if light:
		light.light_color = Color(0.95, 0.25, 0.15, 1)  # Red
		light.light_energy = 1.6


func _flash_hit() -> void:
	# Flash white on hit, then return to current state color
	if mesh_instance and mesh_instance.material_override:
		var mat := mesh_instance.material_override as StandardMaterial3D
		if mat:
			mat.emission = Color(1.0, 1.0, 1.0)
			await get_tree().create_timer(0.07).timeout
			if is_instance_valid(self) and mat:
				if is_aggroed:
					mat.emission = aggressive_body_emission
				else:
					mat.emission = neutral_body_emission


func _try_attack_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return
	
	var distance := global_position.distance_to(player.global_position)
	if distance > aggro_range:
		return
	
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
		# Small visual feedback on attack
		if light:
			light.light_energy = 2.4
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(self) and light and is_aggroed:
				light.light_energy = 1.6


func set_targeted(targeted: bool) -> void:
	is_targeted = targeted
	target_state_changed.emit(targeted)
	
	if light:
		light.light_energy = 2.0 if targeted else (1.6 if is_aggroed else 1.1)


func die() -> void:
	died.emit()
	
	if mesh_instance:
		mesh_instance.visible = false
	if head:
		head.visible = false
	if core:
		core.visible = false
	if light:
		light.visible = false
	
	await get_tree().create_timer(0.12).timeout
	queue_free()


func _spawn_floating_text(amount: float) -> void:
	var text_scene := preload("res://scenes/ui/FloatingCombatText.tscn")
	var text_instance := text_scene.instantiate() as Node3D
	text_instance.position = Vector3(global_position.x, global_position.y + 2.1, global_position.z)
	get_tree().current_scene.add_child(text_instance)
	
	if text_instance.has_method("setup"):
		text_instance.setup(amount, false)  # false = damage (red)


func get_display_name() -> String:
	return display_name
