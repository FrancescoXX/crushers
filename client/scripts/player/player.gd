extends CharacterBody3D

## Crushers - WoW Classic style controller + Basic Combat
## Hold LMB = look around + turn character | Left Click = target | Tab = cycle targets | Charge (1)

@export_group("Movement")
@export var walk_speed: float = 7.0
@export var acceleration: float = 24.0
@export var deceleration: float = 28.0
@export var jump_velocity: float = 17.0  # A bit higher jump force
@export var turn_speed: float = 4.5
@export var autorun: bool = false

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var vertical_look_limit: float = 70.0
@export var camera_distance_min: float = 3.0
@export var camera_distance_max: float = 11.0
@export var camera_zoom_speed: float = 0.85

@export_group("Combat")
@export var base_damage: float = 20.0
@export var crit_chance: float = 0.25
@export var crit_multiplier: float = 2.0
@export var auto_attack_range: float = 4.5
@export var auto_attack_cooldown: float = 2.1
@export var ability_1_cooldown: float = 6.5
@export var heal_amount: float = 35.0
@export var heal_mana_cost: float = 25.0
@export var heal_cooldown: float = 4.0
@export var loot_interact_range: float = 5.5

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var right_arm: MeshInstance3D = $Visual/RightArm

@export var gravity: float = 75.0    # A bit less gravity
var right_mouse_held: bool = false

# Combat & Targeting
var current_target: Node3D = null
var auto_attack_timer: float = 0.0
var ability_1_timer: float = 0.0
var heal_timer: float = 0.0

var is_charging: bool = false
var charge_target: Node3D = null
@export var charge_max_range: float = 18.0
@export var charge_speed: float = 28.0

signal target_changed(new_target: Node3D)


# === Player Stats (WoW Classic style) ===
@export_group("Stats")
@export var max_health: float = 120.0
@export var max_resource: float = 100.0
@export var resource_name: String = "Mana"   # Can become "Rage", "Energy", "Focus" later

var current_health: float = max_health
var current_resource: float = max_resource

var mana_regen_lock_timer: float = 0.0          # 5-second rule like WoW Classic
const MANA_REGEN_LOCK_DURATION: float = 5.0

signal health_changed(current: float, maximum: float)
signal resource_changed(current: float, maximum: float, resource_name: String)

# === Experience System ===
@export_group("Experience")
@export var level: int = 1
@export var xp: int = 0
@export var xp_to_next_level: int = 1  # Kill 1 monster to reach level 2 (for quick testing)

signal level_up(new_level: int)
signal xp_changed(current: int, needed: int)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	spring_arm.spring_length = 6.8
	
	add_to_group("player")
	
	# Initialize health and resource (WoW style)
	current_health = max_health
	current_resource = max_resource
	health_changed.emit(current_health, max_health)
	resource_changed.emit(current_resource, max_resource, resource_name)
	
	# Gravity is now controlled by the exported variable above (easier to tweak)


func _input(event: InputEvent) -> void:
	# === Right Mouse Button (WoW Classic style) ===
	# Hold Right Mouse Button to look around and turn your character
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and _try_open_loot_under_mouse():
			return
		right_mouse_held = event.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if right_mouse_held else Input.MOUSE_MODE_VISIBLE

	# === Mouse Wheel Zoom (Very WoW) ===
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = max(camera_distance_min, spring_arm.spring_length - camera_zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = min(camera_distance_max, spring_arm.spring_length + camera_zoom_speed)

	# === Left Click Targeting (Classic WoW) ===
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_target_under_mouse()

	# === Tab Targeting (Classic WoW) ===
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		_cycle_target()

	# === Ability 1 (key 1) ===
	if event is InputEventKey and event.pressed and event.keycode == KEY_1:
		_use_ability_1()
	
	# === Heal (key 2) ===
	if event is InputEventKey and event.pressed and event.keycode == KEY_2:
		_use_heal()

	# === Autorun toggle (Num Lock like WoW) ===
	if event is InputEventKey and event.pressed and event.keycode == KEY_NUMLOCK:
		autorun = !autorun
		print("Autorun: ", "ON" if autorun else "OFF")


func _unhandled_input(event: InputEvent) -> void:
	# Only rotate camera + turn character when holding Right Mouse Button (WoW Classic)
	if event is InputEventMouseMotion and right_mouse_held:
		rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		
		spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -vertical_look_limit, vertical_look_limit)


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# === Charge Movement (Warrior Charge) ===
	if is_charging:
		if not charge_target or not is_instance_valid(charge_target):
			is_charging = false
			charge_target = null
			return
		
		var target_pos = charge_target.global_position
		var distance = global_position.distance_to(target_pos)
		
		# Stop cleanly when reaching the target
		if distance < 2.5:
			is_charging = false
			charge_target = null
			velocity = Vector3.ZERO
			play_simple_attack_animation()
			# Small damage on arrival
			if charge_target and charge_target.has_method("take_damage"):
				charge_target.take_damage(12)
			return
		
		# Move quickly toward the target
		var direction = (target_pos - global_position).normalized()
		velocity = direction * charge_speed
		move_and_slide()
		return  # Skip normal movement while charging

	# Movement
	var turn_input := Input.get_axis("move_left", "move_right")
	if turn_input != 0.0:
		rotate_y(-turn_input * turn_speed * delta)
	
	var move_input := Input.get_axis("move_forward", "move_back")
	
	# Autorun (WoW style)
	if autorun and move_input >= 0:
		move_input = -1.0   # force forward
	
	var direction := (transform.basis * Vector3(0, 0, move_input)).normalized()
	
	# Apply velocity
	var target_velocity := direction * walk_speed if direction else Vector3.ZERO
	var current_horizontal := Vector2(velocity.x, velocity.z)
	var target_horizontal := Vector2(target_velocity.x, target_velocity.z)
	
	var accel_rate := acceleration if direction else deceleration
	var new_horizontal := current_horizontal.move_toward(target_horizontal, accel_rate * delta)
	
	velocity.x = new_horizontal.x
	velocity.z = new_horizontal.y
	
	move_and_slide()
	
	# === Combat Timers ===
	_process_combat(delta)


func _process_combat(delta: float) -> void:
	auto_attack_timer = max(auto_attack_timer - delta, 0)
	ability_1_timer = max(ability_1_timer - delta, 0)
	heal_timer = max(heal_timer - delta, 0)
	mana_regen_lock_timer = max(mana_regen_lock_timer - delta, 0)
	
	# Mana regeneration (WoW Classic style - 5 second rule)
	_process_mana_regen(delta)
	
	# Auto-attack when we have a valid target
	if current_target and is_instance_valid(current_target) and "current_health" in current_target and current_target.current_health <= 0:
		clear_target()
		return
	
	if current_target and is_instance_valid(current_target) and auto_attack_timer <= 0:
		var dist := global_position.distance_to(current_target.global_position)
		if dist <= auto_attack_range and current_target.has_method("take_damage"):
			_perform_auto_attack()


func _perform_auto_attack() -> void:
	if not current_target or not is_instance_valid(current_target):
		clear_target()
		return
	
	if "current_health" in current_target and current_target.current_health <= 0:
		clear_target()
		return
	
	if current_target.has_method("take_damage"):
		var damage := base_damage
		if randf() < crit_chance:
			damage *= crit_multiplier
			print("Critical hit for ", damage, " damage!")
		current_target.take_damage(damage)
		play_simple_attack_animation()
		auto_attack_timer = auto_attack_cooldown


func _use_ability_1() -> void:
	# Charge ability (Warrior style)
	if is_charging or ability_1_timer > 0:
		return
	
	if not current_target or not is_instance_valid(current_target):
		return
	
	var distance = global_position.distance_to(current_target.global_position)
	if distance > charge_max_range:
		return
	
	# Start charging
	charge_target = current_target
	is_charging = true
	ability_1_timer = ability_1_cooldown
	print("Charging...")

func get_ability_1_cooldown_percent() -> float:
	if ability_1_cooldown <= 0:
		return 0.0
	return clamp(ability_1_timer / ability_1_cooldown, 0.0, 1.0)

func is_charge_in_range() -> bool:
	if not current_target or not is_instance_valid(current_target):
		return false
	return global_position.distance_to(current_target.global_position) <= charge_max_range


func _use_heal() -> void:
	if heal_timer > 0 or current_health >= max_health:
		return
	
	if not use_resource(heal_mana_cost):
		return
	
	mana_regen_lock_timer = MANA_REGEN_LOCK_DURATION
	heal(heal_amount)
	heal_timer = heal_cooldown


func get_heal_cooldown_percent() -> float:
	if heal_cooldown <= 0:
		return 0.0
	return clamp(heal_timer / heal_cooldown, 0.0, 1.0)


func can_use_heal() -> bool:
	return heal_timer <= 0 and current_health < max_health and current_resource >= heal_mana_cost


# === Experience System ===
func gain_xp(amount: int) -> void:
	xp += amount
	xp_changed.emit(xp, xp_to_next_level)
	
	print("Gained %d XP! (%d/%d)" % [amount, xp, xp_to_next_level])
	
	if xp >= xp_to_next_level:
		level_up_player()

func level_up_player() -> void:
	level += 1
	xp -= xp_to_next_level
	
	# Set next level requirement (simple scaling)
	if level == 2:
		xp_to_next_level = 2
	else:
		xp_to_next_level = int(xp_to_next_level * 1.5)
	
	level_up.emit(level)
	xp_changed.emit(xp, xp_to_next_level)
	
	print("Level Up! You are now Level %d" % level)
	_play_level_up_effect()
	
	# Restore some health/mana on level up (nice QoL)
	current_health = max_health
	current_resource = max_resource
	health_changed.emit(current_health, max_health)
	resource_changed.emit(current_resource, max_resource, resource_name)


func _play_level_up_effect() -> void:
	var effect_root := Node3D.new()
	effect_root.name = "LevelUpEffect"
	effect_root.global_position = global_position
	get_tree().current_scene.add_child(effect_root)
	
	var flash := OmniLight3D.new()
	flash.name = "LevelUpFlash"
	flash.position = Vector3(0, 2.2, 0)
	flash.light_color = Color(1.0, 0.82, 0.28, 1.0)
	flash.light_energy = 4.5
	flash.omni_range = 7.0
	effect_root.add_child(flash)
	
	var label := Label3D.new()
	label.text = "LEVEL UP!"
	label.position = Vector3(0, 3.2, 0)
	label.font_size = 48
	label.modulate = Color(1.0, 0.86, 0.22, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	effect_root.add_child(label)
	
	for i in range(3):
		_create_level_up_ring(effect_root, i)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "light_energy", 0.0, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", 4.25, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.45).set_delay(0.7)
	tween.finished.connect(effect_root.queue_free)


func _create_level_up_ring(parent: Node3D, index: int) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "LevelUpRing%d" % index
	ring.rotation_degrees.x = 90.0
	ring.position.y = 0.18 + index * 0.75
	ring.scale = Vector3(0.2, 0.2, 0.2)
	
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.92
	mesh.outer_radius = 1.0
	ring.mesh = mesh
	
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.82, 0.18, 0.82)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.78, 0.2, 1.0)
	mat.emission_energy_multiplier = 2.8
	ring.material_override = mat
	parent.add_child(ring)
	
	var delay := index * 0.16
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(2.6, 2.6, 2.6), 0.82).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "position:y", ring.position.y + 1.2, 0.82).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color", Color(1.0, 0.82, 0.18, 0.0), 0.35).set_delay(delay + 0.42)


func _try_target_under_mouse() -> void:
	var camera := spring_arm.get_node("Camera3D") as Camera3D
	if not camera:
		return
	
	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 80.0
	
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, 2)   # layer 2 = enemies
	query.collide_with_areas = false
	
	var result := space_state.intersect_ray(query)
	
	if result and result.collider is CorruptedBug:
		set_target(result.collider as Node3D)
	else:
		clear_target()


func _try_open_loot_under_mouse() -> bool:
	var camera := spring_arm.get_node("Camera3D") as Camera3D
	if not camera:
		return false
	
	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 80.0
	
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to, 4)   # layer 3 = corpses
	query.collide_with_areas = false
	
	var result := space_state.intersect_ray(query)
	if not result:
		return false
	
	var corpse := result.collider as Node3D
	if not corpse or not corpse.is_in_group("corpse"):
		return false
	
	if global_position.distance_to(corpse.global_position) > loot_interact_range:
		return false
	
	var loot_window := get_tree().current_scene.get_node_or_null("CanvasLayer/LootWindow")
	if loot_window and loot_window.has_method("open"):
		loot_window.open(corpse, mouse_pos)
		return true
	
	return false


func _cycle_target() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	
	var current_index := -1
	if current_target:
		current_index = enemies.find(current_target)
	
	var next_index := (current_index + 1) % enemies.size()
	
	# Prefer enemies in front of the player
	for i in range(enemies.size()):
		var idx := (current_index + 1 + i) % enemies.size()
		var candidate := enemies[idx] as CorruptedBug
		if not candidate or not is_instance_valid(candidate) or candidate.current_health <= 0:
			continue
		
		var to_enemy := (candidate.global_position - global_position).normalized()
		var dot := to_enemy.dot(-global_transform.basis.z)
		if dot > 0.3:   # somewhat in front
			set_target(candidate)
			return
	
	# Fallback: just take the next one
	var fallback := enemies[next_index] as CorruptedBug
	if fallback and is_instance_valid(fallback) and fallback.current_health > 0:
		set_target(fallback)


func set_target(new_target: Node3D) -> void:
	if current_target == new_target:
		return
	
	# Untarget previous
	if current_target and current_target.has_method("set_targeted"):
		current_target.set_targeted(false)
	
	current_target = new_target
	
	# Target new one
	if current_target and current_target.has_method("set_targeted"):
		current_target.set_targeted(true)
	
	target_changed.emit(current_target)


func clear_target() -> void:
	if current_target and current_target.has_method("set_targeted"):
		current_target.set_targeted(false)
	
	current_target = null
	target_changed.emit(null)


func _on_enemy_died(enemy: Node) -> void:
	if current_target == enemy:
		clear_target()


func _process_mana_regen(delta: float) -> void:
	if current_resource >= max_resource:
		return
	
	var regen_rate := 2.0   # base regen per second
	
	# WoW Classic 5-second rule: much slower regen while locked
	if mana_regen_lock_timer > 0:
		regen_rate = 0.4
	
	current_resource = min(current_resource + regen_rate * delta, max_resource)
	resource_changed.emit(current_resource, max_resource, resource_name)


# === Health & Resource System (WoW Classic style) ===


func take_damage(amount: float) -> void:
	if current_health <= 0:
		return
	
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	
	# Show floating damage above player
	_spawn_floating_text(amount)
	
	if current_health <= 0:
		die()


func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


func use_resource(amount: float) -> bool:
	if current_resource < amount:
		return false
	
	current_resource -= amount
	resource_changed.emit(current_resource, max_resource, resource_name)
	return true


func restore_resource(amount: float) -> void:
	current_resource = min(current_resource + amount, max_resource)
	resource_changed.emit(current_resource, max_resource, resource_name)


func die() -> void:
	print("You died!")
	# For now just respawn with full health
	current_health = max_health
	current_resource = max_resource
	health_changed.emit(current_health, max_health)
	resource_changed.emit(current_resource, max_resource, resource_name)


func play_simple_attack_animation() -> void:
	"""Very basic arm swing so the player can see when the attack will land."""
	if not right_arm:
		return
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Swing forward
	tween.tween_property(right_arm, "rotation_degrees:x", -55.0, 0.12)
	# Swing back
	tween.tween_property(right_arm, "rotation_degrees:x", 25.0, 0.25)
	# Return to rest
	tween.tween_property(right_arm, "rotation_degrees:x", 0.0, 0.15)


func _spawn_floating_text(amount: float) -> void:
	var text_scene := preload("res://scenes/ui/FloatingCombatText.tscn")
	var text_instance := text_scene.instantiate() as Node3D
	text_instance.position = Vector3(global_position.x, global_position.y + 2.5, global_position.z)
	get_tree().current_scene.add_child(text_instance)
	
	if text_instance.has_method("setup"):
		text_instance.setup(amount, false)
