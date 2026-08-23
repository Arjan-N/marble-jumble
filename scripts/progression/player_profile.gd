extends Node

## Persistent player currency and marble cosmetics (PROJECT.md section 10:
## coins, spent on cosmetic marble items). Coins and skin ownership are saved
## together since nothing else currently needs its own save file.
##
## Skins are flat colours only — there is no art pipeline yet (see
## home_screen.gd), and the shop is a placeholder until the home screen's own
## visual design is settled.

signal coins_changed(balance: int)

const SAVE_PATH := "user://player_profile.cfg"

## id 0 is the free default every profile starts with. Prices are round
## placeholder numbers, not a tuned economy (PROJECT.md section 17 item 10).
const SKINS := [
	{"id": 0, "name": "Default", "colour": Color(0.95, 0.75, 0.15), "price": 0},
	{"id": 1, "name": "Ocean", "colour": Color(0.25, 0.78, 1.0), "price": 50},
	{"id": 2, "name": "Ember", "colour": Color(0.92, 0.32, 0.18), "price": 50},
	{"id": 3, "name": "Toxic", "colour": Color(0.55, 0.92, 0.20), "price": 75},
	{"id": 4, "name": "Royal", "colour": Color(0.58, 0.30, 0.92), "price": 100},
]

var coins: int = 0
var owned_skins: Array[int] = [0]
var equipped_skin: int = 0


func _ready() -> void:
	_load()


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)
	_save()


func buy_skin(id: int) -> bool:
	if owned_skins.has(id):
		return false
	var skin := skin_by_id(id)
	if skin.is_empty() or coins < int(skin["price"]):
		return false
	coins -= int(skin["price"])
	owned_skins.append(id)
	coins_changed.emit(coins)
	_save()
	return true


func equip_skin(id: int) -> bool:
	if not owned_skins.has(id):
		return false
	equipped_skin = id
	_save()
	return true


func owns_skin(id: int) -> bool:
	return owned_skins.has(id)


func skin_by_id(id: int) -> Dictionary:
	for skin in SKINS:
		if skin["id"] == id:
			return skin
	return {}


func equipped_colour() -> Color:
	return skin_by_id(equipped_skin).get("colour", Color.WHITE)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "coins", coins)
	config.set_value("profile", "owned_skins", owned_skins)
	config.set_value("profile", "equipped_skin", equipped_skin)
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	coins = int(config.get_value("profile", "coins", 0))

	owned_skins = []
	for id in config.get_value("profile", "owned_skins", [0]):
		owned_skins.append(int(id))
	if not owned_skins.has(0):
		owned_skins.append(0) ## The free default is never actually losable.

	equipped_skin = int(config.get_value("profile", "equipped_skin", 0))
	if not owns_skin(equipped_skin):
		equipped_skin = 0
