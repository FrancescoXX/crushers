extends CharacterBody3D

## Crushers - WoW Classic style controller + Basic Combat
## Hold RMB = steer with mouse | Left Click = target | Tab = cycle targets | Auto-attack + Ability 1

@export_group("Movement")
@export var walk_speed: float = 7.0
@export var acceleration: float = 24.0
@export var deceleration: float = 28.0
@export var jump_velocity: float = 17.0  # A bit higher jump force
@export var turn_speed: float = 14.0
# turn_speed_free_mouse was removed - we no longer auto-rotate the body when mouse is free
# to prevent UI flickering. Character now strafes in free-mouse mode.
@export var autorun: bool = false

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var vertical_look_limit: float = 70.0
@export var camera_distance_min: float = 3.0
@export var camera_distance_max: float = 11.0
@export var camera_zoom_speed: float = 0.85

@export_group("Combat")
@export var auto_attack_range: float = 4.5
@export var auto_attack_cooldown: float = 2.1
@export var ability_1_damage: float = 18.0
@export var ability_1_cooldown: float = 6.5

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var right_arm: MeshInstance3D = $Visual/RightArm

@export var gravity: float = 75.0    # A bit less gravity
var right_mouse_held: bool = false

# Combat & Targeting
var current_target: Node3D = null
var auto_attack_timer: float = 0.0
var ability_1_timer: float = 0.0

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
	# === Right Mouse Button (WoW steering) ===
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
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

	# === Autorun toggle (Num Lock like WoW) ===
	if event is InputEventKey and event.pressed and event.keycode == KEY_NUMLOCK:
		autorun = !autorun
		print("Autorun: ", "ON" if autorun else "OFF")


func _unhandled_input(event: InputEvent) -> void:
	# Only rotate camera when holding Right Mouse Button (WoW Classic style)
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
	
	# Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Autorun (WoW style)
	if autorun and input_dir.y >= 0:
		input_dir.y = -1   # force forward
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# No auto body turning when mouse is free (RMB not held).
	# This prevents constant camera rotation that was causing UI flickering.
	# Character will now strafe when using WASD without holding RMB.
	#
	# When holding RMB, the body is rotated directly via mouse input in _unhandled_input.
	
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
	mana_regen_lock_timer = max(mana_regen_lock_timer - delta, 0)
	
	# Mana regeneration (WoW Classic style - 5 second rule)
	_process_mana_regen(delta)
	
	# Auto-attack when we have a valid target
	if current_target and is_instance_valid(current_target) and auto_attack_timer <= 0:
		var dist := global_position.distance_to(current_target.global_position)
		if dist <= auto_attack_range and current_target.has_method("take_damage"):
			_perform_auto_attack()


func _perform_auto_attack() -> void:
	if not current_target or not is_instance_valid(current_target):
		clear_target()
		return
	
	var bug := current_target as CorruptedBug
	if bug:
		var damage := 8.0 + randf_range(-1.5, 1.5)
		bug.take_damage(damage)
		play_simple_attack_animation()
		auto_attack_timer = auto_attack_cooldown


func _use_ability_1() -> void:
	if ability_1_timer > 0 or not current_target or not is_instance_valid(current_target):
		return
	
	var dist := global_position.distance_to(current_target.global_position)
	if dist > auto_attack_range * 1.3:
		return
	
	var bug := current_target as CorruptedBug
	if bug:
		bug.take_damage(ability_1_damage)
		play_simple_attack_animation()
		ability_1_timer = ability_1_cooldown
		print("Used Ability 1 for ", ability_1_damage, " damage!")

func get_ability_1_cooldown_percent() -> float:
	if ability_1_cooldown <= 0:
		return 0.0
	return clamp(ability_1_timer / ability_1_cooldown, 0.0, 1.0)


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
	
	# Restore some health/mana on level up (nice QoL)
	current_health = max_health
	current_resource = max_resource
	health_changed.emit(current_health, max_health)
	resource_changed.emit(current_resource, max_resource, resource_name)


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
	text_instance.position = Vector3(global_position.x, global_position.y + 2.3, global_position.z)
	get_tree().current_scene.add_child(text_instance)
	
	if text_instance.has_method("setup"):
		text_instance.setup(amount, false)
