extends Control

@onready var slot1: Control = $HBoxContainer/Slot1
@onready var slot2: Control = $HBoxContainer/Slot2
@onready var slot3: Control = $HBoxContainer/Slot3

var player: Node = null


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	_style_slot(slot1, "1", 18)
	_style_slot(slot2, "2", 25)
	_style_slot(slot3, "3", 0)


func _style_slot(slot: Control, key: String, mana_cost: int) -> void:
	var key_label = slot.get_node("KeyLabel") as Label
	if key_label:
		key_label.text = key
	
	var cost_label = slot.get_node_or_null("CostLabel") as Label
	if cost_label:
		cost_label.text = str(mana_cost) if mana_cost > 0 else ""
	
	slot.set_meta("mana_cost", mana_cost)


func _process(_delta: float) -> void:
	if not player:
		return
	
	if player.has_method("get_ability_1_cooldown_percent"):
		_update_cooldown_visual(slot1, player.get_ability_1_cooldown_percent())
	if player.has_method("get_heal_cooldown_percent"):
		_update_cooldown_visual(slot2, player.get_heal_cooldown_percent())
	
	_update_mana_color(slot1)
	_update_mana_color(slot2)
	_update_charge_slot_visual(slot1)
	_update_heal_slot_visual(slot2)


func _update_cooldown_visual(slot: Control, percent: float) -> void:
	var overlay = slot.get_node("CooldownOverlay") as ColorRect
	if not overlay:
		return
	
	overlay.visible = percent > 0.01
	overlay.size.y = slot.size.y * percent


func _update_mana_color(slot: Control) -> void:
	var cost_label = slot.get_node_or_null("CostLabel") as Label
	var mana_cost = slot.get_meta("mana_cost", 0)
	
	if mana_cost <= 0 or not player or not "current_resource" in player:
		return
	
	if cost_label:
		cost_label.modulate = Color(0.85, 0.3, 0.3) if player.current_resource < mana_cost else Color(0.4, 0.75, 1.0)


func _update_charge_slot_visual(slot: Control) -> void:
	var charge_icon = slot.get_node_or_null("ChargeIcon") as Label
	var cost_label = slot.get_node_or_null("CostLabel") as Label
	var icon_tint = slot.get_node_or_null("IconTint") as ColorRect
	
	if not charge_icon:
		return
	
	if player.has_method("get_ability_1_cooldown_percent") and player.get_ability_1_cooldown_percent() > 0.05:
		charge_icon.modulate = Color(0.6, 0.6, 0.6)
		if icon_tint:
			icon_tint.color = Color(0.18, 0.16, 0.14, 1)
		if cost_label:
			cost_label.modulate = Color(0.6, 0.6, 0.6)
		return
	
	if player.has_method("is_charge_in_range") and player.is_charge_in_range():
		charge_icon.modulate = Color(1, 1, 1)
		if icon_tint:
			icon_tint.color = Color(0.58, 0.16, 0.08, 1)
		if cost_label:
			cost_label.modulate = Color(0.5, 0.85, 1.0)
	else:
		charge_icon.modulate = Color(1.0, 0.35, 0.25)
		if icon_tint:
			icon_tint.color = Color(0.24, 0.07, 0.05, 1)
		if cost_label:
			cost_label.modulate = Color(1.0, 0.35, 0.25)


func _update_heal_slot_visual(slot: Control) -> void:
	var heal_icon = slot.get_node_or_null("HealIcon") as Label
	var cost_label = slot.get_node_or_null("CostLabel") as Label
	var icon_tint = slot.get_node_or_null("IconTint") as ColorRect
	
	if not heal_icon:
		return
	
	if player.has_method("get_heal_cooldown_percent") and player.get_heal_cooldown_percent() > 0.05:
		heal_icon.modulate = Color(0.6, 0.6, 0.6)
		if icon_tint:
			icon_tint.color = Color(0.14, 0.16, 0.14, 1)
		if cost_label:
			cost_label.modulate = Color(0.6, 0.6, 0.6)
		return
	
	if player.has_method("can_use_heal") and player.can_use_heal():
		heal_icon.modulate = Color(1, 1, 1)
		if icon_tint:
			icon_tint.color = Color(0.07, 0.36, 0.16, 1)
		if cost_label:
			cost_label.modulate = Color(0.5, 0.85, 1.0)
	else:
		heal_icon.modulate = Color(1.0, 0.35, 0.25)
		if icon_tint:
			icon_tint.color = Color(0.09, 0.16, 0.09, 1)
		if cost_label:
			cost_label.modulate = Color(1.0, 0.35, 0.25)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ability_1"):
		if player and player.has_method("_use_ability_1"):
			player._use_ability_1()
	
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_2:
		if player and player.has_method("_use_heal"):
			player._use_heal()
