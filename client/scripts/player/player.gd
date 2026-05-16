extends CharacterBody3D

## Crushers - WoW Classic style controller + Basic Combat
## Hold RMB = steer with mouse | Left Click = target | Tab = cycle targets | Auto-attack + Ability 1

@export_group("Movement")
@export var walk_speed: float = 7.0
@export var acceleration: float = 24.0
@export var deceleration: float = 28.0
@export var jump_velocity: float = 9.0
@export var turn_speed: float = 14.0
@export var autorun: bool = false

@export_group("Camera")
@export var mouse_sensitivity: float = 0.003
@export var vertical_look_limit: float = 70.0
@export var camera_distance_min: float = 2.5
@export var camera_distance_max: float = 9.0
@export var camera_zoom_speed: float = 0.8

@export_group("Combat")
@export var auto_attack_range: float = 4.5
@export var auto_attack_cooldown: float = 2.1
@export var ability_1_damage: float = 18.0
@export var ability_1_cooldown: float = 6.5

@onready var spring_arm: SpringArm3D = $SpringArm3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var right_mouse_held: bool = false

# Combat & Targeting
var current_target: Node3D = null
var auto_attack_timer: float = 0.0
var ability_1_timer: float = 0.0

signal target_changed(new_target: Node3D)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	spring_arm.spring_length = 5.2


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
	if event is InputEventMouseMotion:
		if right_mouse_held:
			rotate_y(-event.relative.x * mouse_sensitivity)
			spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		else:
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
	
	# Turning behavior
	if not right_mouse_held and direction.length() > 0.1:
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)
	
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
		auto_attack_timer = auto_attack_cooldown
	
	# TODO: Add swing animation / sound later


func _use_ability_1() -> void:
	if ability_1_timer > 0 or not current_target or not is_instance_valid(current_target):
		return
	
	var dist := global_position.distance_to(current_target.global_position)
	if dist > auto_attack_range * 1.3:
		return   # too far
	
	var bug := current_target as CorruptedBug
	if bug:
		bug.take_damage(ability_1_damage)
		ability_1_timer = ability_1_cooldown
		print("Used Ability 1 for ", ability_1_damage, " damage!")


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
