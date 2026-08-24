extends Node

## Persistent player currency and marble cosmetics (PROJECT.md section 10:
## coins, spent on cosmetic marble items). Coins and skin ownership are saved
## together since nothing else currently needs its own save file.
##
## The first five skins are flat colours. The rest carry a `finish`, which
## `marble_skin.gd` paints into a texture at runtime — still no art pipeline
## (see home_screen.gd), just procedural maps, the same way every other visual
## in the project is made. A skin without a `finish` key is a plain colour and
## nothing in `marble_skin.gd` touches it.
##
## Keys an elaborate skin may carry, all optional:
##   finish    Which generator paints it: cats_eye, sunburst, galaxy, magma,
##             chrome, stormcell, quicksilver.
##   colour    Still required on every skin — the base/background tone, and the
##             one colour the HUD swatch and the marble's trail are drawn in,
##             neither of which can show a pattern.
##   ribbon    The generator's accent colours; what they mean is per-finish.
##   reactive  Optional; `marble.gd` behaviour tied to the race rather than the
##             static pattern above: "impact_flash" spikes emission energy on
##             the player's own collisions, "speed_tint" lerps ALBEDO by the
##             marble's current speed. Absent means the skin just sits there.
##   metallic  Defaults to the plain marble's 0.1.
##   roughness Defaults to the plain marble's 0.25.

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
	{
		"id": 5,
		"name": "Cat's Eye",
		"colour": Color(0.94, 0.94, 0.90), ## Milky glass; the vane lives in `ribbon`.
		"finish": "cats_eye",
		"ribbon": [Color(0.91, 0.24, 0.28), Color(0.99, 0.83, 0.24), Color(0.20, 0.48, 0.92)],
		# Glass, so smoother and less metallic than the painted marbles above.
		"metallic": 0.05,
		"roughness": 0.12,
		"price": 150,
	},
	{
		"id": 6,
		"name": "Sunburst",
		"colour": Color(0.98, 0.55, 0.12),
		"finish": "sunburst",
		"ribbon": [Color(0.98, 0.45, 0.08), Color(1.0, 0.93, 0.78)],
		"cap": Color(0.99, 0.78, 0.20),
		"price": 150,
	},
	{
		"id": 7,
		"name": "Galaxy",
		# Bright enough for the HUD swatch and the trail, which get this colour
		# flat; the ball itself is painted over the near-black `backdrop`.
		"colour": Color(0.55, 0.38, 0.95),
		"backdrop": Color(0.055, 0.04, 0.13),
		"finish": "galaxy",
		"ribbon": [Color(0.52, 0.18, 0.82), Color(0.18, 0.58, 0.92)],
		"metallic": 0.0,
		"roughness": 0.45,
		"price": 250,
	},
	{
		"id": 8,
		"name": "Magma",
		"colour": Color(0.96, 0.38, 0.10),
		"backdrop": Color(0.11, 0.09, 0.10),
		"finish": "magma",
		"ribbon": [Color(0.95, 0.30, 0.05), Color(1.0, 0.87, 0.38)],
		"metallic": 0.0,
		# Cooled basalt. The one skin that is not meant to shine.
		"roughness": 0.85,
		"price": 250,
	},
	{
		"id": 9,
		"name": "Chrome",
		"colour": Color(0.86, 0.89, 0.94),
		"finish": "chrome",
		"ribbon": [Color(0.97, 0.98, 1.0), Color(0.20, 0.23, 0.30)],
		"metallic": 1.0,
		"roughness": 0.08,
		"price": 400,
	},
	{
		"id": 10,
		"name": "Stormcell",
		"colour": Color(0.55, 0.68, 0.88),
		"backdrop": Color(0.10, 0.12, 0.18),
		"finish": "stormcell",
		# Vein colour, dim -> hot. `reactive: impact_flash` (marble.gd) is what
		# actually makes this skin different from Magma: the veins hold near
		# their dim end at rest and spike toward it on every hit the player's
		# marble takes, decaying back down after.
		"ribbon": [Color(0.55, 0.85, 1.0), Color(1.0, 1.0, 0.95)],
		"reactive": "impact_flash",
		"metallic": 0.05,
		"roughness": 0.55,
		"price": 300,
	},
	{
		"id": 11,
		"name": "Quicksilver",
		"colour": Color(0.60, 0.68, 0.80),
		"finish": "quicksilver",
		# Reused as both the static chrome banding (marble_skin.gd's
		# `_paint_chrome`) and the two ends `reactive: speed_tint` (marble.gd)
		# lerps ALBEDO between live, at rest and at the marble's own top speed —
		# the one skin whose colour is a gameplay readout, not just decoration.
		"ribbon": [Color(0.55, 0.70, 0.95), Color(1.0, 0.55, 0.15)],
		"reactive": "speed_tint",
		"metallic": 1.0,
		"roughness": 0.08,
		"price": 350,
	},
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


## The whole equipped entry, for the things that can show a pattern — the
## marble itself and the Home preview. Everything that can only show one flat
## colour (the HUD swatch, the trail) keeps using `equipped_colour`.
func equipped_skin_data() -> Dictionary:
	return skin_by_id(equipped_skin)


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
