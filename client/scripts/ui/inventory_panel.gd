extends Control

const SLOT_COUNT := 20

var items: Array[Dictionary] = []
@onready var grid: GridContainer = $Panel/GridContainer
@onready var gold_label: Label = $Panel/GoldLabel


func _ready() -> void:
	visible = false
	if has_node("Panel/CloseButton"):
		$Panel/CloseButton.pressed.connect(func(): visible = false)
	_ensure_slots()
	_refresh()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		visible = !visible


func add_items(new_items: Array) -> bool:
	var accepted_items: Array[Dictionary] = []
	for item in new_items:
		if item is Dictionary:
			accepted_items.append(item)
	
	if not _can_fit_items(accepted_items):
		return false
	
	for item in accepted_items:
		add_item(item)
	return true


func add_item(item: Dictionary) -> bool:
	var item_name := str(item.get("name", "Unknown Item"))
	var quantity := int(item.get("quantity", 1))
	var quality := str(item.get("quality", "common"))
	
	for existing in items:
		if existing.get("name", "") == item_name:
			existing["quantity"] = int(existing.get("quantity", 1)) + quantity
			_refresh()
			return true
	
	if items.size() >= SLOT_COUNT:
		return false
	
	items.append({
		"name": item_name,
		"quantity": quantity,
		"quality": quality,
	})
	_refresh()
	return true


func _ensure_slots() -> void:
	while grid.get_child_count() < SLOT_COUNT:
		var slot := Panel.new()
		slot.name = "Slot%d" % (grid.get_child_count() + 1)
		slot.custom_minimum_size = Vector2(54, 54)
		grid.add_child(slot)


func _can_fit_items(new_items: Array[Dictionary]) -> bool:
	var simulated_names: Array[String] = []
	for item in items:
		simulated_names.append(str(item.get("name", "")))
	
	var used_slots := items.size()
	for item in new_items:
		var item_name := str(item.get("name", ""))
		if simulated_names.has(item_name):
			continue
		used_slots += 1
		simulated_names.append(item_name)
	
	return used_slots <= SLOT_COUNT


func _refresh() -> void:
	var total_gold := 0
	for item in items:
		if item.get("name", "") == "Gold":
			total_gold += int(item.get("quantity", 0))
	
	if gold_label:
		gold_label.text = "%d g" % total_gold
	
	for i in range(grid.get_child_count()):
		var slot := grid.get_child(i) as Panel
		if not slot:
			continue
		
		_clear_slot(slot)
		if i < items.size():
			_render_slot(slot, items[i])


func _clear_slot(slot: Panel) -> void:
	for child in slot.get_children():
		slot.remove_child(child)
		child.queue_free()


func _render_slot(slot: Panel, item: Dictionary) -> void:
	var item_name := str(item.get("name", "Item"))
	var quantity := int(item.get("quantity", 1))
	
	var icon := ColorRect.new()
	icon.name = "Icon"
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 5
	icon.offset_top = 5
	icon.offset_right = -5
	icon.offset_bottom = -5
	icon.color = Color(0.95, 0.72, 0.22, 1) if item_name == "Gold" else Color(0.22, 0.28, 0.36, 1)
	slot.add_child(icon)
	
	var count_label := Label.new()
	count_label.name = "Count"
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.offset_left = -42
	count_label.offset_top = -22
	count_label.offset_right = -4
	count_label.offset_bottom = -2
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72, 1))
	count_label.text = str(quantity) if quantity > 1 or item_name == "Gold" else ""
	slot.add_child(count_label)
	
	var tooltip := "%s x%d" % [item_name, quantity]
	slot.tooltip_text = tooltip
