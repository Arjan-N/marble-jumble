extends SceneTree

## Writes every entry in `PlayerProfile.SKINS` to disk as a lit ball, so a skin
## can be looked at without launching the game and walking to the shop.
##
##     godot --path . --headless --script res://tools/skin_sheet.gd
##
## Saves `shots/skins/<id>_<name>.png` (the swatch `shop_screen.gd` draws, at a
## size worth looking at) and, for the patterned ones, `<id>_<name>_map.png`:
## the raw equirectangular albedo. The map is where a seam or a pinched pole
## shows up — on the ball, the far side of the sphere is hiding it.
##
## No rendering here, headless or otherwise: `marble_skin.gd` paints both images
## on the CPU, and this only asks it for them and saves them.

const OUT_DIR := "res://shots/skins"
const SWATCH_PX := 256


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	for skin in PlayerProfile_SKINS():
		var stem := "%s/%d_%s" % [OUT_DIR, int(skin["id"]), _slug(String(skin["name"]))]
		MarbleSkin.swatch_texture(skin, SWATCH_PX).get_image().save_png("%s.png" % stem)

		var finish := String(skin.get("finish", ""))
		if finish != "":
			var material := StandardMaterial3D.new()
			MarbleSkin.apply(material, skin)
			material.albedo_texture.get_image().save_png("%s_map.png" % stem)
			if material.emission_texture != null:
				material.emission_texture.get_image().save_png("%s_glow.png" % stem)
		print("wrote %s" % stem)

	quit()


## `PlayerProfile` is an autoload, and autoloads do not exist in a `--script`
## run — there is no main scene and nothing to attach them to. The catalogue is
## a plain const, so it is read off the script resource instead.
func PlayerProfile_SKINS() -> Array:
	var profile: GDScript = load("res://scripts/progression/player_profile.gd")
	return profile.get_script_constant_map()["SKINS"]


func _slug(name: String) -> String:
	return name.to_lower().replace(" ", "_").replace("'", "")
