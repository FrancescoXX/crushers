extends Control

@onready var slot1: Control = $HBoxContainer/Slot1
@onready var slot2: Control = $HBoxContainer/Slot2
@onready var slot3: Control = $HBoxContainer/Slot3

var player: Node = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	_style_slot(slot1, "1", 18)
	_style_slot(slot2, "2", 0)
	_style_slot(slot3, "3", 0)

func _style_slot(slot: Control, key: String, mana_cost: int) -> void:
	var key_label = slot.get_node("KeyLabel") as Label
	if key_label:
		key_label.text = key
	
	var cost_label = slot.get_node_or_null("CostLabel") as Label
	if cost_label:
		cost_label.text = str(mana_cost) if mana_cost > 0 else ""
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.1, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.27, 0.35, 1)
	slot.add_theme_stylebox_override("panel", style)
	
	slot.set_meta("mana_cost", mana_cost)

func _process(_delta: float) -> void:
	if not player:
		return
	
	# Update cooldown on slot 1
	if player.has_method("get_ability_1_cooldown_percent"):
		var percent = player.get_ability_1_cooldown_percent()
		_update_cooldown_visual(slot1, percent)
	
	# Update mana cost color
	_update_mana_color(slot1)

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
		if player.current_resource < mana_cost:
			cost_label.modulate = Color(0.85, 0.3, 0.3)
		else:
			cost_label.modulate = Color(0.4, 0.75, 1.0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ability_1"):
		if player and player.has_method("_use_ability_1"):
			player._use_ability_1()