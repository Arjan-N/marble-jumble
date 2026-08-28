class_name Landscape
extends RefCounted

## The world a course sits in, as opposed to the course itself.
##
## Nothing here collides with anything. That is the defining rule of this file:
## a landscape is what the camera sees past the racing surface, and the moment a
## piece of it can be hit it stops being scenery and becomes course geometry that
## has to be probed, tuned and reasoned about. Every mesh this builds is a bare
## `MeshInstance3D` or a `MultiMeshInstance3D` with no body under it.
##
## The constraint that shapes all of it is the locked race camera. `Mode.LOW`
## sits at 32 degrees with a 26 degree horizontal lens on a 720x1280 frame, which
## works out to a ~44.6 degree vertical field whose **top edge is about 10 degrees
## below the horizon**. Two things follow, and both are counter-intuitive enough
## to be worth stating where the code is:
##
## - There is no sky in shot except over dead-flat ground, so a skybox is not a
##   backdrop here. Distance has to be closed by fog and by geometry.
## - Nothing more than about 11m above the racing surface at the focus is ever
##   on camera, falling to ~6m at 60m up-course. Canopies and ceilings are wasted
##   unless they hang lower than that.
##
## So the budget is the top fifth of the frame, the two flanks, and whatever is
## underneath — which is where the "floating" reads from. Trackmania's tracks
## float too, and are not read that way, because the ground below is always
## drawn, the track is visibly propped on it, and fog closes the gap. That is the
## order of importance, and it is the order these helpers are written in.

## Deterministic scatter with a per-instance tint, as one draw call.
##
## `MultiMesh` rather than a node each, because scenery is where the instance
## count runs away: the jungle alone wants a couple of hundred trees and a
## low-mid Android phone will not pay for a couple of hundred draw calls to get
## them.
static func scatter(
	mesh: Mesh,
	transforms: Array[Transform3D],
	colours: Array[Color],
	name := "Scatter"
) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = not colours.is_empty()
	multi.mesh = mesh
	multi.instance_count = transforms.size()

	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
		if multi.use_colors:
			# Converted, because instance colours are consumed as linear while
			# every `Color` literal in a course file is written in sRGB the way the
			# inspector shows it. Handed over raw, a 0.27 trunk brown is read as
			# 0.27 linear and displays around 0.56 — the jungle's first render came
			# out with pale tan trunks and sage crowns, and nothing about the
			# constants said why.
			multi.set_instance_color(i, colours[i].srgb_to_linear())

	var node := MultiMeshInstance3D.new()
	node.name = name
	node.multimesh = multi
	return node


## A material for scattered instances, reading `MultiMesh`'s per-instance colour
## as albedo so one mesh and one draw call can still be a hundred shades.
static func instance_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.metallic = 0.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return material


## A ground material with world-space detail on it. See `terrain_detail.gdshader`
## for why the noise is in the shader rather than in a texture.
static func detail_material(
	albedo: Color,
	alt: Color,
	macro_scale := 0.035,
	detail_scale := 0.42,
	slope_darken := 0.35
) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://scripts/course/terrain_detail.gdshader")
	material.set_shader_parameter("albedo", albedo)
	material.set_shader_parameter("albedo_alt", alt)
	material.set_shader_parameter("macro_scale", macro_scale)
	material.set_shader_parameter("detail_scale", detail_scale)
	material.set_shader_parameter("slope_darken", slope_darken)
	return material


## A mesh from rows of vertices, stitched row to row and column to column.
##
## The same construction `JungleCourse._build_run` uses for the channel, minus
## the collider: every row must hold the same number of points, and the winding
## below puts the front face towards +Y for rows ordered along the course with
## columns running left to right.
static func stitch(rows: Array, material: Material, name := "Surface") -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for r in range(rows.size() - 1):
		var near: Array = rows[r]
		var far: Array = rows[r + 1]
		for c in range(near.size() - 1):
			tool.add_vertex(near[c])
			tool.add_vertex(far[c])
			tool.add_vertex(near[c + 1])

			tool.add_vertex(near[c + 1])
			tool.add_vertex(far[c])
			tool.add_vertex(far[c + 1])

	tool.generate_normals()

	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = tool.commit()
	node.material_override = material
	return node


## Smooth, seedless relief for a ground plane, in metres.
##
## Deliberately not `RandomNumberGenerator`: adjacent rows of a stitched ground
## mesh have to agree about the height between them, and per-vertex random
## numbers give a field of spikes instead of a landscape. Two sine octaves at
## incommensurate frequencies are continuous everywhere by construction, cost
## nothing at build time, and are the same every run.
static func relief(along: float, across: float, amplitude: float) -> float:
	return amplitude * (
		0.62 * sin(across * 0.071 + along * 0.049)
		+ 0.38 * sin(across * 0.023 - along * 0.031 + 1.7)
	)
