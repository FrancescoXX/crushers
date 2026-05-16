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
var is_dead: bool = false
var attack_timer: float = 0.0
var loot_items: Array[Dictionary] = []

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var head: MeshInstance3D = $Head
@onready var core: MeshInstance3D = $Core
@onready var light: OmniLight3D = $OmniLight3D

var target_circle: MeshInstance3D

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
	_create_target_circle()


func _process(delta: float) -> void:
	if is_dead or not is_aggroed:
		return
	
	attack_timer -= delta
	
	if attack_timer <= 0:
		_try_attack_player()
		attack_timer = attack_cooldown


func take_damage(amount: float) -> void:
	if is_dead or current_health <= 0:
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
	if is_dead or is_aggroed:
		return
	
	is_aggroed = true
	_set_aggressive_visuals()
	
	# Change target circle to red when aggressive (WoW Classic style)
	if target_circle and target_circle.material_override:
		var mat = target_circle.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(1.0, 0.3, 0.2, 0.8)
			mat.emission = Color(1.0, 0.3, 0.2, 0.7)
	
	print(display_name, " has become aggressive!")


func _make_materials_unique() -> void:
	# Make sure each enemy has its own material copy so only the attacked one changes color
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override = mesh_instance.material_override.duplicate()
	if head and head.material_override:
		head.material_override = head.material_override.duplicate()
	if core and core.material_override:
		core.material_override = core.material_override.duplicate()

func _create_target_circle() -> void:
	target_circle = MeshInstance3D.new()
	target_circle.name = "TargetCircle"
	add_child(target_circle)
	
	var ring := TorusMesh.new()
	ring.inner_radius = 1.05
	ring.outer_radius = 1.14
	ring.rings = 8
	ring.ring_segments = 96
	target_circle.mesh = ring
	
	# Rotate so the ring lies flat on the ground.
	target_circle.rotation_degrees.x = 90
	target_circle.position.y = 0.08
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.82, 0.22, 0.86)  # Yellow (neutral)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.76, 0.18, 1.0)
	mat.emission_energy_multiplier = 1.8
	
	target_circle.material_override = mat
	target_circle.visible = false  # Hidden by default


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
	if is_dead:
		return
	
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
	if is_dead:
		is_targeted = false
		target_state_changed.emit(false)
		if target_circle:
			target_circle.visible = false
		return
	
	is_targeted = targeted
	target_state_changed.emit(targeted)
	
	if target_circle:
		target_circle.visible = targeted
	
	if light:
		light.light_energy = 2.0 if targeted else (1.6 if is_aggroed else 1.1)


func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	is_aggroed = false
	is_targeted = false
	died.emit()
	
	# Give XP to the player when the monster dies
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("gain_xp"):
		player.gain_xp(1)
	
	remove_from_group("enemies")
	add_to_group("corpse")
	collision_layer = 4
	collision_mask = 0
	
	_generate_loot()
	_turn_into_corpse()


func _generate_loot() -> void:
	loot_items = [
		{
			"name": "Gold",
			"quantity": randi_range(1, 100),
			"quality": "money",
		},
		{
			"name": "Cracked Data Fragment",
			"quantity": 1,
			"quality": "common",
		},
	]


func get_loot_items() -> Array[Dictionary]:
	return loot_items


func clear_loot_items() -> void:
	loot_items.clear()


func fade_away_after_loot() -> void:
	collision_layer = 0
	collision_mask = 0
	
	var tween := create_tween()
	tween.set_parallel(true)
	for child in get_children():
		if child is MeshInstance3D:
			var mat := child.material_override as StandardMaterial3D
			if mat:
				mat = mat.duplicate()
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				child.material_override = mat
				tween.tween_property(mat, "albedo_color", Color(mat.albedo_color.r, mat.albedo_color.g, mat.albedo_color.b, 0.0), 1.4)
			tween.tween_property(child, "position:y", child.position.y - 0.25, 1.4)
	
	tween.finished.connect(queue_free)


func _turn_into_corpse() -> void:
	var corpse_mat := StandardMaterial3D.new()
	corpse_mat.albedo_color = Color(0.32, 0.32, 0.34, 1.0)
	corpse_mat.emission_enabled = false
	
	for child in get_children():
		if child is MeshInstance3D:
			child.material_override = corpse_mat
	
	if target_circle:
		target_circle.visible = false
	
	if has_node("Label3D"):
		$Label3D.visible = false
	
	if light:
		light.visible = false


func _spawn_floating_text(amount: float) -> void:
	var text_scene := preload("res://scenes/ui/FloatingCombatText.tscn")
	var text_instance := text_scene.instantiate() as Node3D
	text_instance.position = Vector3(global_position.x, global_position.y + 2.4, global_position.z)
	get_tree().current_scene.add_child(text_instance)
	
	if text_instance.has_method("setup"):
		text_instance.setup(amount, false)  # false = damage (red)


func get_display_name() -> String:
	return display_name
