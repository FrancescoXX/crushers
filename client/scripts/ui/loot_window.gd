extends Control

var current_corpse = null

func _ready() -> void:
	visible = false
	
	var loot_btn = $Panel/LootButton if has_node("Panel/LootButton") else null
	var close_btn = $Panel/CloseButton if has_node("Panel/CloseButton") else null
	
	if loot_btn:
		loot_btn.pressed.connect(_on_loot_pressed)
	if close_btn:
		close_btn.pressed.connect(close)


func open(corpse = null, screen_position := Vector2.ZERO) -> void:
	current_corpse = corpse
	visible = true
	
	var name_label = $Panel/CorpseNameLabel
	if name_label:
		if corpse and "display_name" in corpse:
			name_label.text = corpse.display_name + " Corpse"
		else:
			name_label.text = "Corpse"
	
	var loot_items: Array = []
	if corpse and corpse.has_method("get_loot_items"):
		loot_items = corpse.get_loot_items()
	
	_set_loot_row("Gold", loot_items[0] if loot_items.size() > 0 else {})
	_set_loot_row("Item", loot_items[1] if loot_items.size() > 1 else {})
	
	if screen_position != Vector2.ZERO:
		var viewport_size := get_viewport_rect().size
		var window_size := size
		position = Vector2(
			clamp(screen_position.x, 8.0, viewport_size.x - window_size.x - 8.0),
			clamp(screen_position.y, 8.0, viewport_size.y - window_size.y - 8.0)
		)


func close() -> void:
	visible = false
	current_corpse = null


func _set_loot_row(row_name: String, item: Dictionary) -> void:
	var label_path := "Panel/%sLabel" % row_name
	var icon_path := "Panel/%sPanel/%sIcon" % [row_name, row_name]
	
	if not has_node(label_path):
		return
	
	var label := get_node(label_path) as Label
	var icon := get_node_or_null(icon_path) as ColorRect
	
	if item.is_empty():
		label.text = ""
		if icon:
			icon.color = Color(0.12, 0.1, 0.08, 1)
		return
	
	var item_name := str(item.get("name", "Unknown Item"))
	var quantity := int(item.get("quantity", 1))
	label.text = "%d Gold" % quantity if item_name == "Gold" else item_name
	
	if icon:
		icon.color = Color(0.95, 0.72, 0.22, 1) if item_name == "Gold" else Color(0.42, 0.34, 0.2, 1)


func _on_loot_pressed() -> void:
	if current_corpse:
		var inventory := get_tree().current_scene.get_node_or_null("CanvasLayer/InventoryPanel")
		if inventory and inventory.has_method("add_items") and current_corpse.has_method("get_loot_items"):
			if inventory.add_items(current_corpse.get_loot_items()):
				if current_corpse.has_method("clear_loot_items"):
					current_corpse.clear_loot_items()
				if current_corpse.has_method("fade_away_after_loot"):
					current_corpse.fade_away_after_loot()
				print("Looting: ", current_corpse.name)
	close()


func _input(event) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
