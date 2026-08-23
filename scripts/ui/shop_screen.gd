class_name ShopScreen
extends Control

## Placeholder shop: spend coins (scripts/progression/player_profile.gd) on a
## few flat-colour marble skins. Deliberately undesigned — the home screen's
## own look is still being worked out, so this reuses plain engine controls
## rather than home_screen.gd's custom-drawn comic-book style. Swap the visuals
## once that direction is settled.

const HOME_SCENE := "res://scenes/home.tscn"

var _coins_label: Label
var _rows: Dictionary = {} ## skin id -> row Control, so a purchase can refresh just that row.


func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0

	var background := ColorRect.new()
	background.color = Color(0.10, 0.10, 0.12)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var layout := VBoxContainer.new()
	layout.anchor_right = 1.0
	layout.anchor_bottom = 1.0
	layout.offset_left = 24.0
	layout.offset_right = -24.0
	layout.offset_top = 24.0
	layout.offset_bottom = -24.0
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)

	layout.add_child(_build_header())

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	layout.add_child(list)
	for skin in PlayerProfile.SKINS:
		var row := _build_skin_row(skin)
		_rows[skin["id"]] = row
		list.add_child(row)

	PlayerProfile.coins_changed.connect(_on_coins_changed)


func _build_header() -> Control:
	var row := HBoxContainer.new()

	var back := Button.new()
	back.text = "< HOME"
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(HOME_SCENE))
	row.add_child(back)

	var title := Label.new()
	title.text = "SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	row.add_child(title)

	_coins_label = Label.new()
	_coins_label.text = "%d coins" % PlayerProfile.coins
	row.add_child(_coins_label)

	return row


func _build_skin_row(skin: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var swatch := ColorRect.new()
	swatch.color = skin["colour"]
	swatch.custom_minimum_size = Vector2(40, 40)
	row.add_child(swatch)

	var name_label := Label.new()
	name_label.text = skin["name"]
	name_label.custom_minimum_size = Vector2(140, 0)
	row.add_child(name_label)

	var action := Button.new()
	action.custom_minimum_size = Vector2(120, 0)
	action.name = "Action"
	action.pressed.connect(func() -> void: _on_action_pressed(skin["id"]))
	row.add_child(action)

	_refresh_row(row, skin["id"])
	return row


func _on_action_pressed(id: int) -> void:
	if PlayerProfile.owns_skin(id):
		PlayerProfile.equip_skin(id)
	else:
		PlayerProfile.buy_skin(id)
	_refresh_all_rows()


func _on_coins_changed(balance: int) -> void:
	_coins_label.text = "%d coins" % balance


func _refresh_all_rows() -> void:
	for id in _rows:
		_refresh_row(_rows[id], id)


func _refresh_row(row: Control, id: int) -> void:
	var action := row.get_node("Action") as Button
	var skin := PlayerProfile.skin_by_id(id)

	if PlayerProfile.equipped_skin == id:
		action.text = "EQUIPPED"
		action.disabled = true
	elif PlayerProfile.owns_skin(id):
		action.text = "EQUIP"
		action.disabled = false
	else:
		action.text = "BUY  %d" % int(skin["price"])
		action.disabled = PlayerProfile.coins < int(skin["price"])
